function [] = warn_cmd_plotter(csv_paths, scf, dcf)
    global stat;
    
    % add choose_file
    addpath(genpath("../../../util"));

    should_repick = false;
    
    DEFAULT_COMPRESS_STRATEGY = "ABS_MAX";

    % set axis_num
    if exist("stat",'var')
        if stat.is_single_axis == true
            axis_num = 1;
        else
            axis_num = 3;
        end
    else
        axis_num = 1;
    end

    warning("'axis_num' set to default value: %d\n", axis_num);

    if nargin == 0
        should_repick = true;
    end

    % complete csv path
    if should_repick
        csv_paths = cell(1, 1);
        addpath("../compress/");

        % for three methods
        CSV_DEFAULT_PATH = "../../../../CSV";
        DCF_DEFAULT_PATH = "../../../../Data";

        hint = sprintf("Please choose 'warn' file:\n");
        [file, path] = choose_file(hint, 'csv', CSV_DEFAULT_PATH);

        % reassign path
        path = fullfile(path, file);

        if contains(file, 'ThreeAxes')
            axis_num = 3;
            warning("File: %s, contains keyword 'ThreeAxes'.\n..." + ...
                        "Set local 'axis_num' to 3\n", file);
        else
            % update compress strategy
            if contains(file, 'ABS_MAX')
                DEFAULT_COMPRESS_STRATEGY = 'ABS_MAX';
            else
                DEFAULT_COMPRESS_STRATEGY = 'ENERGY';
            end
        end

        csv_paths{1} = path;

        % TODO: Simplify this part
        hint = sprintf("Please choose SCF file:\n");
        [scf_file, scf_path] = choose_file(hint, '', DCF_DEFAULT_PATH);
        % reassign scf_path
        scf_path = fullfile(scf_path, scf_file);

        hint = sprintf("Please choose DCF file:\n");
        [dcf_file, dcf_path] = choose_file(hint, '', DCF_DEFAULT_PATH);
        % reassign dcf_path
        dcf_path = fullfile(dcf_path, dcf_file);

        % load dcf file, copied from data_reader.m
        scf_table = readtable(scf_path, 'VariableNamingRule', 'preserve');
        dcf_table = readtable(dcf_path, 'VariableNamingRule', 'preserve');

        scf_data = table2array(scf_table)';
        dcf_data = table2array(dcf_table)';

        % resampling
        avg_sampling_interval = mean(diff(scf_data(1, :)));
        fs = 1 / avg_sampling_interval;

        scf_data = adjust_times(scf_data, fs);
        dcf_data = adjust_times(dcf_data, fs);

        new_time_vector = scf_data(1, 1):avg_sampling_interval:scf_data(1, end);
        for i = 2:size(scf_data, 1)
            processed_scf_data(i, :) = interp1(scf_data(1, :), scf_data(i, :), new_time_vector, 'linear', 'extrap');
            processed_dcf_data(i, :) = interp1(dcf_data(1, :), dcf_data(i, :), new_time_vector, 'linear', 'extrap');
        end
        processed_scf_data(1, :) = new_time_vector;
        processed_dcf_data(1, :) = new_time_vector;

        scf = processed_scf_data;
        dcf = processed_dcf_data;
    end

    % Calculate KLD
    D_KL = zeros(size(scf));
    D_KL(1, :) = scf(1, :); % 添加时间到 D_KL
    for i = 2:4
        P = scf(i, :);
        Q = dcf(i, :);

        P(P == 0) = eps(0); % 替换 0 以避免除以 0
        Q(Q == 0) = eps(0);

        % P 和 Q 要 abs 化?
        new_P = P;
        new_Q = Q;

        D_KL(i, :) = abs(new_P .* log10(new_P ./ new_Q));
    end

    % determine compress or not
    if axis_num == 1
        disp("Compressing data to single axis");
        warning("Using %s to parse following data", DEFAULT_COMPRESS_STRATEGY);
        processed_d_kl = compress_to_single_axis(D_KL, DEFAULT_COMPRESS_STRATEGY);
        d_kl = processed_d_kl';
    else
        d_kl = D_KL';
    end

    

    % load csv cmd
    cmd_csv = table2array(readtable(csv_paths{1}, 'VariableNamingRule', 'preserve'));
    d_kl(:, 1) = d_kl(:, 1) - d_kl(1, 1);

    %% plot logic
    colors =  [[0.9373, 0.3490, 0.4824];  [1, 0.7961, 0.0941];  [0.4510, 0.7137, 0.4196]];
    axes_name = ["X";"Y";"Z"];

    for axis = 1 : axis_num
        figure;
        hold on;

        plot(d_kl(:, 1), d_kl(:, axis + 1), 'LineWidth', 3);
        title_str = sprintf("Vibration Command of %s Axis", axes_name(axis));
        title(title_str, "FontSize", 24);
        xlabel("Time (s)", "FontSize", 18, "FontWeight", "bold");
        ylabel("KLD", "FontSize", 18, "FontWeight", "bold");

        yyaxis("right");
        plot(cmd_csv(:, 1), cmd_csv(:, axis * 2));
        ylabel("PWM CMD (‰)", "FontSize", 18, "FontWeight", "bold");
        legend('KLD', 'WARN CMD', "FontSize", 18, "FontWeight", "bold");
        
        ax = gca;
        ax.FontSize = 18;
        ax.FontWeight = "bold";
    end
end

%% WARNING: This is a copied from data_reader.m. You should also modified that part
%           when this region got modified.
function data = adjust_times(data, fs)
    % 检查并调整数据中的重复时间点
    time_data = data(1, :);

    % 查找重复时间点
    [~, unique_indices] = unique(time_data, 'stable');
    duplicate_indices = setdiff(1:length(time_data), unique_indices);

    % 为重复点之后的时间增加偏移
    for idx = duplicate_indices
        % 从当前重复点到末尾增加 1/fs
        data(1, idx:end) = data(1, idx:end) + 1/fs;
    end
end
