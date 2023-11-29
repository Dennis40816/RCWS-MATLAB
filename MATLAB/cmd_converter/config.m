function stat = config()
%% user modification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % generate only one axis data: true / false
    FUSE_DATA_TO_SINGLE_AXIS = false;
    
    % generate command mode: "WARN_BIN" / "WARN_LEVEL" / "FORCE_LINEAR"
    MODE = "FORCE_LINEAR";
    
    % time delta in second
    TIME_DELTA_SEC = 0.15;
    
    % compress strategy, only be used when FUSE_DATA_TO_SINGLE_AXIS set to
    % `true`. For more details, see
    % `helper/compress/compress_to_single_axis.m`.
    COMPRESS_STRATEGY = "ABS_MAX";
    
    % freq_band, only used in STFTM
    % could be something like [[1, 200]; [500, 2000]] (Hz)
    FREQ_BANDS = [[1,5];[]];

    % STFT related
    % STFT overlap percent
    OVERLAP_PERCENT = 50;

    % leakage
    LEAKAGE = 0.7;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Data related parameters

    fullFileName = mfilename('fullpath');
    [parentPath, ~, ~] = fileparts(fileparts(fullFileName));
    [grandParentPath, ~, ~] = fileparts(parentPath);
    
    DATA_PATH = fullfile(grandParentPath, 'Data');
    SCF_PATH = fullfile(DATA_PATH, "SCF.xlsx");
    DCF_PATH = fullfile(DATA_PATH, "DCF.xlsx");
    D_KL_PATH = fullfile(DATA_PATH, "DKL.xlsx");

    CSV_PATH = fullfile(grandParentPath, 'CSV');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % @todo: add sub namespace `in`, `out`
    % generate stat struct
    % fieldname list below
    % --------------------
    % FOR INPUT
    % 1. is_single_axis         Boolean
    % 2. mode                   String("WARN_BIN" / "WARN_LEVEL" / "FORCE_LINEAR")                       
    % 3. time_delta             Float
    % 4. compress_strategy      String("ABS_MAX")
    % 5. file_path              String
    %     - scf
    %     - dcf
    %     - d_kl
    % 6. freq_bands             Float Array[n][2] -> 
    %                              [[freq_start1, freq_end1]; [freq_start2, freq_end2]; ...] 
    % --------------------
    % FOR OUTPUT
    % a. plot_data                    
    %    1. APM          
    %       - P                 See data_sampler::find_segment_peaks()
    %    2. STFTM
    %       - energy:           Float Array [n][L][k], n 跟上方的 freq_bands 長度相同
    %                                                  L 跟 sampled 後 t 長度一樣 (以 delta_time 取樣)
    %                                                  k 是 raw data 有幾軸資訊 (受 is_single_axis 影響)
    %                                                  
    %       - total_energy      Float Array [L][k]
    %       - stft_info         TODO: 
    % --------------------
    % INPUT AND OUTPUT
    % 1. fs (sampling rate)     Float
    %       in:  from scf
    %       out: used in STFTM
    stat.is_single_axis = FUSE_DATA_TO_SINGLE_AXIS;
    stat.mode = MODE;
    stat.time_delta = TIME_DELTA_SEC;
    stat.compress_strategy = COMPRESS_STRATEGY;
    stat.file_path.scf = SCF_PATH;
    stat.file_path.dcf = DCF_PATH;
    stat.file_path.d_kl = D_KL_PATH;
    stat.freq_bands = FREQ_BANDS;
    stat.leakage = LEAKAGE;
    stat.overlap_percent = OVERLAP_PERCENT;
    stat.csv_path = CSV_PATH;
end