%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana05_time_frequ_ERD.m
%
% This script performs a time-frequency analysis and calculates ERD/ERS
% for the preprocessed MI datasets.
%
% The following steps are performed:
%           - Read in preprocessed and artifact-cleaned MI EEG datasets
%           - Perform time-frequency decomposition for selected
%             sensorimotor electrodes using EEGLAB's pop_newtimef
%           - Calculate single-trial power from complex wavelet coefficients
%           - Calculate a trial-averaged baseline for each frequency
%           - Normalize single-trial power relative to the common baseline
%             to obtain ERD/ERS in percent
%           - Average ERD/ERS across trials for each electrode and dataset
%           - Store ERD/ERS time-frequency matrices together with subject,
%             group, and MI session information
%           - Create a wide-format structure combining MI1 and MI2 data
%             for each participant
%
% Input:    - Preprocessed and artifact-cleaned MI EEG datasets from lis04_2
%             after final epoch rejection (_ep_ar_man.set)
%
% Output:   - time_frequency_data_struct.mat:
%             ERD/ERS time-frequency data in long format
%           - ersp_struct.mat:
%             EEGLAB ERSP output for each electrode and dataset
%           - times.mat:
%             Common time vector used for the time-frequency analysis
%           - frequencies.mat:
%             Common frequency vector used for the time-frequency analysis
%           - time_frequency_data_struct_wf.mat:
%             ERD/ERS time-frequency data in wide format with MI1 and MI2
%             combined for each participant
%
% Note:     Participants 23 and 36 were manually removed from the resulting
%           data structures because their mean mu-band ERD values over the
%           contralateral left sensorimotor electrodes during MI1 were
%           non-negative.
%
% Adapted by Linn Schwarz 02/10/2025
% Linn Schwarz 26/11/2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DIRECTORIES

clear; close all;

% execute this script from within the 'scripts' folder
MAINPATH = fileparts(pwd);
PATHIN  = fullfile(MAINPATH,'data','lis04_2',filesep);      % path containing input data             
PATHOUT = fullfile(MAINPATH, 'data','lis05',filesep);  % path for script output

% create output folder if it does not exist yet
if ~exist(PATHOUT)
    mkdir(PATHOUT);
end

% locate datasets
cd(PATHIN)
list=dir('*.set');  % reads all .set files in PATHIN
len=length(list); % total number of datasets that will be evaluated 
fname=cell(1,len); % create a file name cell array

% start eeglab
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

%% PARAMETERS

BL_ON = -1000;      % baseline onset  [ms]
BL_OFF = -500;      % baseline offset [ms]

% define electrodes of interest and corresponding channel indices
e_label = {'FC1','FC2','C3','C4'};
e_num   = [21,22,5,6];

%% CALCULATE TIME-FREQUENCY ERD/ERS

% initialize structures for ERD/ERS and EEGLAB ERSP data
time_frequency_data = struct([]);
ersp_struc = struct([]);

% initializing counter
entry = 1;

