function [] = three_methods_cmd_plotter(csv_paths, dcf)
    global stat;
    
    % add choose_file
    addpath(genpath("../../../util"));

    should_repick = false;
    METHODS = ["TSM", "APM", "STFTM"];

    % TODO: Get from file names
    DEFAULT_COMPRESS_STRATEGY = "ABS_MAX";

    % set axis_num
    if exist("stat", "var")
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

    if should_repick
        csv_paths = cell(length(METHODS), 1);
        addpath("../compress/")

        % for three methods
        CSV_DEFAULT_PATH = "../../../../CSV";
        DCF_DEFAULT_PATH = "../../../../Data";

        for j = 1 : length(METHODS)
            hint = sprintf("Please choose %s file:\n", METHODS(j));
            [file, path] = choose_file(hint, 'csv', CSV_DEFAULT_PATH);
            % reassign path
            path = fullfile(path, file);

            % update axis_num here if there is 'ThreeAxes' in file name
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
           
            csv_paths{j} = path;
        end

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

        % use new_time_vector resampling
        for i = 2:size(scf_data, 1)
            % processed_scf_data(i, :) = interp1(scf_data(1, :), scf_data(i, :), new_time_vector, 'linear', 'extrap');
            processed_dcf_data(i, :) = interp1(dcf_data(1, :), dcf_data(i, :), new_time_vector, 'linear', 'extrap');
        end

        % processed_scf_data(1, :) = new_time_vector;
        processed_dcf_data(1, :) = new_time_vector;
        
        % compress or not
        if axis_num == 1
            disp("Compressing data to single axis");
            warning("Using %s to parse following data", DEFAULT_COMPRESS_STRATEGY);
            processed_dcf_data = compress_to_single_axis(processed_dcf_data, DEFAULT_COMPRESS_STRATEGY); 
        end

        % assign to dcf, transport one
        dcf = processed_dcf_data';
    else
        if axis_num == 1
            disp("Compressing data to single axis");
            dcf = compress_to_single_axis(dcf, stat.compress_strategy);
        end
        
        dcf = dcf';
    end
    
    % load methods csv files, TSM, APM, SFTFM
    method_table = cell(length(METHODS), 1);
    method_array = cell(length(METHODS), 1);

    for j = 1 : length(METHODS)
        method_table{j} = readtable(csv_paths{j}, 'VariableNamingRule', 'preserve');
        method_array{j} = table2array(method_table{j});
    end
    
    % set offset according to first time stamp
    dcf(:, 1) = dcf(:, 1) - dcf(1, 1);

    %% plot logic
    colors =  [[0.9373, 0.3490, 0.4824];  [1, 0.7961, 0.0941];  [0.4510, 0.7137, 0.4196]];
    axes_name = ["X";"Y";"Z"];

    for axis = 1 : axis_num
        figure;
        hold on;
        
        plot(dcf(:, 1), abs(dcf(:, axis + 1)), 'LineWidth', 3);
        title_str = sprintf("Vibration Command of %s Axis", axes_name(axis));
        title(title_str, "FontSize", 24);
        xlabel("Time (s)", "FontSize", 18, "FontWeight", "bold");
        ylabel("Absolute Simulation Force (N)", "FontSize", 18, "FontWeight", "bold");

        yyaxis("right");
        for j = 1 : length(METHODS)
            plot(method_array{j}(:, 1), method_array{j}(:, axis * 2), '-', 'LineWidth', 2, 'Color', colors(j,:));
        end
        ylabel("PWM CMD (‰)", "FontSize", 18, "FontWeight", "bold");
        
        legend('ABS(DCF)', 'TSM CMD', 'APM CMD', 'STFTM CMD', "FontSize", 18, "FontWeight", "bold");

        ax = gca;
        ax.FontSize = 18;
        ax.FontWeight = "bold";
    end

    %% apply linear coeff
    fprintf("Linear coeff of PWM - Raw force:\n");

    % resample methods_array by ZOH
    sampled_method_array = cell(axis_num, 1); % is axis_num instead of methods
    target_array = cell(axis_num, 1);
    t_dcf = dcf(:, 1);
    coeff = cell(length(METHODS), axis_num); % Method: row, axis: col

    for j = 1 : length(METHODS)
        tmp = interp1(method_array{j}(:, 1), ...
                      method_array{j}(:, 2:end), t_dcf, 'previous');
        
        % Put three axes data into sampled_method_array        
        for k = 1 : axis_num
           sampled_method_array{k} = tmp(:, 2 * k - 1);
           target_array{k} = abs(dcf(:, k + 1));
        end

        
        % TODO: It's a local variable now
        % base{axis1, axis2, axis3};
        coeff = internal_calculate_linear_coeff(sampled_method_array, target_array);

        % print linear coeff
        if axis_num == 3
            fprintf("'%s': x{%.5f}, y: {%.5f}, z: {%.5f}\n", METHODS(j), coeff(1), coeff(2), coeff(3));
        else
            fprintf("'%s': x{%.5f}\n", METHODS(j), coeff);
        end
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