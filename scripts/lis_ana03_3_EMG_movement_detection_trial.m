%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana03_3_EMG_movement_detection_trial.m
%
% This script identifies trials containing potential muscle activity based
% on the variability of the EMG signal. For each trial and EMG channel, a
% moving standard deviation (MSD) is calculated and compared with the
% standard deviation of the entire trial.
%
% A channel within a trial is flagged if the MSD exceeds 2.5 times the 
% corresponding trial standard deviation at any time point. A trial is 
% classified as a movement trial if at least one EMG channel is flagged.
%
% The following steps are performed:
%           - Load the preprocessed and epoched EMG datasets
%           - Process MI1 and MI2 recordings separately
%           - Calculate the moving standard deviation for each channel
%             and trial using a 250-sample window
%           - Calculate the standard deviation of the entire trial for
%             each channel
%           - Flag channel/trial combinations in which the moving standard
%             deviation exceeds 2.5 times the corresponding trial standard
%             deviation at any time point
%           - Flag a trial as containing potential movement if the
%             threshold is exceeded in at least one EMG channel
%           - Store movement-detection results in the EEGLAB dataset
%           - Save trial rejection information and the percentage of
%             flagged trials
%           - Save the resulting EEGLAB SET files
%
% Input:    - Preprocessed and epoched EMG datasets in EEGLAB SET format
%
% Output:   - EEGLAB SET files containing the movement-detection results
%           - EMG_bad_trials.mat:
%             Structure containing the flagged trials for each dataset
%           - movePerc_all.mat:
%             Percentage of flagged trials for each dataset
%
% Linn Schwarz 13/10/2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DIRECTORIES

clear; close all;

% execute this script from within the 'scripts' folder
MAINPATH = fileparts(pwd);
PATHIN  = fullfile(MAINPATH,'data','lis03_EMG','preprocessed',filesep);      % path containing input data
PATHOUT = fullfile(MAINPATH, 'data','lis03_EMG','movement_detec',filesep);  % path for script output

% create output folder if it does not exist yet
if ~exist(PATHOUT)
    mkdir(PATHOUT);
end

% locate datasets
cd(PATHIN)
list=dir('*.set');  % reads all .set files in PATHIN

%% PARAMETERS

window = 250;          % moving SD window length in samples
MSD_factor = 2.5;      % threshold relative to the SD of the entire trial

% motor imagery sessions
MI = {'MI1', 'MI2'};

%% INITIALIZE EEGLAB AND OUTPUT VARIABLES

% start EEGLAB
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% initialize output variables
bad_trials_EMG = struct();
movePerc_all = [];

%% EMG MOVEMENT DETECTION

% loop over motor imagery sessions
for m = 1:length(MI)    

    % select datasets belonging to the current MI session
    list_mi=list(contains({list.name}, MI{m}));
    len=length(list_mi);
    
    % initialize filename cell array for the current MI session
    fname=cell(1,len);

    % loop over datasets
    for s=1:len
        
        % obtain dataset name and load preprocessed, epoched data
        fname{s} = strrep(list_mi(s).name, '_epoched.set', '');
        EEG = pop_loadset('filename', [fname{s}, '_epoched.set'], 'filepath',...
            PATHIN);

        % obtain number of channels and trials
        [nChans, ~, nTrials] = size(EEG.data);

        % initialize channel-by-trial movement flag matrix, which will later indicate whether there was a movement detected for a certain trial of a certain channel 
        moveFlag = false(nChans, nTrials);              
        
        % loop over trials
        for t = 1:nTrials      
            
            % loop over EMG channels
            for ch = 1:nChans   

                % calculate moving SD for the current channel and trial
                mov_sd = movstd(EEG.data(ch,:,t), window, 0, 2);

                % calculate SD across the entire current trial
                trial_sd = std(EEG.data(ch,:,t), 0, 2);              

                % flag channel if the moving SD exceeds the threshold at
                % any time point within the trial
                if any(mov_sd > MSD_factor * trial_sd)
                    moveFlag(ch,t) = true;  
                end
            end
        end

    % flag trial if at least one EMG channel exceeds the threshold
    bad_trials = any(moveFlag,1);

    % calculate percentage of flagged trials in the current dataset
    movePerc = mean(bad_trials) * 100;

    % store movement-detection results in EEGLAB structure
    EEG.moveFlag = moveFlag;
    EEG.bad_trials = bad_trials;
    EEG.movePerc = movePerc;

    % store flagged trials separately for later combination with EEG
    % artifact rejection
    bad_trials_EMG.(fname{s}) = bad_trials;

    % store percentage of flagged trials
    movePerc_all(end+1) = movePerc;

    % assign dataset name and save
    EEG.setname = [fname{s}, '_movDetect'];
    pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', PATHOUT);
    end
end

% save movement-detection information
save(fullfile(PATHOUT,'EMG_bad_trials.mat'),'bad_trials_EMG');
save(fullfile(PATHOUT,'movePerc_all.mat'),'movePerc_all');

% return to scripts folder
cd(fullfile(MAINPATH, 'scripts', filesep));

% end of script
