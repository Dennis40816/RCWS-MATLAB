function [csv_file_paths] = cmd2csv(t, cmd)
    global stat;

    if contains(stat.mode, "WARN")
        csv_file_paths = warn_cmd2csv(t, cmd);
    elseif contains(stat.mode, "FORCE") 
        csv_file_paths = force_cmd2csv(t, cmd);
    end
end