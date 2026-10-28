%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana13_1_extract_clusterbasedpermutation.m
%
% This script calculates channel-wise time-frequency ERD/ERS data for the MVF
% group for subsequent cluster-based permutation analysis.
%
% The following steps are performed:
%           - Load all preprocessed MI datasets
%           - Retain datasets from the MVF group only
%           - Perform time-frequency decomposition for all EEG channels
%             using EEGLAB's pop_newtimef
%           - Calculate single-trial power from complex wavelet coefficients
%           - Calculate a trial-averaged baseline for each frequency
%             within the predefined baseline interval (-1000 to -500 ms)
%           - Normalize single-trial power relative to the common baseline
%             to obtain ERD/ERS in percent
%           - Average ERD/ERS across trials
%           - Store the complete channel x frequency x time ERD/ERS data
%             separately for MI1 and MI2 in FieldTrip-compatible structures
%           - Verify correspondence of MI1 and MI2 datasets across participants
%
% Input:    - Preprocessed MI datasets in EEGLAB SET format
%
% Output:   - permu_data.mat:
%             Cell arrays containing channel x frequency x time ERD/ERS data
%             for MI1 and MI2 in the MVF group
%
% Linn Schwarz 15/06/2026
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DIRECTORIES

clear all; close all;

% execute this script from within the 'scripts' folder
MAINPATH = fileparts(pwd);
PATHIN  = fullfile(MAINPATH,'data','lis04_2',filesep);      % path containing input data
PATHOUT = fullfile(MAINPATH,'data','lis13',filesep);        % path for script output

% create output folder if it does not exist yet
if ~exist(PATHOUT,'dir')
    mkdir(PATHOUT);
end

% locate preprocessed datasets
cd(PATHIN)
list = dir('*.set');
len  = length(list);

% start EEGLAB
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;


%% PARAMETERS

% define baseline interval
BL_ON  = -1000;     % baseline onset [ms]
BL_OFF = -500;      % baseline offset [ms]

%% CALCULATE TIME-FREQUENCY ERD/ERS DATA

% initialize output cell arrays for both MI sessions
MI1 = cell(1,20);
MI2 = cell(1,20);

% initialize session-specific cell array counters
entry_MI1 = 1;
entry_MI2 = 1;

