%% Test find_segment_peaks
% Test case for find_segment_peaks function

% Create some synthetic data
% t = linspace(0, 2*pi, 100)'; % time vector
t = linspace(0, 2*pi, 100); % time vector
signal1 = sin(24*t); % first signal, with expected peaks at 0, pi, and 2*pi
signal2 = cos(24*t); % second signal, with expected peaks at pi/2 and 3*pi/2
target = [t; signal1; signal2]; % combine into a matrix

% Define indices for segments
indices = [1, 51, 100]; % segments from 1-50, 51-100

% Call the function with the test data
P = find_segment_peaks(target, indices);

avg_peaks = calculate_average_peaks(P);

% Display results
num_axes_signal_only = (size(target, 1) - 1);
for j = 1 : num_axes_signal_only
    fprintf('Signal %d:\n', j);
    for k = 1 : length(indices)
        fprintf('Segment %d, Peaks indices: ', k);
        disp(P{j}{k}(1, :));
        fprintf('Segment %d, Peaks values: ', k);
        disp(P{j}{k}(2, :));
    end
end

% disp
avg_peaks

%% Functions
function P = find_segment_peaks(target, indices)
    % find_segment_peaks Function to find peaks in each segment of target data.
    % Inputs:
    %   target   - The data matrix where columns represent different
    %              signals. The first column is always `time column`.
    %   indices  - The row indices that define the segments in target.
    % 
    % Outputs:
    %   P        - A cell array where each cell contains the peaks info of each segment.
    %
    %   P{j}{k}    j 代表 axis, k 代表 segment (跟 stat.time_delta 有關)
    %              這裡面應該包含一個二維陣列 [peak_indices;peak_values]
    %
    % Example:
    %   P{j}{k} 的 peak_indices -> P{j}{k}(1, :)
    %   P{j}{k} 的 peak_values -> P{j}{k}(2, :)
    % 
    
    % Initialize the cell array to store peaks information
    num_axes_including_time = size(target, 1);
    P = cell(1, num_axes_including_time - 1);

    % Loop over each segment defined by indices
    for k = 1:length(indices)
        if k < length(indices)
            cols = indices(k):indices(k+1)-1;
        else
            cols = indices(k):size(target, 1);
        end
    
        % Pick the current segment
        segment = target(2:end, cols);
    
        % Check if the segment has more than one element
        if size(segment, 2) > 1
            % Find peaks in each column of the segment
            for j = 1 : size(segment, 1)
                [pks, locs] = findpeaks(segment(j, :));
                P{j}{k} = [locs; pks];
            end
        else
            % If the segment is a single element, set the peak to 0
            for j = 1 : size(segment, 1)
                P{j}{k} = [0 ; 0]; % Use [0, 0] to indicate no peak
            end
        end
    end
end

% function P = find_segment_peaks(target, indices)
%     % find_segment_peaks Function to find peaks in each segment of target data.
%     % Inputs:
%     %   target   - The data matrix where columns represent different signals.
%     %   indices  - The row indices that define the segments in target.
%     % Outputs:
%     %   P        - A cell array where each cell contains the peaks info of each segment.
% 
%     % Initialize the cell array to store peaks information
%     P = cell(length(indices), 1);
% 
%     % Loop over each segment defined by indices
%     for k = 1:length(indices)
%         if k < length(indices)
%             rows = indices(k):indices(k+1)-1;
%         else
%             rows = indices(k):size(target, 1);
%         end
% 
%         % Pick the current segment
%         segment = target(rows, 2:end);
% 
%         % Check if the segment has more than one element
%         if size(segment, 1) > 1
%             % Find peaks in each column of the segment
%             for j = 1 : size(segment, 2)
%                 [pks, locs] = findpeaks(segment(:, j));
%                 P{k}{j} = [locs, pks];
%             end
%         else
%             % If the segment is a single element, set the peak to 0
%             for j = 1 : size(segment, 2)
%                 P{k}{j} = [0, 0]; % Use [0, 0] to indicate no peak
%             end
%         end
%     end
% end

% function avg_peaks = calculate_average_peaks(P)
%     % calculate_average_peaks Calculate the average of peaks for each segment and axis.
%     % Inputs:
%     %   P        - A cell array where each cell contains the peaks info of each segment.
%     % Outputs:
%     %   avg_peaks - A matrix of average peak values for each segment and axis.
% 
%     num_segments = length(P); % The number of segments
%     if num_segments > 0
%         num_axes = length(P{1}); % The number of axes (assuming all segments have the same number of axes)
%         avg_peaks = zeros(num_segments, num_axes); % Initialize the output matrix
% 
%         % Calculate average peaks for each segment and axis
%         for k = 1:num_segments
%             for n = 1:num_axes
%                 % Extract the peak values for this axis and segment
%                 peak_values = P{k}{n}(:, 2);
% 
%                 % Calculate the average of the peak values
%                 avg_peaks(k, n) = mean(peak_values);
%             end
%         end
%     else
%         avg_peaks = []; % Return an empty array if P is empty
%     end
% end

function avg_peaks = calculate_average_peaks(P)
    % calculate_average_peaks Calculate the average of peaks for each segment and axis.
    % Inputs:
    %   P        - A cell array where each cell contains the peaks info of each segment.
    % Outputs:
    %   avg_peaks - A matrix of average peak values for each segment and axis.

    num_axes = length(P); % The number of axes

    if num_axes == 0
        avg_peaks = [];
        return;
    end

    % assume length in every axis is same
    num_segments = length(P{1});
    avg_peaks = zeros(num_axes, num_segments);

    % iterate P
    for j = 1 : num_axes
        for k = 1 : num_segments
            peak_values = P{j}{k}(2, :);
            
            % Calculate the average of the peak values
            avg_peaks(j, k) = mean(peak_values);
        end
    end
end
