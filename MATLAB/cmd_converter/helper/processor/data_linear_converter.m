function linear_converted_series = data_linear_converter(series)
    CONST_STFTM = 3;
    VIBRATE_MAX = 999;
    VIBRATE_MIN = 500;

    linear_converted_series.t = series.t;

    % TSM, APM, STFTM
    for method = 1 : 3

        % STFTM
        if method == CONST_STFTM
            % k: freq_bands
            for k = 1 : size(series.cmd{method}, 2)
                mapped_data = [];
                for j = 1 : size(series.cmd{method}{k}, 1)
                   
                    row_data = series.cmd{method}{k}(j, :);
                    row_max = max(row_data);
                    row_min = min(row_data);

                    % 避免除以零的情況
                    if row_max == row_min
                        mapped_data(j, :) = ones(size(row_data)) * VIBRATE_MIN;
                    else
                        scale = (VIBRATE_MAX - VIBRATE_MIN) / (row_max - row_min);
                        offset = VIBRATE_MIN - row_min * scale;
    
                        % 應用線性映射
                        mapped_data(j, :) = row_data * scale + offset;
                    end
                    

                end

                % assign mapped data to mapped_cmd
                mapped_cmd{method}{k} =  mapped_data;
            end

        % for case TSM, APM
        else
            mapped_data = [];
            % j axis
            for j = 1 : size(series.cmd{method}, 1)
                row_data = series.cmd{method}(j, :);
                row_max = max(row_data);
                row_min = min(row_data);

                if row_max == row_min
                    mapped_data(j, :) = ones(size(row_data)) * VIBRATE_MIN;
                else
                    scale = (VIBRATE_MAX - VIBRATE_MIN) / (row_max - row_min);
                    offset = VIBRATE_MIN - row_min * scale;
                    mapped_data(j, :) = row_data * scale + offset;
                end
            end
            
            mapped_cmd{method} = mapped_data;
        end
    end
    
    % mapped_cmd{method}
    % - TSM
    % - APM
    % mapped_cmd{method}{k}: k 是 freq_bands
    % - STFTM
    linear_converted_series.cmd = mapped_cmd;
end