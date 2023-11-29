global stat;

stat = config();
my();
stat.file_path

function [] = my()
    global stat;

    stat.file_path.ne = "test";
end

