function [] = three_methods_cmd_plotter(csv_paths, dcf)
    global stat;
    
    % add choose_file
    addpath("../acc_parser/helper/");

    should_repick = false;

    if nargin == 0
        should_repick = true;
    end

    if should_repick
        METHODS = ["TSM", "APM", "STFTM"];
        csv_paths = [];
        % for three methods
        CSV_DEFAULT_PATH = "../../CSV";

        for j = 1 : length(METHODS)
            hint = sprintf("請選擇要比較的 %s 檔案:\n", METHODS(j));
            [file, path] = choose_file(hint, 'csv', CSV_DEFAULT_PATH);
            csv_paths = [csv_paths, path];
        end
    end

    % plot logic
end