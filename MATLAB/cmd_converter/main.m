%% Principles
%  - 所有的一維陣列都是橫向的
%  - 二維陣列是有同個維度的許多一維陣列組成的，都使用 `;` 隔開

%% TODO
% 修改與確認所有 array 格式皆為正確

%% Global status (會由其他程式進行修改，所以宣告成 global)
global stat;

%% Load config, return a stat handle obj
stat = config()

% add all helpers path
addpath(genpath("helper"));
addpath(genpath("../util"));

%% Main

% scf = [t; x; y; z];
% dcf = [t; x; y; z];
% d_kl = [t; x; y; z];
% 請注意此處的 t 是 raw t
[scf, dcf, d_kl] = data_reader();

% pick correct data
if contains(stat.mode, "WARN")
    data = d_kl;
else
    data = dcf;
end

% TODO: move to helper/plotter
% plot scf-dcf diagram
figure;
hold on;
axes_name = ['X', 'Y', 'Z'];

for j = 1 : 3
    subplot(3, 1, j);
    plot(scf(1, :) - scf(1, 1), scf(j + 1, :), 'LineWidth',3);
    ylabel('SCF (N)', 'FontSize', 18, 'FontWeight', 'bold');

    yyaxis right;
    plot(dcf(1, :) - dcf(1, 1), dcf(j + 1, :), 'LineWidth',3);
    ylabel('DCF (N)', 'FontSize', 18, 'FontWeight', 'bold');
    
    xlabel('Time (s)', 'FontSize', 18, 'FontWeight', 'bold');

    legend('SCF', 'DCF', 'FontSize', 18, 'FontWeight', 'bold');

    title_str = sprintf("SCF - DCF Diagram of %s Axis", axes_name(j));
    title(title_str, 'FontSize', 24);

    % modify axis font
    ax = gca;
    ax.FontSize = 16;
    ax.FontWeight = 'bold';

    % modify yyaxis range
    r_ylim = ylim;
    yyaxis left;
    ylim(r_ylim);
end

% TODO: move to helper/plotter
% plot KLD
figure;
hold on;
axes_name = ['X', 'Y', 'Z'];
rgb_color_98d98e = [215,249,196] / 255;
THRESHOLD_DKL = 1;

for j = 1 : 3
    subplot(3, 1, j);

    t = d_kl(1, :) - d_kl(1, 1);
    d_kl_data = d_kl(j + 1, :);
    
    % use abs
    above_one = abs(d_kl_data) > THRESHOLD_DKL;
    start_idx = find(diff([0, above_one, 0]) == 1);
    end_idx = find(diff([0, above_one, 0]) == -1) - 1;
    
    hold on;
    plot(t, d_kl_data, 'LineWidth', 3);

    % get ylim
    y_lim = ylim;

    for k = 1:length(start_idx)
        h = fill([t(start_idx(k)), t(end_idx(k)), t(end_idx(k)), t(start_idx(k))], ...
             [min(y_lim), min(y_lim), max(y_lim), max(y_lim)], ...
             rgb_color_98d98e, 'EdgeColor', 'none'); 
        uistack(h, 'bottom');
    end

    
    hold off;

    ylabel('DKL', 'FontSize', 18, 'FontWeight', 'bold');
    xlabel('Time (s)', 'FontSize', 18, 'FontWeight', 'bold');

    title_str = sprintf("KLD Diagram of %s Axis ", axes_name(j));
    title(title_str, 'FontSize', 24);

    ax = gca;
    ax.FontSize = 16;
    ax.FontWeight = 'bold';
end

% process and get command
[t, cmd] = data_processor(data);

%% CSV
csv_paths = cmd2csv(t, cmd);

%% Plot

% TODO: plot three-axes scf, dcf, d_kl

% plot three methods vs dcf if 
if contains(stat.mode, "FORCE")
    disp("Do three methods cmd plot with dcf");
    % csv_paths should be [tsm_csv_path; apm_csv_path; stftm_csv_path];
    
    if stat.write_csv_enable
        three_methods_cmd_plotter(csv_paths, dcf);
    else
        % TODO: base path is incorrect
        three_methods_cmd_plotter;
    end
else
    disp("Do warn cmd plotter with scf and dcf");

    % csv_paths should be warn_csv

    if stat.write_csv_enable
        warn_cmd_plotter(csv_paths, scf, dcf);
    else
        % TODO: base path is incorrect
        warn_cmd_plotter;
    end
end