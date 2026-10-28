%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana07_2_pre_statcorrelation.m
%
% This script prepares subject-level mu-band ERD/ERS measures and behavioral
% measures for subsequent correlation analyses. ERD/ERS values are extracted
% from the wide-format time-frequency data generated in Script 5 and combined
% with behavioral measures from an external Excel file.
%
% The following steps are performed:
%           - Load wide-format ERD/ERS time-frequency data
%           - Load behavioral measures for correlation analyses
%           - Identify the predefined mu-band (8-12 Hz) and motor imagery
%             time window (500-2500 ms)
%           - Average ERD/ERS across the selected frequency and time window
%             for each electrode and MI session
%           - Calculate left- and right-hemisphere ERD/ERS averages for
%             MI1 and MI2
%           - Calculate left-minus-right hemisphere difference scores
%           - Calculate the change in left-hemisphere ERD/ERS from MI1 to MI2
%           - Calculate the change in ERD/ERS lateralization from MI1 to MI2
%           - Add behavioral measures for each participant
%           - Assemble all subject-level measures in a structure for
%             subsequent correlation analyses
%           - Export the correlation input data in MATLAB and CSV format
%
% Input:    - Wide-format ERD/ERS time-frequency data (.mat)
%           - Time vector used for the time-frequency analysis (.mat)
%           - Frequency vector used for the time-frequency analysis (.mat)
%           - Behavioral measures ('behav_measures_for_correlation.xlsx')
%
% Note:     The file 'behav_measures_for_correlation.xlsx' must be manually
%           copied into the Script 7 output folder (PATHOUT) before running
%           this script. The participant order in the behavioral data file
%           must correspond to the participant order in
%           time_frequency_data_wf.
%
% Output:   - Subject-level correlation input data (.mat)
%           - Subject-level correlation input data (.csv)
%
% Linn Schwarz 10/06/2026
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DIRECTORIES

clear; close all;

% execute this script from within the 'scripts' folder
MAINPATH = fileparts(pwd);
PATHIN  = fullfile(MAINPATH,'data','lis05',filesep);      % path containing input data                   
PATHOUT = fullfile(MAINPATH, 'data','lis07_8-12Hz_500-2500ms_LI',filesep);  % path for script output

% create output folder if it does not exist yet
if ~exist(PATHOUT)
    mkdir(PATHOUT);
end

% load wide-format ERD/ERS data and common time/frequency vectors
load(fullfile(PATHIN, 'time_frequency_data_struct_wf.mat'));
load(fullfile(PATHIN, 'frequencies.mat'));
load(fullfile(PATHIN, 'times.mat'));

% load behavioral measures
% NOTE: 'behav_measures_for_correlation.xlsx' must be manually copied into
% PATHOUT before running this script
behav_data = readtable(fullfile(PATHOUT, ...
    'behav_measures_for_correlation.xlsx'));

%% PARAMETERS

% frequency window of interest [Hz]
FREQ_ON  = 8;
FREQ_OFF = 12;

% time window of interest [ms]
TIME_ON  = 500;
TIME_OFF = 2500;

% define electrode/session fields
e_label = {'FC1_MI1','FC2_MI1','C3_MI1','C4_MI1', ...
           'FC1_MI2','FC2_MI2','C3_MI2','C4_MI2'};

%% PREPARE CORRELATION INPUT

% initialize output structure
stat_input = struct([]);

% identify indices corresponding to frequency window of interest
freqs_on_idx = find(freqs_check >= FREQ_ON, 1, 'first');  
freqs_off_idx = find(freqs_check <= FREQ_OFF, 1, 'last'); 

% identify indices corresponding to time window of interest
times_on_idx = find(times_check >= TIME_ON, 1, 'first');
times_off_idx = find(times_check <= TIME_OFF, 1, 'last');

