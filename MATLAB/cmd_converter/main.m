%% Principles
%  - 所有的一維陣列都是橫向的
%  - 二維陣列是有同個維度的許多一維陣列組成的，都使用 `;` 隔開

%% TODO
% 修改與確認所有 array 格式皆為正確

%% Global status (會由其他程式進行修改，所以宣告成 global)
global stat;

%% Load config, return a stat handle obj
stat = config();

% add all helpers path
addpath(genpath("helper"));

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

% process and get command
[t, cmd] = data_processor(data);

%% CSV
csv_paths = cmd2csv(t, cmd);

%% Plot

% TODO: plot three-axes scf, dcf, d_kl

% plot three methods vs dcf if 
if contains(stat.mode, "FORCE")
    disp("Do three methods cmd plot with dcf");
    % csv_paths should be [tsm_csv_path, apm_csv_path, stftm_csv_path];
    three_methods_cmd_plotter(csv_paths, dcf);
end