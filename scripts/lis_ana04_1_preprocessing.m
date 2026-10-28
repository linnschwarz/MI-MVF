%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana04_1_preprocessing.m
%
% This script preprocesses the ICA-cleaned EEG data and identifies epochs
% containing potential artifacts. Artifact rejection is based on joint
% probability, while trials containing potential movement based on the EMG
% analysis are additionally flagged. No epochs are rejected in this script.
%
% The different rejection criteria are stored separately in the EEGLAB
% structure to allow their origin to be tracked. Epochs flagged by joint
% probability are stored in EEG.reject.rejjp, movement trials identified
% from the EMG are stored in EEG.reject.rejEMG, and
% EEG.reject.rejmanual is initialized for subsequent visual inspection.
%
% The following steps are performed:
%           - Load ICA-cleaned and interpolated EEG datasets
%           - Load EMG-based movement detection results from
%             lis_ana03_3_EMG_movement_detection_trial.m
%           - Apply low-pass and high-pass filtering
%           - Re-reference the EEG data to linked mastoids
%           - Remove event markers not required for epoching
%           - Epoch the EEG data around stimulus onset
%           - Identify potentially artifactual epochs based on joint
%             probability
%           - Store joint-probability flags in EEG.reject.rejjp
%           - Store EMG-based movement flags in EEG.reject.rejEMG
%           - Initialize EEG.reject.rejmanual for subsequent visual
%             inspection
%           - Store information about previously rejected ICA components
%           - Save the resulting EEGLAB SET files without rejecting epochs
%
% Input:    - ICA-cleaned and interpolated EEG datasets in EEGLAB SET format
%           - EMG_bad_trials.mat containing EMG-based movement flags
%
% Output:   - EEGLAB SET files containing filtered, re-referenced and
%             epoched EEG data as well as rejection information (_ep_ar)
%           - info.mat:
%             Information about epochs flagged by EEGLAB rejection
%             criteria and previously rejected ICA components
%
% Adapted by Linn Schwarz 29/09/2025
% Martin Bleichner 11/01/2018
% Maren Stropahl 25/09/2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DIRECTORIES

clear; close all;

% execute this script from within the 'scripts' folder
MAINPATH = fileparts(pwd);
PATHIN  = fullfile(MAINPATH,'data','lis02_2',filesep);                       % path containing input data  
PATH_EMG = fullfile(MAINPATH,'data','lis03_EMG','movement_detec',filesep);   % path containing EMG rejection information
PATHOUT = fullfile(MAINPATH, 'data','lis04_1',filesep);                      % path for script output

% create output folder if it does not exist yet
if ~exist(PATHOUT)
    mkdir(PATHOUT);
end

% locate datasets
cd(PATHIN)
list=dir('*.set');  % reads all .set files in PATHIN
list=list(~contains({list.name}, 'Int'));   % list contains just the .set files of MI1 and MI2 (not Int)
len=length(list);   % total number of datasets that will be evaluated
fname=cell(1,len);   % create a file name cell array


%% PARAMETERS
PRUNE = 4;                  % artifact rejection threshold in SD
EPOCH_ON = -2.5;            % epoch start [s]
EPOCH_OFF = 9;              % epoch end [s]
SRATE = 250;                % target sampling rate [Hz] (resampling currently disabled)
HP_erp = 1;                 % cut-off frequency high-pass filter [Hz]
LP_erp = 40;                % cut-off frequency low-pass filter [Hz]
HP_ord= 414;                % high-pass filter order depends on sampling rate; o = pop_firwsord('hamming', 250, 2); 
LP_ord= 84;                 % low-pass filter order depends on sampling rate; o = pop_firwsord('hamming', 250, (0.25*40));
ev = '40';                  % event marker for epoching

%% INITIALIZE EEGLAB AND LOAD EMG REJECTION INFORMATION

% start EEGLAB
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% load logical trial vectors containing trials flagged based on EMG
% movement detection
load(fullfile(PATH_EMG,'EMG_bad_trials.mat'),'bad_trials_EMG');

