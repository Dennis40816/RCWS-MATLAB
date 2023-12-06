% ext: Extension name of file. When input equal to '' (empty string) ->
%      list all files.
function [file, path] = choose_file(hint, ext, init_path)
    disp(hint);

    if isempty(ext)
        f = strcat('*', ext);
    else
        f = strcat('*.', ext);
    end
    [file, path]= uigetfile(f, hint, init_path);
    fprintf("choosed: %s\n", fullfile(path, file));
end