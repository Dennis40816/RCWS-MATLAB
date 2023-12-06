% tmp
function [target] = compress_to_single_axis(raw, strategy)
    t = raw(1, :); % Time axis remains the same
    data = raw(2:4, :); % Data to be compressed

    if strcmp(strategy, "ABS_MAX")
        % Compute absolute values
        abs_data = abs(data);

        % Get max index of every column
        [~, max_index] = max(abs_data, [], 1); % Find max along rows

        % Initialize compressed_data
        compressed_data = zeros(1, size(abs_data, 2));

        % Iterate over each column to select the maximum absolute value
        for col = 1 : size(abs_data, 2)
            compressed_data(col) = abs_data(max_index(col), col);
        end

    elseif strcmp(strategy, "ENERGY")
        % compress along row axis
        compressed_data = sqrt(sum(data.^2, 1));
    end

    target = [t; compressed_data]; % Concatenate time axis with compressed data
end
% Brief:
%
% raw 是一個含時間軸和三軸數據的 array. [t, d1, d2, d3]
% strategy 是壓縮策略. 有 "ABS_MAX" ...(TODO) 