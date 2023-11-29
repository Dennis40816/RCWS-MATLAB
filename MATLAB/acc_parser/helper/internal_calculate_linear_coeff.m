function [coeff] = internal_calculate_linear_coeff(base, target)
    if length(base) ~= length(target)
        error("base length != target length");
    end
    
    coeff = []; % 按照軸來排列 [x, y, z]

    for j = 1 : length(base)
        % make sure direction, should be straight array
        base_array = reshape(base{j}, [], 1);
        target_array = reshape(target{j}, [], 1);;

        corr_maxtrix = corr(base_array, target_array);
        coeff(j) = corr_maxtrix;
    end



end

% 計算線性相關係數
% base: 一個 cell array，其中 length(base) 是軸數
% target: 一個 cell array，其中 length(target) 是軸數
