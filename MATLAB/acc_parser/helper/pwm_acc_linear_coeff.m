% pwm, acc 都是直的 array
function [coeff] = pwm_acc_linear_coeff(pwm, acc)
    global acc_stat;

    % remove last of t_pwm (it's auto stop)
    pwm(end, :) = [];

    % 重置時間
    t_pwm = pwm(:, 1) - pwm(1, 1);
    acc_start_index = find(acc(:, 1) - pwm(1, 1) >= 0, 1, 'first');
    acc_end_index = find(acc(:, 1) - pwm(end, 1) >= 0, 1, 'first');
    t_acc = acc(acc_start_index:acc_end_index, 1) - pwm(1, 1);

    % 確定軸數量
    num_axes = acc_stat.axis_num;

    % 初始化 cell array
    in_acc_avg = cell(num_axes, 1);
    in_pwm = cell(num_axes, 1);

    for axis = 1:num_axes
        acc_values = acc(acc_start_index:acc_end_index, axis + 1); % 加速度數據位於第 axis+1 列

        for i = 1:(length(t_pwm) - 1)
            % 獲取當前時間段的加速度數據
            seg_start = t_pwm(i);
            seg_end = t_pwm(i + 1);
            segment_indices = (t_acc >= seg_start) & (t_acc < seg_end);
            acc_segment = acc_values(segment_indices);

            % 找出正負峰值
            [peaks_pos, ~] = findpeaks(acc_segment);
            [peaks_neg, ~] = findpeaks(-acc_segment);
            peaks_neg = -peaks_neg; % 轉換回負峰值
            
            % 計算正負峰值的平均
            if length(peaks_pos) == 0 || length(peaks_neg) == 0
                diff_time = t_pwm(2) - t_pwm(1);
                disp_str = sprintf('PWM 產生的頻率過高，演算法失效\n失效點為: %d 及之後的 %.3f(秒)', t_pwm(i), diff_time);
                warning(disp_str);
                continue;
            end
            avg_pos = mean(peaks_pos);
            avg_neg = mean(peaks_neg);

            % 計算加速度偏差和整體平均值
            acc_bias = (avg_pos + avg_neg) / 2;
            in_acc_avg{axis}(i) = (avg_pos + abs(avg_neg) - acc_bias);

            % 獲取對應的 PWM 數據
            in_pwm{axis}(i) = pwm(i, 2 + (axis - 1) * 2);
        end
    end

    % call internal lienar coeff calculater
    coeff = internal_calculate_linear_coeff(in_pwm, in_acc_avg);
end