% 假設的文件名
files = {"WARN_BIN_0.15_0.csv", "WARN_BIN_0.15_1.csv", "WARN_BIN_0.15_2.csv"};

% 基本文件名
file_name_base = "WARN_BIN_0.15";

% 轉義點字符
file_name_base_escaped = regexprep(file_name_base, '\.', '\\.');

% 初始化最大索引
max_index = -1;

% 遍歷文件名
for i = 1:length(files)
    % 從文件名中提取數字，只匹配最後一個 _ 和數字組合
    [~, name, ~] = fileparts(files{i});
    tokens = regexp(name, '.*?_(\d+)$', 'tokens');
    if ~isempty(tokens) && ~isempty(tokens{1})
        num = str2double(tokens{1}{1});
        if ~isnan(num) && num > max_index
            max_index = num;
        end
    end
end

% 顯示最大索引
disp(max_index);
