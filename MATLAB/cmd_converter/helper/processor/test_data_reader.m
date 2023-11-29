% add config path
currentFilePath = mfilename('fullpath');
[parentPath, ~, ~] = fileparts(currentFilePath);
[grandParentPath, ~, ~] = fileparts(parentPath);
[grandParentPath, ~, ~] = fileparts(grandParentPath);
addpath(grandParentPath);

% get stat
global stat;
stat = config();

% get data
[scf, dcf, d_kl] = data_reader();