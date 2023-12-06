function [] = acc_plotter(pwm, acc)
    global acc_stat;
    
    % remove last of t_pwm (it's auto stop)
    if size(pwm(:, 1), 1) ~= size(unique(pwm(:, 1)), 1) 
        pwm(end, 1) = pwm(end, 1) + eps(pwm(end, 1));
    end

    % reset t
    t_pwm = pwm(:, 1) - pwm(1, 1);

    acc_start_index = find(acc(:, 1) - pwm(1, 1) >= 0, 1, 'first');
    t_acc = acc(acc_start_index:end, 1) - pwm(1, 1);
    acc = acc(acc_start_index:end, :);

    % 確定軸數量
    num_axes = acc_stat.axis_num;

    % 對齊 PWM 數據與加速度數據
    pure_pwm = pwm(:, 2:2:num_axes*2);
    pwm_zoh = interp1(t_pwm, pure_pwm, t_acc, 'previous');
    pwm_zoh(isnan(pwm_zoh)) = pure_pwm(find(~isnan(pure_pwm), 1, 'last'));

    % 為每個軸創建圖形
    axes_name = ["X";"Y";"Z"];
    for i = 1:num_axes
        figure;
        hold on;

        % 找出靜止時的加速度平均值
        static_indices = pwm_zoh(:, i) >= 490 & pwm_zoh(:, i) <= 510;
        acc_static_avg = mean(acc(static_indices, i+1));

        % 移除加速度平均值
        acc(:, i+1) = acc(:, i+1) - acc_static_avg;

        % 使用 Savitzky-Golay 法平滑
        acc(:, i+1) = smooth(acc(:, i+1), 10, 'sgolay', 2); 

        % 繪製加速度數據
        yyaxis left
        p_r = plot(t_acc, acc(:, i+1), 'LineWidth', 1.5);
        ylabel('Accelerometer (g)', 'FontWeight', 'bold', 'FontSize', 18);
        ylim([0, 9]);

        % 繪製 PWM 數據
        yyaxis right
        p_l = plot(t_acc, pwm_zoh(:, i), 'LineWidth', 2);
        ylabel('PWM (‰)', 'FontWeight', 'bold', 'FontSize', 18);
        ylim([500, 1000]); 
        
        title_str = sprintf('PWM - ACC Diagram of %s Axis', axes_name(i));
        title(title_str, 'FontSize', 24);
        xlabel('Time (s)', 'FontWeight', 'bold', 'FontSize', 18);
        legend('Acc', 'PWM command', 'FontWeight', 'bold', 'FontSize', 18);
        hold off;

        ax = gca;
        ax.FontSize = 18;
        ax.FontWeight = "bold";
    end
end