%% EEG PREPROCESSING AND ARTIFACT DETECTION

% loop over datasets
for s = 1:len

    % obtain dataset name and load ICA-cleaned and interpolated EEG data
    fname{s} = strrep(list(s).name, '_cleaned_interp.set', '');
    EEG = pop_loadset('filename', [fname{s}, '_cleaned_interp.set'], 'filepath',...
        PATHIN);

    % assigning the bad trials from EMG of the current dataset to bad_emg
    if isfield(bad_trials_EMG, fname{s})
        bad_emg = bad_trials_EMG.(fname{s}); % logical vector, length = nTrials
    else
        warning(['No EMG data for ' fname{s} ' found']);
        bad_emg = false(1, EEG.trials);
    end

    % apply low pass filter
    EEG = pop_firws(EEG, 'fcutoff', LP_erp, 'ftype', 'lowpass', 'wtype', ...
        'hamming', 'forder', LP_ord);
    % downsample data (not needed here, since data is collected with srate of 250 Hz)
    % EEG = pop_resample(EEG, SRATE);
    % apply high pass filter
    EEG = pop_firws(EEG, 'fcutoff', HP_erp, 'ftype', 'highpass', 'wtype', ...
        'hamming', 'forder', HP_ord);

    % re-reference to linked mastoids
    EEG = pop_reref(EEG, [31 32]);

    % find all event markers except the stimulus onset marker used for epoching
    c=1;
    idx = [];
    for e = 1 : length(EEG.event)
        if ~ strcmp(EEG.event(e).type,ev)
            idx(c) = e;
            c=c+1;
        end
    end

    % remove all event markers except stimulus onset
    EEG = pop_editeventvals(EEG,'delete',idx);
    EEG = eeg_checkset(EEG);
    
    % epoching
    EEG = pop_epoch(EEG, {ev}, [EPOCH_ON EPOCH_OFF], 'newname', EEG.setname,...
        'epochinfo', 'yes');
    
    % artifact detection based on joint probability
    % identify/reject artifacts with joint prob. > PRUNE (SD)
    % optional: store the indices of epoch that are going to be rejected
    % otherwise reject epochs immediately:
    % EEG = pop_jointprob(EEG, 1, [1:EEG.nbchan], PRUNE, PRUNE, 0, 1 , 0);
    EEG = pop_jointprob(EEG, 1, [1:EEG.nbchan], PRUNE, PRUNE, 0, 0 , 0);
    EEG = eeg_rejsuperpose( EEG, 1, 1, 1, 1, 1, 1, 1, 1);

    % store indices of epochs currently flagged by EEGLAB rejection criteria
    % (at this stage, these originate from joint probability)
    rej_ep(s) = {find(EEG.reject.rejglobal == 1)};

    % epochs are not rejected here; final rejection is performed in
    % lis_ana04_2_preprocessing.m
    % EEG = pop_rejepoch( EEG, EEG.reject.rejglobal ,0);

    % initialize logical vector for subsequent manual epoch screening
    rej_man = false(size(bad_emg));             

    % store EMG-based movement flags and initialize manual rejection flags
    % separately from joint-probability rejection information
    EEG.reject.rejEMG    = bad_emg;
    EEG.reject.rejmanual = rej_man;

    % EEG.reject.rejjp contains epochs flagged by joint probability
    % EEG.reject.rejEMG contains trials flagged by EMG movement detection
    % EEG.reject.rejmanual will contain epochs flagged during visual inspection

    % store indices of ICA components that were previously rejected
    comps(s) = {EEG.badcomps};
    
    % check dataset consistency, assign dataset name and save
    EEG = eeg_checkset(EEG);
    EEG.setname = [fname{s}, '_ep_ar'];
    EEG = pop_saveset(EEG, [EEG.setname, '.set'], PATHOUT);
    
end

% save information about flagged epochs and previously rejected ICA components
save([PATHOUT 'info'], 'rej_ep','comps' )

eeglab redraw

% return to scripts folder
cd(fullfile(MAINPATH, 'scripts', filesep));

% end of script

