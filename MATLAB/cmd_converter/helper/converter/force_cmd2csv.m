function [] = force_cmd2csv(t, cmd)
      % file name: {mode}_{method}_{stat.time_delta}_{number_index}

      global stat;
      force_csv_path = fullfile(stat.csv_path, "FORCE");

      if stat.is_single_axis
        axis_name = "Single";
      else
        axis_name = "ThreeAxes";
      end

      METHOD_NAME = ["TSM", "APM", "STFTM"];
      paths = [];

      for method_num = 1 : length(METHOD_NAME)

        if strcmp(METHOD_NAME(method_num), "STFTM")
            % for STFTM
            % k bands
            for k = 1 : size(stat.freq_bands, 1)
                freq_info = strcat("f", string(stat.freq_bands(k, 1)), "-f", string(stat.freq_bands(k, 2)));
                file_name_base = strcat(stat.mode, "_", ...
                                        string(METHOD_NAME(method_num)), "_", ...
                                        string(freq_info), "_", ...
                                        string(stat.time_delta), "_", ...
                                        string(axis_name));
                 file_name = find_next_index(force_csv_path, file_name_base, ".csv");

                 cmd_T = cmd{method_num}{k}';
                 t_T = t';

                 % add freq
                 FREQ = 5; % Hz
                 L = size(cmd_T, 1); % 矩陣 cmd_T 的列數
                 n = size(cmd_T, 2); % 矩陣 cmd_T 的欄數
                
                 % 創建新矩陣 new_cmd_T
                 new_cmd_T = zeros(L, 2*n);
                
                 % 將 cmd_T 的每一列和值為 5 的列交替放入 B 中
                 for i = 1:n
                     new_cmd_T(:, 2*i - 1) = cmd_T(:, i);
                     new_cmd_T(:, 2*i) = FREQ;
                 end
                       
                 % replace NaN to 500
                 PAUSE = 500;
                 new_cmd_T(isnan(new_cmd_T)) = PAUSE;

                 if stat.is_single_axis
                    % 補足三軸
                    new_cmd_T(:, 3) = 500;
                    new_cmd_T(:, 4) = 5;
                    new_cmd_T(:, 5) = 500;
                    new_cmd_T(:, 6) = 5;
                end

                 combined_array = [t_T,new_cmd_T];

                 writematrix(combined_array, file_name);
            end
            
        else
            % for TSM APM
            file_name_base = strcat(stat.mode, "_", ...
                                    string(METHOD_NAME(method_num)), "_", ...
                                    string(stat.time_delta), "_", ...
                                    string(axis_name));
            file_name = find_next_index(force_csv_path, file_name_base, ".csv");

            cmd_T = cmd{method_num}';
            t_T = t';

            % add freq
            FREQ = 5; % Hz
            L = size(cmd_T, 1); % 矩陣 cmd_T 的列數
            n = size(cmd_T, 2); % 矩陣 cmd_T 的欄數
            
            % 創建新矩陣 new_cmd_T
            new_cmd_T = zeros(L, 2*n);
            
            % 將 cmd_T 的每一列和值為 5 的列交替放入 B 中
            for i = 1:n
                new_cmd_T(:, 2*i - 1) = cmd_T(:, i);
                new_cmd_T(:, 2*i) = FREQ;
            end
            
            % replace NaN to 500
            PAUSE = 500;
            new_cmd_T(isnan(new_cmd_T)) = PAUSE;

            if stat.is_single_axis
                % 補足三軸
                new_cmd_T(:, 3) = 500;
                new_cmd_T(:, 4) = 5;
                new_cmd_T(:, 5) = 500;
                new_cmd_T(:, 6) = 5;
            end


            combined_array = [t_T,new_cmd_T];

            writematrix(combined_array, file_name);
        end
      disp(["Store `" + string(stat.mode) + " " + ...
          string(METHOD_NAME(method_num)) + " " + ...
          "` csv to:" + newline + file_name]);
        
      % update paths
      paths = [path, file_name];
      end
end