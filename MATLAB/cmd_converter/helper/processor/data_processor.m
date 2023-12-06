function [t_sampled, cmd] = data_processor(raw)
    % Global status (會由其他程式進行修改，所以宣告成 global)
    global stat;

    % Const
    CONST_TSM = 1;
    CONST_APM = 2;
    CONST_STFTM = 3;

    %% Main
    % decide to compress data or not
    if stat.is_single_axis
        target = compress_to_single_axis(raw, stat.compress_strategy);
    else
        target = raw;
    end

    % modified time
    % make time start from 0
    t_raw = target(1, :) - target(1, 1);
    t_start = t_raw(1, 1);
    t_end = max(t_raw);
    t_sampled = t_start : stat.time_delta : t_end;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Use warn binary cmd (Vibrate or not) => 999 or 500
    % TODO: let the const be declared in const_struct.
    if strcmp(stat.mode, "WARN_BIN")
        D_KL_THRESHOLD = 1;
        VIBRATE_CMD = 999;
        NOT_VIBRATE_CMD = 500;
        
        % generate binary command
        axis_num = size(target, 1) - 1;
        cmd = zeros(axis_num, length(t_sampled));
        
        for i = 1:length(t_sampled)
            segment_start = find(t_raw >= t_sampled(i), 1, 'first');
            if i < length(t_sampled)
                segment_end = find(t_raw < t_sampled(i+1), 1, 'last');
            else
                segment_end = length(t_raw); % 對於最後一個 segment，使用 t_raw 的最後一個元素
            end
    
            for j = 1:axis_num
                abs_target = abs(target(j + 1, segment_start:segment_end));
                segment_max = max(abs_target);
                if segment_max >= D_KL_THRESHOLD
                    cmd(j, i) = VIBRATE_CMD;
                else
                    cmd(j, i) = NOT_VIBRATE_CMD;
                end
            end
        end
    
        % EXIT >>> 1
        return;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % TODO: Use warn level cmd (Strong, Mid, Light, No vibration) => 999, 750,
    % 600, 500
    if strcmp(stat.mode, "WARN_LEVEL")
        THRESHOLD.STRONG = 1;
        THRESHOLD.MID = 0.9;
        THRESHOLD.LIGHT = 0.8;
        STRONG_VIBRATE_CMD = 999;
        MID_VIBRATE_CMD = 750;
        LIGHT_VIBRATE_CMD = 600;
        NOT_VIBRATE_CMD = 500;
    
        % generate level warning command
        axis_num = size(target, 1) - 1;
        cmd = NOT_VIBRATE_CMD * ones(axis_num, length(t_sampled)); % default to No vibration
    
        for i = 1:length(t_sampled)
            segment_start = find(t_raw >= t_sampled(i), 1, 'first');
            if i < length(t_sampled)
                segment_end = find(t_raw < t_sampled(i+1), 1, 'last');
            else
                segment_end = length(t_raw); % 對於最後一個 segment，使用 t_raw 的最後一個元素
            end
    
            for j = 1:axis_num
                abs_target = abs(target(j + 1, segment_start:segment_end));
                segment_max = max(abs_target);
                
                % 分配 Strong vibration
                if segment_max >= THRESHOLD.STRONG
                    cmd(j, i) = STRONG_VIBRATE_CMD;
                % 分配 Mid vibration
                elseif segment_max >= THRESHOLD.MID
                    cmd(j, i) = MID_VIBRATE_CMD;
                % 分配 Light vibration
                elseif segment_max >= THRESHOLD.LIGHT
                    cmd(j, i) = LIGHT_VIBRATE_CMD;
                % No vibration (default value)
                else
                    cmd(j, i) = NOT_VIBRATE_CMD;
                end
            end
        end
    
        % EXIT >>> 2
        return;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Use force linear => 999 ~ 500
    %
    if strcmp(stat.mode, "FORCE_LINEAR")
        % series is a struct
        % - t: t_sample_corrected
        % - cmd: a cell, size(1, 3). 3 代表方法 TSM, APM, STFTM
        %   - tsm_sampled_target: size(j, L), array
        %   - apm_sampled_target: size(j, L), array
        %   - stftm_sampled_target: size(k, j, L), cell(array). k 是 freq_bands
        %                           index, j 是軸向 
        [series, plot_data] = data_sampler(target);
        
        linear_converted_series = data_linear_converter(series);

        t_sampled = linear_converted_series.t;
        cmd{CONST_TSM} = linear_converted_series.cmd{CONST_TSM};
        cmd{CONST_APM} = linear_converted_series.cmd{CONST_APM};
        cmd{CONST_STFTM} = linear_converted_series.cmd{CONST_STFTM};
   
        % store util to stat
        stat.plot_data.APM = plot_data.APM;
        stat.plot_data.STFTM = plot_data.STFTM;

        % EXIT >>> 3
        return;
    else
        error('Mode error: %s \n', stat.mode);
    end
end
% Brief: Process data
% 
% Return: cmd, Cell Array, same as series
%   [WARN]: single layer cell cmd
%       - is_single_axis:
%           -  true: {[cmd]}，單 row
%              使用 cmd{1} 拿到指令 (只有一行)
%
%           -  false: {[cmd1]; [cmd2]; ...; [cmdn]}, total n axes
%           -  使用 cmd{1} 拿到 x 軸, cmd{2} 拿到 y 軸 ...
% 
%   [FORCE]: two or three layers cell cmd，僅在 STFTM 是三層
%       - is_single_axis:
%           - true:
%                 {
%                   {[cmd_tsm]}; 
%                   {[cmd_apm]}; 
%                   {
%                       {[cmd_stftm_band1]}; 
%                       {[cmd_stftm_band2]};...
%                   }
%                 }
%                 e.g., 
%                 cmd{1}{1} -> [cmd_tsm]
%                 cmd{2}{1} -> [cmd_apm]
%                 cmd{3}{1}{1} -> [cmd_stftm_band1]
%           - false
%                 {
%                   {[cmd_tsm_x];[cmd_tsm_y];[cmd_tsm_z]}; 
%                   {[cmd_apm_x];[cmd_apm_y];[cmd_apm_z]}; 
%                   {
%                       {[cmd_stftm_band1_x];[cmd_stftm_band1_y];[cmd_stftm_band1_z]}; 
%                       {[cmd_stftm_band2_x];[cmd_stftm_band2_y];[cmd_stftm_band2_z]};
%                       ...
%                   }
%                 }
%                 e.g., 
%                 cmd{1}{1} -> [cmd_tsm_x]
%                 cmd{2}{2} -> [cmd_apm_y]
%                 cmd{m}{g}: m 是方法，按照 tsm, apm, stftm 排序; g 是 axis
%
%                 *STFTM 是特例，使用三個 {} 取值
%                 cmd{3}{1}{1} -> [cmd_stftm_band1_x]
%                 cmd{3}{k}{j}: k 是 freq_band, j 是 axis
% 目前總共有三個離開點，請搜尋 `EXIT >>>`