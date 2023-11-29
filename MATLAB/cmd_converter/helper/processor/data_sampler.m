function [series, plot_data] = data_sampler(target)
    % Global status (會由其他程式進行修改，所以宣告成 global)
    global stat;
    
    %% Main
    % get sampling t
    t_raw = target(1, :) - target(1, 1);
    t_start = t_raw(1, 1);
    t_end = max(t_raw);
    t_sample = t_start : stat.time_delta : t_end;

    % init indices
    indices = zeros(size(t_sample));

    % find closest time in t_raw
    for i = 1:length(t_sample)
        [~, indices(i)] = min(abs(t_raw - t_sample(i)));
    end

    t_sample_corrected = t_raw(indices);
    abs_target = abs(target);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Time Sampling Method
    tsm_sampled_target = abs_target(2:end, indices);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Average Peak Method
    P = find_segment_peaks(abs_target, indices);
    apm_sampled_target = calculate_average_peaks(P);

    % add P to plot_data for plot requirement
    plot_data.APM.P = P;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % STFTM
    % NOTE THAT WE USE ORIGINAL `target` TO GET STFT RESULT
    %
    % STFTM 牽扯到 stst.freq_band (array)
    % 
    [stftm_sampled_target, stft_info, other_info] = sampled_by_stft(target, apm_sampled_target);

    plot_data.STFTM.stft_info = stft_info;
    plot_data.STFTM.total_energy = other_info.total_energy;
    plot_data.STFTM.energy = other_info.energy;
    plot_data.STFTM.ratio = other_info.ratio;

    series.t = t_sample_corrected;

    % three methods (TSM, APM, STFTM)
    series.cmd = cell(1, 3);
    % TPM
    series.cmd{1} = tsm_sampled_target;
    % APM
    series.cmd{2} = apm_sampled_target;
    % STFTM
    series.cmd{3} = stftm_sampled_target;
end


function P = find_segment_peaks(target, indices)
    % find_segment_peaks Function to find peaks in each segment of target data.
    % P will be in like following for three axes case
    % {
    %   {[peak_index1_1, peak_value1_1]}, {[peak_index1_2, peak_value1_2]},...
    %   {[peak_index2_1, peak_value2_1]}, {[peak_index2_2, peak_value2_2]},...
    %   ...
    %   {[peak_indexk_1, peak_valuek_1]}, {[peak_indexk_2, peak_valuek_2]},
    % }
    %
    % 其中 length(P{1}, 1) 可能不等於 length(P{2}, 1)
    % Inputs:
    %   target   - The data matrix where columns represent different
    %              signals. The first column is always `time column`.
    %   indices  - The row indices that define the segments in target.
    % 
    % Outputs:
    %   P        - A cell array where each cell contains the peaks info of each segment.
    %
    %   P{j}{k}    j 代表 axis, k 代表 segment (跟 stat.time_delta 有關)
    %              這裡面應該包含一個二維陣列 [peak_indices;peak_values]
    %
    % Example:
    %   P{j}{k} 的 peak_indices -> P{j}{k}(1, :)
    %   P{j}{k} 的 peak_values -> P{j}{k}(2, :)
    % 
    
    % Initialize the cell array to store peaks information
    num_axis = size(target, 1) - 1;
    P = cell(1, num_axis); % 初始化 P 每个轴

    for j = 1:num_axis
        P{j} = cell(1, length(indices)); % 初始化每个段落
    end

    for k = 1:length(indices)
        if k < length(indices)
            cols = indices(k) : indices(k + 1) - 1;
        else
            cols = indices(k) : size(target, 1);
        end

        if isempty(cols)
            for j = 1:num_axis
                % 通常，這表示模擬發生當機事件，導致時差不固定
                P{j}{k} = [NaN; NaN]; % 使用 NaN 表示没有数据
            end
            continue;
        end

        segment_start_index = cols(1) - 1; 
        segment = target(2:end, cols);

        for j = 1:num_axis
            if size(segment, 2) >= 3 % 如果段落包含 3 个或更多元素
                [pks, locs] = findpeaks(segment(j, :));
                if isempty(locs)
                    [pks, locs] = max(segment(j, :));
                end
                adjusted_locs = locs + segment_start_index;
                P{j}{k} = [adjusted_locs; pks];
            else % 对于少于 3 个元素的段落
                [pks, locs] = max(segment(j, :));
                adjusted_locs = locs + segment_start_index;
                P{j}{k} = [adjusted_locs; pks];
            end
        end
    end
