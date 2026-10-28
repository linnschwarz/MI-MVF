%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana07_1_pre_stat.m
%
% This script prepares subject-level mu-band ERD/ERS measures for
% statistical analysis. ERD/ERS values are extracted from the wide-format
% time-frequency data generated in Script 5.
%
% The following steps are performed:
%           - Load wide-format ERD/ERS time-frequency data
%           - Identify the predefined mu-band (8-12 Hz) and motor imagery
%             time window (500-2500 ms)
%           - Average ERD/ERS across the selected frequency and time window
%             for each electrode and MI session
%           - Calculate left- and right-hemisphere ERD/ERS averages for
%             MI1 and MI2
%           - Calculate left-minus-right hemisphere difference scores
%           - Calculate electrode-pair difference scores for FC1/FC2 and
%             C3/C4
%           - Calculate normalized lateralization indices based on the
%             hemisphere averages and separately for FC1/FC2 and C3/C4
%           - Assemble all subject-level measures in a structure for
%             subsequent statistical analysis
%           - Export the statistical input data in MATLAB and CSV format
%
% Input:    - time_frequency_data_struct_wf.mat:
%             Wide-format ERD/ERS time-frequency data
%           - times.mat:
%             Time vector used for the time-frequency analysis
%           - frequencies.mat:
%             Frequency vector used for the time-frequency analysis
%
% Output:   - Subject-level statistical input data (.mat)
%           - Subject-level statistical input data (.csv)
%
% Linn Schwarz 11/11/2025
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

%% PREPARE STATISTICAL INPUT 

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
    stat_input(s).LHMI1            = mean([stat_input(s).FC1_MI1 stat_input(s).C3_MI1]);
    stat_input(s).LHMI2            = mean([stat_input(s).FC1_MI2 stat_input(s).C3_MI2]);

    % calculate mean ERD/ERS over right-hemisphere electrodes
    stat_input(s).RHMI1            = mean([stat_input(s).FC2_MI1 stat_input(s).C4_MI1]);
    stat_input(s).RHMI2            = mean([stat_input(s).FC2_MI2 stat_input(s).C4_MI2]);

    % calculate hemisphere-wise left-minus-right difference scores
    stat_input(s).LHminusRHMI1     = stat_input(s).LHMI1 - stat_input(s).RHMI1;
    stat_input(s).LHminusRHMI2     = stat_input(s).LHMI2 - stat_input(s).RHMI2;

    % calculate left-minus-right difference scores for FC1/FC2
    stat_input(s).FC1minusFC2MI1   = stat_input(s).FC1_MI1 - stat_input(s).FC2_MI1;
    stat_input(s).FC1minusFC2MI2   = stat_input(s).FC1_MI2 - stat_input(s).FC2_MI2;

    % calculate left-minus-right difference scores for C3/C4
    stat_input(s).C3minusC4MI1     = stat_input(s).C3_MI1 - stat_input(s).C4_MI1;
    stat_input(s).C3minusC4MI2     = stat_input(s).C3_MI2 - stat_input(s).C4_MI2;

    % calculate general lateralization index based on hemisphere-wise
    % ERD/ERS averages: (LH - RH) / (LH + RH)
    stat_input(s).LIgenMI1         = (stat_input(s).LHMI1 - stat_input(s).RHMI1)/(stat_input(s).LHMI1 + stat_input(s).RHMI1);
    stat_input(s).LIgenMI2         = (stat_input(s).LHMI2 - stat_input(s).RHMI2)/(stat_input(s).LHMI2 + stat_input(s).RHMI2);

    % calculate lateralization index for FC1/FC2
    stat_input(s).LIcenMI1        = (stat_input(s).FC1_MI1 - stat_input(s).FC2_MI1)/(stat_input(s).FC1_MI1 + stat_input(s).FC2_MI1);
    stat_input(s).LIcenMI2        = (stat_input(s).FC1_MI2 - stat_input(s).FC2_MI2)/(stat_input(s).FC1_MI2 + stat_input(s).FC2_MI2);

    % calculate lateralization index for C3/C4
    stat_input(s).LIpcenMI1         = (stat_input(s).C3_MI1 - stat_input(s).C4_MI1)/(stat_input(s).C3_MI1 + stat_input(s).C4_MI1);
    stat_input(s).LIpcenMI2         = (stat_input(s).C3_MI2 - stat_input(s).C4_MI2)/(stat_input(s).C3_MI2 + stat_input(s).C4_MI2);

end

%% SAVE STATISTICAL INPUT

% save statistical input structure as MATLAB file
fullFilePath = fullfile(PATHOUT, 'stat_input.mat');
save(fullFilePath, 'stat_input', '-v7.3');

% convert statistical input structure to table
T = struct2table(stat_input);

% save statistical input table as CSV file
writetable(T, fullfile(PATHOUT, 'stat_input.csv'));

% return to scripts folder
cd(fullfile(MAINPATH, 'scripts', filesep));

% end of script