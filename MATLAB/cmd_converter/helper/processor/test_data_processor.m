% 创建模拟 raw 数据
% 假设 raw 数据包含一列时间戳和三列数据
timeStamps = (0:0.1:10)'; % 时间戳从 0 开始，每 0.1 秒一个数据点，共 101 个数据点
data1 = rand(size(timeStamps)); % 随机生成数据列
data2 = rand(size(timeStamps));
data3 = rand(size(timeStamps));
raw = [timeStamps, data1, data2, data3];

% 设置一个预定义的随机数种子以获得可重复的结果
rng(0);
raw(:, 2:end) = rand(size(timeStamps, 1), 3);

% 测试 WARN_BIN 模式
stat.mode = "WARN_BIN";
stat.is_single_axis = false; % 假设不需要压缩为单一轴
stat.time_delta = 0.1; % 假设采样间隔仍然是 0.1 秒

% 调用 data_processor 函数
[t_bin, cmd_bin] = data_processor(raw, stat);

% 使用 assert 进行验证
% 预期的行为是所有数据值大于等于 1 的都被设置为 999，其余为 500
expected_cmd_bin = repmat(500, size(raw, 1), size(raw, 2) - 1);
expected_cmd_bin(raw(:, 2:end) >= 1) = 999;

% 使用 assert 检查 cmd_bin 是否如预期
assert(isequal(cmd_bin, expected_cmd_bin), 'WARN_BIN mode did not work as expected.');

% 测试 WARN_LEVEL 模式
stat.mode = "WARN_LEVEL";
stat.is_single_axis = false; % 假设不需要压缩为单一轴

% 调用 data_processor 函数
[t_level, cmd_level] = data_processor(raw, stat);

% 验证 WARN_LEVEL 模式的输出
% 我们定义了三个阈值，并且根据这些阈值设置了命令值
STRONG_THRESHOLD = 1;
MID_THRESHOLD = 0.9;
LIGHT_THRESHOLD = 0.8;
STRONG_CMD = 999;
MID_CMD = 750;
LIGHT_CMD = 600;
NO_VIBRATION_CMD = 500;

% 生成预期的命令矩阵
expected_cmd_level = repmat(NO_VIBRATION_CMD, size(raw, 1), size(raw, 2) - 1);
expected_cmd_level(raw(:, 2:end) >= STRONG_THRESHOLD) = STRONG_CMD;
expected_cmd_level(raw(:, 2:end) >= MID_THRESHOLD & raw(:, 2:end) < STRONG_THRESHOLD) = MID_CMD;
expected_cmd_level(raw(:, 2:end) >= LIGHT_THRESHOLD & raw(:, 2:end) < MID_THRESHOLD) = LIGHT_CMD;

% 使用 assert 检查 cmd_level 是否如预期
assert(isequal(cmd_level, expected_cmd_level), 'WARN_LEVEL mode did not work as expected.');

% 如果所有 assert 都通过，没有错误抛出，表示测试通过
disp('All tests passed.');
