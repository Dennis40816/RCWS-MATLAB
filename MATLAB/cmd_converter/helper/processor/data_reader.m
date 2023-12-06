function [processed_scf_data, processed_dcf_data, D_KL] = data_reader()
    % Global status (由其他程序修改)
    global stat;

    %% Read data
    scf_table = readtable(stat.file_path.scf, 'VariableNamingRule', 'preserve');
    dcf_table = readtable(stat.file_path.dcf, 'VariableNamingRule', 'preserve');

    % 将表格转换为数组
    scf_data = table2array(scf_table)';
    dcf_data = table2array(dcf_table)';

    % 计算平均采样间隔
    avg_sampling_interval = mean(diff(scf_data(1, :)));
    stat.fs = 1 / avg_sampling_interval;

    % 处理重复时间点
    scf_data = adjust_times(scf_data, stat.fs);
    dcf_data = adjust_times(dcf_data, stat.fs);

    % 创建新的时间向量
    new_time_vector = scf_data(1, 1):avg_sampling_interval:scf_data(1, end);

    % 重新采样
    for i = 2:size(scf_data, 1)
        processed_scf_data(i, :) = interp1(scf_data(1, :), scf_data(i, :), new_time_vector, 'linear', 'extrap');
        processed_dcf_data(i, :) = interp1(dcf_data(1, :), dcf_data(i, :), new_time_vector, 'linear', 'extrap');
    end
    processed_scf_data(1, :) = new_time_vector;
    processed_dcf_data(1, :) = new_time_vector;

    %% 计算 KL 散度
    D_KL = zeros(size(processed_scf_data));
    D_KL(1, :) = processed_scf_data(1, :); % 添加时间到 D_KL
    for i = 2:4
        P = processed_scf_data(i, :);
        Q = processed_dcf_data(i, :);

        P(P == 0) = eps(0); % 替换 0 以避免除以 0
        Q(Q == 0) = eps(0);

        % P 和 Q 要 abs 化?
        new_P = P;
        new_Q = Q;

        D_KL(i, :) = abs(new_P .* log10(new_P ./ new_Q));
    end

    %% 更新时间分辨率

    % 如果 stat.time_delta <= stat.fs，则修改 stat.time_delta
    if stat.time_delta <= (1 / stat.fs)
        while stat.time_delta <= (1 / stat.fs)
            stat.time_delta = 2 * stat.time_delta;
        end
        warning("\nRaised owing to `stat.time_delta <= stat.fs`\nstat.time_delta modified to: %.3f second", stat.time_delta);
    end
end

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