% loop over participants
for s = 1:length(time_frequency_data_wf)

    % store participant and group information
    stat_input(s).subject       = time_frequency_data_wf(s).subject;
    stat_input(s).group         = time_frequency_data_wf(s).group;

    % loop over electrodes and MI sessions
    for electrodeidx = 1:length(e_label)

        % get current electrode/session field
        fld = e_label{electrodeidx};   % e.g. 'FC1_MI1'

        % extract ERD/ERS values within the predefined frequency and
        % time window
        data_oi = time_frequency_data_wf(s).(fld)(freqs_on_idx:freqs_off_idx,times_on_idx:times_off_idx);

        % calculate mean ERD/ERS across frequencies and time points
        avdata = mean(data_oi(:));

        % store mean ERD/ERS value for current electrode and MI session
        stat_input(s).(fld)     = avdata;
    end

    % calculate mean ERD/ERS over left-hemisphere electrodes
    stat_input(s).LHMI1                   = mean([stat_input(s).FC1_MI1 stat_input(s).C3_MI1]);
    stat_input(s).LHMI2                   = mean([stat_input(s).FC1_MI2 stat_input(s).C3_MI2]);

    % calculate mean ERD/ERS over right-hemisphere electrodes
    stat_input(s).RHMI1                   = mean([stat_input(s).FC2_MI1 stat_input(s).C4_MI1]);
    stat_input(s).RHMI2                   = mean([stat_input(s).FC2_MI2 stat_input(s).C4_MI2]);

    % calculate hemisphere-wise left-minus-right difference scores
    stat_input(s).LHminusRHMI1            = stat_input(s).LHMI1 - stat_input(s).RHMI1;
    stat_input(s).LHminusRHMI2            = stat_input(s).LHMI2 - stat_input(s).RHMI2;
    
    % calculate change in left-hemisphere ERD/ERS from MI1 to MI2
    stat_input(s).LHMI2minusLHMI1         = stat_input(s).LHMI2 - stat_input(s).LHMI1;

    % calculate change in ERD/ERS lateralization from MI1 to MI2
    stat_input(s).latERDMI2minusMI1       = stat_input(s).LHminusRHMI2 - stat_input(s).LHminusRHMI1;

    % add behavioral measures
    stat_input(s).Vividness_of_illusion   = behav_data.Vividness_of_illusion(s);
    stat_input(s).Increasing_realism      = behav_data.Increasing_realism(s);
    stat_input(s).Mirror_arm_not_mine     = behav_data.Mirror_arm_not_mine(s);
    stat_input(s).Only_left_arm_movement  = behav_data.Only_left_arm_movement(s);
    stat_input(s).Only_right_arm_movement = behav_data.Only_right_arm_movement(s);
    stat_input(s).Both_arms_movement      = behav_data.Both_arms_movement(s);
    stat_input(s).Session_challenging     = behav_data.Session_challenging(s);
    stat_input(s).Avg_attention           = behav_data.Avg_attention(s);
    stat_input(s).Avg_tiredness           = behav_data.Avg_tiredness(s);
    stat_input(s).KVIQ_kin                = behav_data.KVIQ_kin(s);
    stat_input(s).MI_Score_avg            = behav_data.MI_Score_avg(s);
    stat_input(s).MI_Score_MI1            = behav_data.MI_Score_MI1(s);
    stat_input(s).MI_Score_MI2            = behav_data.MI_Score_MI2(s);
    stat_input(s).MI_Score_MI2minusMI1    = behav_data.MI_Score_MI2minusMI1(s);
   
end

%% SAVE CORRELATION INPUT

% save correlation input structure as MATLAB file
fullFilePath = fullfile(PATHOUT, 'stat_input_correlation.mat');
save(fullFilePath, 'stat_input', '-v7.3');

% convert correlation input structure to table
T = struct2table(stat_input);

% save correlation input table as CSV file
writetable(T, fullfile(PATHOUT, 'stat_input_correlation.csv'));

% return to scripts folder
cd(fullfile(MAINPATH, 'scripts', filesep));

% end of script

