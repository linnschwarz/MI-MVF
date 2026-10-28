%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana03_2_EMG_preprocessing.m
%
% This script preprocesses the EMG recordings previously converted to
% EEGLAB .set files and segments the continuous data into epochs relative
% to motor imagery onset.
%
% The following steps are performed:
%           - Load the previously converted EEGLAB SET files
%           - Retain the three channels used for EMG recording
%           - Apply a high-pass FIR filter
%           - Apply wavelet-based signal denoising
%           - Segment the continuous data into epochs relative to motor
%             imagery onset
%           - Save the preprocessed and epoched datasets as EEGLAB SET files
%
% Input:    - EEGLAB SET files containing the continuous recordings
%
% Output:   - Preprocessed and epoched EEGLAB SET files
%
% Note:     Only channels 1–3 are retained because these channels were
%           connected to the EMG electrodes during data acquisition.
%           The remaining channels were not connected to the participant.
%
% Linn Schwarz 09/10/2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DIRECTORIES

clear; close all; 

% execute this script from within the 'scripts' folder
MAINPATH = fileparts(pwd);
PATHIN  = fullfile(MAINPATH,'rawdata_EMG',filesep);      % path containing rawdata
PATHOUT = fullfile(MAINPATH, 'data','lis03_EMG', 'preprocessed',filesep);  % path for script output

% create output folder if it does not exist yet
if ~exist(PATHOUT)
    mkdir(PATHOUT);
end

% locate rawdata-sets
cd(PATHIN)
list=dir('*.set');  % reads all .set files in PATHIN
len=length(list);   % total number of datasets that will be evaluated
fname=cell(1,len);   % create a subject vector

%% PARAMETERS

% epoching parameters relative to motor imagery onset
EPOCH_ON  = -1;                 % epoch start in seconds
EPOCH_OFF = 4.5;                % epoch end in seconds
ev = '40';                      % event marker indicating motor imagery onset

% high-pass FIR filter parameters
HP_erp = 1;                     % high-pass cutoff frequency in Hz
HP_ord = 1650;                  % filter order o = pop_firwsord('hamming', 1000, 2)

%% INITIALIZE EEGLAB

% start EEGLAB
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

%% PREPROCESS EMG DATA AND EPOCH RELATIVE TO MOTOR IMAGERY ONSET

% loop over datasets
for s=1:len

    % obtain dataset name and load continuous recording
    fname{s} = strrep(list(s).name, '.set', '');
    EEG = pop_loadset('filename', [fname{s}, '.set'], 'filepath', PATHIN);

    % retain the three channels used for EMG recording
    EEG = pop_select(EEG, 'channel', 1:3);

    % apply high-pass FIR filter using a Hamming window
    EEG = pop_firws(EEG, 'fcutoff', HP_erp, 'ftype', 'highpass', 'wtype', 'hamming', 'forder', HP_ord);

    % wavelet denoising
    for ch = 1:size(EEG.data,1)
        EEG.data(ch,:) = wdenoise(double(EEG.data(ch,:)),4,'Wavelet', 'db4','DenoisingMethod', 'Bayes', 'ThresholdRule', 'Soft','NoiseEstimate', 'LevelDependent');
    end

    % segment data into epochs relative to motor imagery onset
    EEG = pop_epoch(EEG, {ev}, [EPOCH_ON EPOCH_OFF],'epochinfo', 'yes');

    % assign dataset name and save preprocessed data
    EEG.setname = [fname{s}, '_epoched'];
    pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', PATHOUT);
end

% return to scripts folder
cd(fullfile(MAINPATH, 'scripts', filesep));

% end of script