function [paths] = warn_cmd2csv(t, cmd)
    % file name: {mode}_{stat.time_delta}_{number_index}

    global stat;
    warn_csv_path = fullfile(stat.csv_path, "WARN");

    if stat.is_single_axis
        axis_name = "Single";
    else
        axis_name = "ThreeAxes";
    end

    file_name_base = strcat(stat.mode, "_", string(stat.time_delta), "_", string(axis_name));

    file_name = find_next_index(warn_csv_path, file_name_base, ".csv");

    % store cmd to csv file
    cmd_T = cmd';

    % add freq
    FREQ = 5; % Hz
    L = size(cmd_T, 1); % 矩陣 cmd_T 的列數
    n = size(cmd_T, 2); % 矩陣 cmd_T 的欄數
    
    % 創建新矩陣 new_cmd_T
    new_cmd_T = zeros(L, 2*n);
    
    % 將 cmd_T 的每一列和值為 5 的列交替放入 B 中
    for i = 1:n
        new_cmd_T(:, 2*i - 1) = cmd_T(:, i);
        new_cmd_T(:, 2*i) = FREQ;
    end

    if stat.is_single_axis
        % 補足三軸
        new_cmd_T(:, 3) = 500;
        new_cmd_T(:, 4) = 5;
        new_cmd_T(:, 5) = 500;
        new_cmd_T(:, 6) = 5;
    end

    t_T = t';
    combined_array = [t_T,new_cmd_T];

    writematrix(combined_array, file_name);
    disp(["Store `" + string(stat.mode) + "` csv to:" + newline + file_name]);
    
    % return paths
    paths = [file_name];
end