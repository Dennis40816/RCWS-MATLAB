%% pwm 的母資料夾名稱是否包含Single 決定 axis_num
config();

global acc_stat;

% add hepler
addpath(genpath("helper"));
addpath(genpath("../util"));

% base on ../../Data/Acc
base_path = "../../Data/Acc";
dcf_path = "../../Data";

% PWM
[file, path] = choose_file('Select PWM file', 'txt', base_path);
if path == 0
    disp('Nothing chosen, leave!');
    return;
end
pwm_txt = readmatrix(fullfile(path,file));

[parentDirPath, ~, ~] = fileparts(path);
[~, parentDirName, ~] = fileparts(parentDirPath);

% Determin axis num
if contains(parentDirName, "Single") || contains(parentDirName, "single")
    acc_stat.axis_num = 1;
else
    acc_stat.axis_num = 3;
end

% ACC
[file, path] = choose_file('Select ACC file', 'txt', base_path);
if path == 0
    disp('Nothing chosen, leave!');
    return;
end
acc_txt = readmatrix(fullfile(path,file));

% plot PWM vs ACC
acc_plotter(pwm_txt, acc_txt);

% pick DCF
[file, path] = choose_file('Select DCF file', 'xlsx', dcf_path);
if path == 0
    disp('Nothing chosen, leave!');
    return;
end

dcf_csv = readmatrix(fullfile(path,file));

% analysis linear 
coeff_result = pwm_acc_linear_coeff(pwm_txt, acc_txt);

fprintf("PWM - ACC corr result:\n ");
for k = 1 : length(coeff_result)
    fprintf(" %d axis: %.4f\n", k, coeff_result(k));
end