% loop over all preprocessed datasets
for s = 1:len

    % extract dataset name
    fname = strrep(list(s).name, '_ep_ar_man.set', '');

    % retain datasets from the MVF group only
    if ~contains(fname, 'mt')
        continue
    end

    % load dataset
    EEG = pop_loadset('filename', [fname '_ep_ar_man.set'], ...
                      'filepath', PATHIN);

    % extract subject ID from filename
    sub = strrep(fname, 'lis_mirror_', '');
    subID = extractBefore(sub, '_');

    % include all EEG channels
    chan_idx = 1:EEG.nbchan;
    chanlabels = {EEG.chanlocs(chan_idx).labels};

    % loop over all EEG channels
    for c = 1:numel(chan_idx)

        ch = chan_idx(c);

        % perform time-frequency decomposition
        % baseline correction within pop_newtimef is disabled because
        % ERD/ERS normalization is performed manually below
        [~,~,~,times,freqs,~,~,tfdata] = pop_newtimef( ...
            EEG, 1, ch, [-2500 7000], [3 10], ...
            'topovec', ch, ...
            'elocs', EEG.chanlocs, ...
            'chaninfo', EEG.chaninfo, ...
            'caption', EEG.chanlocs(ch).labels, ...
            'baseline', [NaN], ...
            'freqs', [5 35], ...
            'freqscale', 'log', ...
            'plotphase', 'off', ...
            'padratio', 1, ...
            'trialbase', 'off', ...
            'plotersp', 'off');

        % check whether time and frequency vectors are consistent across
        % all datasets and channels
        if ~exist('times_check','var')
            times_check = times;
            freqs_check = freqs;
        else
            if ~isequal(times, times_check)
                error('Mismatch in times vector at dataset %d, channel %d', s, ch);
            end
            if ~isequal(freqs, freqs_check)
                error('Mismatch in freqs vector at dataset %d, channel %d', s, ch);
            end
        end

        % identify time points belonging to the pre-trial baseline interval
        baseline_idx = times >= BL_ON & times <= BL_OFF;

        % calculate single-trial power from complex wavelet coefficients
        trial_power      = abs(tfdata).^2;                    % freq x time x trial

        % average power across trials
        trial_power_mean = mean(trial_power,3);               % freq x time

        % calculate one common baseline value per frequency by averaging
        % trial-averaged power across the baseline interval
        R                = mean(trial_power_mean(:,baseline_idx),2); % freq x 1

        % calculate ERD/ERS (%) for each trial relative to the common
        % trial-averaged baseline
        ERD_percent = (trial_power - R) ./ R * 100;           % freq x time x trial

        % average ERD/ERS across trials
        ERD_mean    = mean(ERD_percent,3);                    % freq x time

        % initialize channel x frequency x time array for current dataset
        if c == 1
            powspctrm = nan(numel(chan_idx), length(freqs), length(times));
        end

        % store time-frequency ERD/ERS data for current channel
        powspctrm(c,:,:) = ERD_mean;                          % chan x freq x time

        % clear channel-specific variables before processing the next channel
        clear tfdata ...
            trial_power trial_power_mean R ...
            ERD_percent ERD_mean ...
            baseline_idx

    end

    % store current dataset in the corresponding MI session cell array
    if contains(fname, 'MI1')

        idx = entry_MI1;

        MI1{idx}.subject   = subID;
        MI1{idx}.group     = 'mt';
        MI1{idx}.session   = 'MI1';
        MI1{idx}.label     = chanlabels;
        MI1{idx}.freq      = freqs_check;
        MI1{idx}.time      = times_check;
        MI1{idx}.powspctrm = powspctrm;
        MI1{idx}.dimord    = 'chan_freq_time';

        % increment MI1 cell array counter
        entry_MI1 = entry_MI1 + 1;

    elseif contains(fname, 'MI2')

        idx = entry_MI2;

        MI2{idx}.subject   = subID;
        MI2{idx}.group     = 'mt';
        MI2{idx}.session   = 'MI2';
        MI2{idx}.label     = chanlabels;
        MI2{idx}.freq      = freqs_check;
        MI2{idx}.time      = times_check;
        MI2{idx}.powspctrm = powspctrm;
        MI2{idx}.dimord    = 'chan_freq_time';

        % increment MI2 cell array counter
        entry_MI2 = entry_MI2 + 1;
    end

    % clear current dataset and close figures generated during processing
    clear EEG powspctrm
    close all force
end

%% CHECK DATA

% remove unused cells from preallocated output cell arrays
MI1 = MI1(~cellfun('isempty', MI1));
MI2 = MI2(~cellfun('isempty', MI2));

% verify equal numbers of MI1 and MI2 datasets
if length(MI1) ~= length(MI2)
    error('Different number of MI1 and MI2 datasets.');
end

% verify subject correspondence between MI1 and MI2
for i = 1:length(MI1)
    if ~strcmp(MI1{i}.subject, MI2{i}.subject)
        error('Subject mismatch: MI1{%d} = %s, MI2{%d} = %s', ...
              i, MI1{i}.subject, i, MI2{i}.subject);
    end
end

% verify channel correspondence between MI1 and MI2
if ~isequal(MI1{1}.label, MI2{1}.label)
    error('Channel labels differ between MI1 and MI2.');
end

% display basic information for final inspection
disp(length(MI1))
disp(length(MI2))
disp(size(MI1{1}.powspctrm))
disp(MI1{1}.subject)
disp(MI2{1}.subject)

%% SAVE DATA

% save time-frequency ERD/ERS data for subsequent permutation analysis
save(fullfile(PATHOUT, 'permu_data.mat'), 'MI1', 'MI2', '-v7.3');

% return to scripts folder
cd(fullfile(MAINPATH, 'scripts', filesep));

% end of script
