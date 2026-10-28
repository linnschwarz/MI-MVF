%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana00_convert_rawdata.m
%
% This script converts the raw EEG recordings from .xdf format to EEGLAB .set
% files and assigns the digitized electrode coordinates corresponding to the
% posteriorly shifted cap configuration used during data acquisition.
%
% The following steps are performed:
%           - Loop over all participants and .xdf recordings
%           - Exclude predefined participants
%           - Load the EEG stream from each XDF file
%           - Load the averaged and symmetrized electrode coordinates
%             obtained from the digitized shifted cap configuration
%           - Assign the digitized channel locations to the EEG dataset
%           - Recompute additional EEGLAB coordinate representations from
%             the Cartesian XYZ coordinates
%           - Save each recording as an EEGLAB SET file
%
% Input:    - Raw EEG recordings in XDF format
%           - symmetrized_32ch_positions.elc
%             Averaged and symmetrized electrode coordinates representing
%             the posteriorly shifted cap configuration used during data
%             acquisition
%
% Output:   - EEGLAB SET files with updated channel locations
%
% Note:     Channel labels retain the original channel naming of the EEG cap.
%           Their XYZ coordinates represent the digitized electrode positions
%           of the posteriorly shifted cap and therefore do not necessarily
%           correspond to the anatomical locations implied by their labels.
%
% Adapted by Linn Schwarz 16/03/2026
% Martin Bleichner 11/01/2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DIRECTORIES

clear all; close all;

% execute this script from within the 'scripts' folder 
MAINPATH = fileparts(pwd);
PATHIN  = fullfile(MAINPATH,'rawdata_xdf', filesep); % path containing rawdata                   
PATHOUT = fullfile(MAINPATH, 'rawdata_digitized', filesep);    % path for script output

% create output folder if it does not exist yet
if ~exist(PATHOUT)
    mkdir(PATHOUT);
end

% Averaged and symmetrized electrode coordinates representing the
% posteriorly shifted cap configuration used during data acquisition
chan_file = fullfile(MAINPATH,'electrodeposition_digitizer','symmetrized_32ch_positions.elc');

%% PARAMETERS

% number of subjects
nsub = 42;

% excluded subjects
exsub = {'06','07'};

%% INITIALIZE EEGLAB

% start EEGLAB
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

%% LOAD AND CONVERT RAW EEG DATA, ASSIGN DIGITIZED CHANNEL LOCATIONS, SAVE DATASET

% loop over subjects
for s = 1:nsub

    % generate two-digit participant ID (01, 02, ..., 42)
    subjID = sprintf('%02d', s); % 01, 02, ..., 42

    % skip subject if it's number is in variable exSub
    if ismember(subjID, exsub)
        fprintf('Subject %s is skipped.\n', subjID);
        continue
    end

    % list all xdf. files of one participant
    xdfFiles = dir(fullfile(PATHIN, subjID, subjID, '*.xdf'));

    % loop over .xdf files of one subject
    for f = 1:length(xdfFiles)
        
        % name of file witout ending
        [~, fname, ~] = fileparts(xdfFiles(f).name);
        
        % load EEG stream from .xdf file
        EEG = pop_loadxdf(fullfile(xdfFiles(f).folder, xdfFiles(f).name),'streamname', 'EEG', 'streamtype', 'EEG', 'exclude_markerstreams', {});
        
        % load averaged and symmetrized XYZ coordinates of the shifted cap
        % configuration and assign them to the EEG channels
        EEG = pop_chanedit(EEG, 'load', {chan_file 'filetype' 'autodetect'});

        % recompute additional EEGLAB coordinate representations
        % (e.g., spherical and polar coordinates) from Cartesian XYZ
        EEG = pop_chanedit(EEG, 'eval', 'chans = convertlocs(chans, ''cart2all'');');

        % remove automatically generated comments and assign dataset name
        EEG.comments = '';
        EEG.setname = [fname];
        
        % save .set 
        pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', PATHOUT);
        
    end
end

% return to scripts folder
cd(fullfile(MAINPATH, 'scripts', filesep));

% end of script


