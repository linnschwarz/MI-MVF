%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana04_2_preprocessing.m
%
% This script performs the final rejection of artifactual EEG epochs based
% on the rejection information generated and stored during the previous
% preprocessing step and subsequent visual inspection.
%
% The different rejection criteria are combined into a single logical
% rejection vector. An epoch is rejected if it was flagged by joint
% probability, EMG-based movement detection, or manual visual inspection.
%
% The following steps are performed:
%           - Load the filtered and epoched EEG datasets from lis04_1
%           - Combine joint-probability, EMG-based, and manual rejection
%             flags into EEG.reject.rejfinal
%           - Store the indices of all epochs to be rejected
%           - Store information about previously rejected ICA components
%           - Reject all epochs flagged by at least one rejection criterion
%           - Save the resulting cleaned EEGLAB SET files
%
% Input:    - Preprocessed and epoched EEG datasets from lis04_1 containing:
%             EEG.reject.rejjp
%             EEG.reject.rejEMG
%             EEG.reject.rejmanual
%
% Output:   - EEGLAB SET files after final epoch rejection (_ep_ar_man)
%           - info.mat:
%             Information about rejected epochs and previously rejected
%             ICA components
%
% Adapted by Linn Schwarz 29/09/2025
% María Paula Villabona 06/06/2023
% Martin Bleichner 11/01/2018
% Maren Stropahl 25/09/2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DIRECTORIES

clear; close all;

% execute this script from within the 'scripts' folder
MAINPATH = fileparts(pwd);
PATHIN  = fullfile(MAINPATH,'data','lis04_1',filesep);      % path containing input data                  
PATHOUT = fullfile(MAINPATH, 'data','lis04_2',filesep);  % path for script output

% create output folder if it does not exist yet
if ~exist(PATHOUT)
    mkdir(PATHOUT);
end

% locate datasets
cd(PATHIN)
list=dir('*.set');  % reads all .set files in PATHIN
len=length(list);   % total number of datasets that will be evaluated
fname=cell(1,len);   % create a file name cell array

%% INITIALIZE EEGLAB

% start eeglab
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

%% REJECTION OF ARTIFACTUAL EPOCHS

% loop over datasets
for s=1:len

    % obtain dataset name and load preprocessed and epoched EEG data
    fname{s} = strrep(list(s).name, '_ep_ar.set', '');
    EEG = pop_loadset('filename', [fname{s}, '_ep_ar.set'], 'filepath',...
        PATHIN);

    % combine all rejection sources into one logical rejection vector;
    % an epoch is flagged if it was identified by joint probability,
    % EMG-based movement detection, or manual visual inspection
    EEG.reject.rejfinal = EEG.reject.rejjp | EEG.reject.rejEMG | EEG.reject.rejmanual;

    % store indices of epochs to be rejected based on joint probability,
    % EMG-based movement detection, and manual visual inspection
    rej_ep(s) = {find(EEG.reject.rejfinal == 1)};

    % store indices of ICA components that were previously rejected
    comps(s) = {EEG.badcomps};

    % reject all epochs flagged by at least one rejection criterion
    EEG = pop_rejepoch( EEG, EEG.reject.rejfinal ,0);

    % check dataset consistency, assign dataset name and save
    EEG = eeg_checkset(EEG);
    EEG.setname = [fname{s}, '_ep_ar_man'];
    EEG = pop_saveset(EEG, [EEG.setname, '.set'], PATHOUT);
    
end

% optional: save rejected epochs per subject and ICA components that were
% rejected 
save([PATHOUT 'info'], 'rej_ep','comps' )

eeglab redraw

% return to scripts folder
cd(fullfile(MAINPATH, 'scripts', filesep));

% end of script