% loop over all preprocessed datasets
for s=1:len

    % load dataset
    fname{s} = strrep(list(s).name, '_ep_ar_man.set', '');
    EEG = pop_loadset('filename', [fname{s}, '_ep_ar_man.set'], 'filepath',...
        PATHIN);

    % extract subject ID from filename
    sub{s} = strrep(fname{s}, 'lis_mirror_', '');
    subID{s} = extractBefore(sub{s}, '_');

    % determine experimental group from filename
    if contains(fname{s}, 'mt')
        cond_label = 'mt';
    elseif contains(fname{s}, 'sh')
        cond_label = 'sh';
    end

    % determine MI session from filename
    if contains(fname{s}, 'MI1')
        session_label = 'MI1';
    elseif contains(fname{s}, 'MI2')
        session_label = 'MI2';
    end

    % store dataset information in output structures
    time_frequency_data(entry).subject    = subID{s};
    time_frequency_data(entry).group      = cond_label;
    time_frequency_data(entry).session    = session_label;

    ersp_struc(entry).subject                   = subID{s};
    ersp_struc(entry).group                     = cond_label;
    ersp_struc(entry).session                   = session_label;

    % loop over electrodes of interest
    for electrodeidx = 1:length(e_label)

        % perform time-frequency decomposition
        % baseline correction within pop_newtimef is disabled because
        % ERD/ERS normalization is performed manually below
        [ersp,itc,powbase,times,freqs,erspboot,itcboot,tfdata] = pop_newtimef(EEG, 1, e_num(electrodeidx), [-2500  8996], [3  10], 'topovec', e_num(electrodeidx), 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'caption', e_label{electrodeidx},'baseline', [NaN], 'freqs', [5 35], 'freqscale', 'log', 'plotphase', 'off', 'padratio', 1,'trialbase', 'off', 'plotersp','off');

        % check whether time and frequency vectors are consistent across
        % all datasets and electrodes
        if ~exist('times_check','var')
            times_check = times;
            freqs_check = freqs;
        else
            if ~isequal(times, times_check)
                error('Mismatch in TIMES vector for subject %d, electrode %s', s, e_label{electrodeidx});
            end
            if ~isequal(freqs, freqs_check)
                error('Mismatch in FREQS vector for subject %d, electrode %s', s, e_label{electrodeidx});
            end
        end

        % identify time points belonging to the pre-trial baseline interval
        baseline_idx = times >= BL_ON & times <= BL_OFF;

        % calculate single-trial power from complex wavelet coefficients
        trial_power = abs(tfdata).^2;                           % freq x time x trial

        % average power across trials
        trial_power_mean = mean(trial_power,3);                 % freq x time

        % calculate one common baseline value per frequency by averaging
        % trial-averaged power across the baseline interval
        R = mean(trial_power_mean(:,baseline_idx),2);           % freq x 1

        % calculate ERD/ERS (%) for each trial relative to the common
        % trial-averaged baseline
        ERD_percent = (trial_power - R) ./ R * 100;             % freq x time x trial

        % average ERD/ERS across trials
        ERD_mean = mean(ERD_percent,3);                         % freq x time

        % store trial-averaged ERD/ERS matrix for current electrode
        fld = e_label{electrodeidx};   % e.g. 'FC1'
        time_frequency_data(entry).(fld) = ERD_mean;

        % store EEGLAB ERSP output for current electrode
        ersp_struc(entry).(fld) = ersp;

    end

    % store common time and frequency vectors
    time_frequency_data(entry).times      = times;
    time_frequency_data(entry).freqs      = freqs;

    ersp_struc(entry).times                     = times;
    ersp_struc(entry).freqs                     = freqs;

    % increment structure counter
    entry = entry + 1;
end

% save long-format ERD/ERS structure
fullFilePath = fullfile(PATHOUT, 'time_frequency_data_struct.mat');
save(fullFilePath, 'time_frequency_data', '-v7.3');

% save EEGLAB ERSP structure
fullFilePath = fullfile(PATHOUT, 'ersp_struct.mat');
save(fullFilePath, 'ersp_struc', '-v7.3');

% save common time vector
fullFilePath = fullfile(PATHOUT, 'times.mat');
save(fullFilePath, 'times_check');

% save common frequency vector
fullFilePath = fullfile(PATHOUT, 'frequencies.mat');
save(fullFilePath, 'freqs_check');


%% CREATE WIDE-FORMAT STRUCTURE 

% initialize wide-format structure
time_frequency_data_wf = struct(); 

% initialize participant counter
row = 1; 

% combine MI1 and MI2 data for each participant
for entry = 1:length(time_frequency_data)
    
    if contains(time_frequency_data(entry).session, 'MI1')

        % store participant and group information
        time_frequency_data_wf(row).subject = time_frequency_data(entry).subject;
        time_frequency_data_wf(row).group   = time_frequency_data(entry).group;

        % store MI1 ERD/ERS matrices for all electrodes
        for e = 1:length(e_label)
            time_frequency_data_wf(row).([e_label{e} '_MI1']) = time_frequency_data(entry).(e_label{e});
        end

        % store common time and frequency vectors
        time_frequency_data_wf(row).times = time_frequency_data(entry).times;
        time_frequency_data_wf(row).freqs = time_frequency_data(entry).freqs;
        
    elseif contains(time_frequency_data(entry).session, 'MI2')

        % store MI2 ERD/ERS matrices for all electrodes
        for e = 1:length(e_label)
            time_frequency_data_wf(row).([e_label{e} '_MI2']) = time_frequency_data(entry).(e_label{e});
        end

        % continue with next participant after MI2 data have been added
        row = row + 1;
    end
end

% save wide-format ERD/ERS structure
fullFilePath = fullfile(PATHOUT, 'time_frequency_data_struct_wf.mat');
save(fullFilePath, 'time_frequency_data_wf', '-v7.3');

eeglab redraw

% return to scripts folder
cd(fullfile(MAINPATH, 'scripts', filesep));

% end of script