end

function avg_peaks = calculate_average_peaks(P)
    % calculate_average_peaks Calculate the average of peaks for each segment and axis.
    % Inputs:
    %   P        - A cell array where each cell contains the peaks info of each segment.
    % Outputs:
    %   avg_peaks - A matrix of average peak values for each segment and axis.
    %   
    %   avg_peaks = [
    %                   [sig_1_avg];
    %                   [sig_2_avg];
    %                   ...
    %               ]

    num_axes = length(P); % The number of axes

    if num_axes == 0
        avg_peaks = [];
        return;
    end

    % assume length in every axis is same
    num_segments = length(P{1});
    avg_peaks = zeros(num_axes, num_segments);

    % iterate P
    for j = 1 : num_axes
        for k = 1 : num_segments
            peak_values = P{j}{k}(2, :);
            
            % Calculate the average of the peak values
            avg_peaks(j, k) = mean(peak_values);
        end
    end
end

function [stftm_sampled_target, stft_info, other_info] = sampled_by_stft(target, apm_sampled_target)
    global stat;

    % check stat.freq_bands is not null
    if isempty(stat.freq_bands)
        error("Error: stat.freq_bands should not be empty!");
    end

    num_freq_band = size(stat.freq_bands, 1);
    num_axis = size(target, 1) - 1;

    % init a two dimensional cell array
    % stftm_sampled_target {k}{j}
    % k: number of freq_bands
    % j: number of axis
    % stftm_sampled_target = cell(num_freq_band, num_axis);
    stft_info = cell(1, num_axis);

    % STFT all signals
    for j = 1 : num_axis
        [s,f,t] = pspectrum(target(j + 1, :), stat.fs, "spectrogram", ...
                            TimeResolution=stat.time_delta, ...
                            OverlapPercent=stat.overlap_percent, ...
                            Leakage=stat.leakage);
        % resample the along time axis
        new_t = 0:stat.time_delta:max(t);
        new_s = zeros(size(s, 1), length(new_t));

        % interp1
        for i = 1:size(s, 1)
            new_s(i, :) = interp1(t, s(i, :), new_t, 'linear', 'extrap');
        end


        info.s = new_s'; % [row: t; col: f]
        info.f = f';
        info.t = new_t';

        stft_info{j} = info;
    end


    % get total energy array and energy array
    % total_energy {j}(:), array length should be same as size(apm_sampled_target, 2)
    % energy {j}{k}(:) array length should be same as size(apm_sampled_target, 2)
    num_bands = size(stat.freq_bands, 1);
    total_energy = cell(1, num_axis);
    energy = cell(num_axis, num_bands);

    for j = 1:num_axis
        % 获取当前轴向的频谱数据和新的时间向量
        s = stft_info{j}.s;
        
        % 计算总能量
        total_energy{j} = sum(s, 2); % 沿频率维度求和
    
        % 对每个频带计算能量
        for k = 1:num_bands
            band_start = stat.freq_bands(k, 1);
            band_end = stat.freq_bands(k, 2);
            
            % 找到频带对应的频率索引
            freq_indices = stft_info{j}.f >= band_start & stft_info{j}.f <= band_end;
            
            % 计算该频带的能量
            energy{j}{k} = sum(s(:, freq_indices), 2); % 沿频率维度求和
        end
    end

    % calculate stftm cmd
    for k = 1 : num_bands
        result = [];
        for j = 1 : num_axis
            % ratio{j} is a (L, 1) array
            % TODO: store ratio to stat
            ratio{j} = energy{j}{k} ./ total_energy{j};
            result{j} = (ratio{j}) .* apm_sampled_target(j, :)';
        end
        stftm_sampled_target{k} = cell2mat(result)';
    end

    other_info.total_energy = total_energy;
    other_info.energy = energy;
    other_info.ratio = ratio;
end
