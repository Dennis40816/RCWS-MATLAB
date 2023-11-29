function [file, path] = choose_file(hint, ext, init_path)
    disp(hint);
    f = strcat('*.', ext);
    [file, path]= uigetfile(f, '請選擇檔案', init_path);
    fprintf("已選擇: %s\n", path);
end