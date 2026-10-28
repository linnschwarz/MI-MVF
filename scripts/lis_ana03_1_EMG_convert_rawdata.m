%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana03_1_EMG_convert_rawdata.m
%
% This script converts the raw recordings containing the EMG channels from
% .xdf format to EEGLAB .set files.
%
% The following steps are performed:
%           - Loop over all participants and .xdf recordings
%           - Exclude predefined participants
%           - Exclude recordings not used for the EMG analysis
%           - Load the BrainAmpSeries stream from each XDF file
%           - Save each recording as an EEGLAB SET file
%
% Input:    - Raw recordings in XDF format
%
% Output:   - EEGLAB SET files containing the raw recordings used for the
%             subsequent EMG preprocessing
%
% Note:     Channel locations are not assigned in this script because
%           spatial electrode coordinates are not required for the EMG
%           movement-detection analysis. The EMG channels are selected in
%           the subsequent preprocessing script 
%           (lis_ana03_2_EMG_preprocessing).
%
% Linn Schwarz 09/10/2025
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DIRECTORIES

clear; close all;

% execute this script from within the 'scripts' folder
MAINPATH = fileparts(pwd);
PATHIN  = fullfile(MAINPATH,'rawdata_xdf', filesep); % path containing rawdata
PATHOUT = fullfile(MAINPATH, 'rawdata_EMG', filesep);    % path for script output

% create output folder if it does not exist yet
if ~exist(PATHOUT)
    mkdir(PATHOUT);
end

%% PARAMETERS

% number of subjects
nsub = 42;

% excluded subjects
exsub = {'06','07'};

%% INITIALIZE EEGLAB

% start EEGLAB
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

%% LOADING .XDF FILES AND CONVERTING THEM TO EEGLAB .SET FILES

% loop over subjects
for s = 1:nsub

    % generate two-digit participant ID (01, 02, ..., 42)
    subjID = sprintf('%02d', s);

    % skip predefined excluded subjects
    if ismember(subjID, exsub)
        fprintf('Subject %s is skipped.\n', subjID);
        continue
    end

    % list all xdf. files of one participant
    xdfFiles = dir(fullfile(PATHIN, subjID, subjID, '*.xdf'));

    % loop over .xdf files of one subject
    for f = 1:length(xdfFiles)
        
        % name of file without ending
        [~, fname, ~] = fileparts(xdfFiles(f).name);

        % skip files containing "Int" in filename
        if contains(fname, 'Int')
            fprintf('Skipping file %s because it contains "Int".\n', fname);
            continue
        end

        % load BrainAmpSeries stream from .xdf file
        EEG = pop_loadxdf(fullfile(xdfFiles(f).folder, xdfFiles(f).name),'streamname', 'BrainAmpSeries', 'streamtype', 'EEG', 'exclude_markerstreams', {});
        
        % remove automatically generated comments and assign dataset name
        EEG.comments = '';
        EEG.setname = [fname];
        
        % save dataset as EEGLAB .set file
        pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', PATHOUT);
        
    end
end

% back into scripts folder
cd(fullfile(MAINPATH, 'scripts', filesep));

% end of script
