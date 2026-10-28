%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana11_extract_topo_muERD.m
%
% This script calculates channel-wise mu-band ERD/ERS values for subsequent
% topographic visualization.
%
% The following steps are performed:
%           - Load all preprocessed MI datasets
%           - Exclude predefined participants (VP23 and VP36) because their 
%             mean mu-band ERD values over the contralateral left
%             sensorimotor electrodes during MI1 were non-negative
%           - Perform time-frequency decomposition for all EEG channels
%             using EEGLAB's pop_newtimef
%           - Calculate single-trial power from complex wavelet coefficients
%           - Calculate a trial-averaged baseline for each frequency
%             within the predefined baseline interval (-1000 to -500 ms)
%           - Normalize single-trial power relative to the common baseline
%             to obtain ERD/ERS in percent
%           - Average ERD/ERS across trials
%           - Extract one mean mu-band ERD/ERS value per channel within the
%             predefined frequency (8-12 Hz) and time (500-2500 ms) window
%           - Store the channel-wise values together with subject, group,
%             MI session, and channel-location information
%
% Input:    - Preprocessed MI datasets in EEGLAB SET format
%
% Output:   - topo_muERD.mat:
%             Channel-wise mu-band ERD/ERS values and corresponding dataset
%             and channel-location information for topographic visualization
%
% Linn Schwarz 24/03/2026
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DIRECTORIES 

clear; close all;

% execute this script from within the 'scripts' folder
MAINPATH = fileparts(pwd);
PATHIN  = fullfile(MAINPATH,'data','lis04_2',filesep);      % path containing input data
PATHOUT = fullfile(MAINPATH,'data','lis11',filesep);        % path for script output

% create output folder if it does not exist yet
if ~exist(PATHOUT,'dir')
    mkdir(PATHOUT);
end

% locate preprocessed datasets
cd(PATHIN)
list = dir('*.set');

% exclude predefined participants
excludeSubjects = {'23', '36'};
keep = true(size(list));

for i = 1:numel(list)

    % extract subject ID from filename
    fname = strrep(list(i).name, '_ep_ar_man.set', '');
    sub = strrep(fname, 'lis_mirror_', '');
    subID = extractBefore(sub, '_');

    % mark excluded participants for removal
    if ismember(subID, excludeSubjects)
        keep(i) = false;
    end
end

% retain datasets from included participants only
list = list(keep);
len = length(list);

% start EEGLAB
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

%% PARAMETERS

% define baseline interval
BL_ON  = -1000;     % baseline onset [ms]
BL_OFF = -500;      % baseline offset [ms]

% define mu frequency range
MU_ON  = 8;         % lower frequency limit [Hz]
MU_OFF = 12;        % upper frequency limit [Hz]

% define analysis time window
T_ON   = 500;       % analysis window onset [ms]
T_OFF  = 2500;      % analysis window offset [ms]

%% CALCULATE CHANNEL-WISE MU ERD/ERS

% initialize output structure
topo_muERD = struct([]);

% initialize structure counter
entry = 1;

% loop over all included preprocessed datasets
for s = 1:len

    % load dataset
    fname = strrep(list(s).name, '_ep_ar_man.set', '');
    EEG = pop_loadset('filename', [fname '_ep_ar_man.set'], 'filepath', PATHIN);

    % extract subject ID from filename
    sub = strrep(fname, 'lis_mirror_', '');
    subID = extractBefore(sub, '_');

    % determine experimental group from filename
    if contains(fname, 'mt')
        cond_label = 'mt';
    elseif contains(fname, 'sh')
        cond_label = 'sh';
    else
        error('Could not determine group for %s', fname);
    end

    % determine MI session from filename
    if contains(fname, 'MI1')
        session_label = 'MI1';
    elseif contains(fname, 'MI2')
        session_label = 'MI2';
    else
        error('Could not determine session for %s', fname);
    end

    % include all EEG channels for topographic visualization
    chan_idx = 1:EEG.nbchan;

    % store dataset and channel-location information
    topo_muERD(entry).subject  = subID;
    topo_muERD(entry).group    = cond_label;
    topo_muERD(entry).session  = session_label;
    topo_muERD(entry).chanlocs = EEG.chanlocs(chan_idx);

    % initialize vector for channel-wise mu ERD/ERS values
    muERD_vec = nan(1, numel(chan_idx));

    % loop over all EEG channels
    for c = 1:numel(chan_idx)

        ch = chan_idx(c);

        % perform time-frequency decomposition
        % baseline correction within pop_newtimef is disabled because
        % ERD/ERS normalization is performed manually below
        [~,~,~,times,freqs,~,~,tfdata] = pop_newtimef( ...
            EEG, 1, ch, [-2500 4000], [3 10], ...
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

        % identify frequencies belonging to the mu band
        mu_idx       = freqs >= MU_ON & freqs <= MU_OFF;

        % identify time points belonging to the analysis window
        time_idx     = times >= T_ON & times <= T_OFF;

        % calculate single-trial power from complex wavelet coefficients
        trial_power      = abs(tfdata).^2;                   % freq x time x trial

        % average power across trials
        trial_power_mean = mean(trial_power,3);              % freq x time

        % calculate one common baseline value per frequency by averaging
        % trial-averaged power across the baseline interval
        R = mean(trial_power_mean(:,baseline_idx),2);        % freq x 1

        % calculate ERD/ERS (%) for each trial relative to the common
        % trial-averaged baseline
        ERD_percent = (trial_power - R) ./ R * 100;          % freq x time x trial

        % average ERD/ERS across trials
        ERD_mean    = mean(ERD_percent,3);                   % freq x time

        % average ERD/ERS across the predefined mu frequency range and
        % analysis time window to obtain one value per channel
        muERD_vec(c) = mean(ERD_mean(mu_idx,time_idx), 'all');

        % clear channel-specific variables before processing the next channel
        clear times freqs tfdata ...
            trial_power trial_power_mean R ERD_percent ERD_mean ...
            baseline_idx mu_idx time_idx
    end

    % store channel-wise mu ERD/ERS values for current dataset
    topo_muERD(entry).muERD = muERD_vec;

    % clear current dataset and close figures generated during processing
    clear EEG
    close all force

    % increment structure counter
    entry = entry + 1;
end

%% SAVE DATA

% save channel-wise mu ERD/ERS values and common time/frequency vectors
save(fullfile(PATHOUT, 'topo_muERD.mat'), 'topo_muERD', 'times_check', 'freqs_check', '-v7.3');

% return to scripts folder
cd(fullfile(MAINPATH, 'scripts', filesep));

% end of script
