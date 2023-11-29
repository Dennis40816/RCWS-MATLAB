function file_name = find_next_index(folder, file_name_base, file_ext)

    % filename: <file_name_base>_index
    
    % check folder existed
    if ~exist(folder, 'dir')
        mkdir(folder);
    end

    files = dir(fullfile(folder, strcat(file_name_base, '*')));
    index = 0;
    max_index = 0;

    if isempty(files)
        file_name = strcat(file_name_base, "_", string(index));
        % add folder and extension
        file_name = fullfile(folder, file_name);
        file_name = strcat(file_name, file_ext);
        return;
    end

    for i = 1:length(files)
        % 從文件名中提取數字，只匹配最後一個 _ 和數字組合
        [~, name, ~] = fileparts(files(i).name);
        tokens = regexp(name, '.*?_(\d+)$', 'tokens');
        if ~isempty(tokens) && ~isempty(tokens{1})
            num = str2double(tokens{1}{1});
            if ~isnan(num) && num > max_index
                max_index = num;
            end
        end
    end

    index = max_index + 1;
    file_name = strcat(file_name_base, "_", string(index));
    
    % add folder and extension
    file_name = fullfile(folder, file_name);
    file_name = strcat(file_name, file_ext);
end