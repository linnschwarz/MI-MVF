%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana13_2_calc_clusterbasedpermutation.m
%
% This script performs a cluster-based permutation analysis to test for
% changes in time-frequency ERD/ERS from MI1 to MI2 within the MVF group.
%
% The following steps are performed:
%           - Load the time-frequency ERD/ERS data generated in lis_ana13_1
%           - Exclude predefined participants (VP23 and VP36) because their
%             mean mu-band ERD values over the contralateral left
%             sensorimotor electrodes during MI1 were non-negative
%           - Convert EEGLAB channel-location information to FieldTrip format
%           - Define neighbouring EEG channels using triangulation
%           - Perform a dependent-samples cluster-based permutation test
%             comparing MI1 and MI2 across all EEG channels, frequencies
%             from 5 to 35 Hz, and all available time points
%           - Correct for multiple comparisons using cluster-based
%             statistics and 5000 Monte Carlo randomizations
%           - Store the statistical results and analysis configuration
%
% Input:    - permu_data.mat:
%             Cell arrays containing channel x frequency x time ERD/ERS data
%             for MI1 and MI2 in the MVF group
%           - One preprocessed EEGLAB dataset for channel-location information
%
% Output:   - stat_CBPT_MVF_MI1vsMI2_5000perm_minnbchan0.mat:
%             Results of the cluster-based permutation analysis together with
%             the channel-neighbour definition, analysis configuration, and
%             input data used for the statistical comparison
%
% Linn Schwarz 16/06/2026
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DIRECTORIES

clear all; close all;

% execute this script from within the 'scripts' folder
MAINPATH = fileparts(pwd);
PATHIN1  = fullfile(MAINPATH,'data','lis04_2',filesep);     % path containing preprocessed EEG data
PATHIN2  = fullfile(MAINPATH,'data','lis13',filesep);       % path containing time-frequency data
PATHFT   = fullfile(MAINPATH, 'fieldtrip-master');          % path containing FieldTrip
PATHOUT  = fullfile(MAINPATH,'data','lis13',filesep);       % path for script output

% check existence of FieldTrip directory
if ~exist(PATHFT, 'dir')
    error('FieldTrip directory not found: %s', PATHFT);
end

% create output folder if it does not exist yet
if ~exist(PATHOUT,'dir')
    mkdir(PATHOUT);
end

% start EEGLAB
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% add FieldTrip to MATLAB path and initialize toolbox
addpath(PATHFT)
ft_defaults

%% LOAD DATA

% load one preprocessed EEG dataset to obtain channel-location information
EEG = pop_loadset('filename','lis_mirror_02_mt_MI1_ep_ar_man.set','filepath',PATHIN1);

% load time-frequency ERD/ERS data
load(fullfile(PATHIN2, 'permu_data.mat'));

%% EXCLUDE PARTICIPANTS

% define participants excluded from the statistical analyses
exclude_subjects = {'23','36'}; 

% identify participants to retain
keep = true(1,length(MI1));

for i = 1:length(MI1)
    if ismember(MI1{i}.subject, exclude_subjects)
        keep(i) = false;
    end
end

% retain included participants only
MI1 = MI1(keep);
MI2 = MI2(keep);

%% DEFINE CHANNEL NEIGHBOURS

% convert EEGLAB channel-location information to FieldTrip format
tmp = eeglab2fieldtrip(EEG, 'chanloc');
elec = tmp.elec;

% verify correspondence of channel labels
if ~isequal(MI1{1}.label(:), elec.label(:))
    error('Channel labels in MI1 and elec do not match.');
end

% add electrode information required for neighbour definition
MI1{1}.elec = elec;

% define neighbouring channels using triangulation
cfg_neighb = [];
cfg_neighb.method = 'triangulation';
cfg_neighb.elec   = elec;

neighbours = ft_prepare_neighbours(cfg_neighb, MI1{1});

%% CLUSTER-BASED PERMUTATION TEST

% define data dimensions included in the analysis
cfg = [];
cfg.channel          = 'all';
cfg.latency          = 'all';
cfg.frequency        = [5 35];

% define cluster-based Monte Carlo permutation procedure
cfg.method           = 'montecarlo';
cfg.statistic        = 'ft_statfun_depsamplesT';
cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.05;
cfg.clusterstatistic = 'maxsum';
cfg.minnbchan        = 0;

% define two-sided statistical test
cfg.tail             = 0;
cfg.clustertail      = 0;
cfg.alpha            = 0.025;

% define number of Monte Carlo randomizations
cfg.numrandomization = 5000;

% provide channel-neighbour definition
cfg.neighbours       = neighbours;

% determine number of included participants
nSubj = length(MI1);

% construct design matrix for paired MI1 vs. MI2 comparison
design = zeros(2, 2*nSubj);
design(1,:) = [1:nSubj 1:nSubj];
design(2,:) = [ones(1,nSubj) 2*ones(1,nSubj)];

% specify subject and condition variables
cfg.design = design;
cfg.uvar   = 1;
cfg.ivar   = 2;

% perform cluster-based permutation analysis
stat = ft_freqstatistics(cfg, MI1{:}, MI2{:});

%% SAVE DATA

% save statistical results and analysis information
save(fullfile(PATHOUT,'stat_CBPT_MVF_MI1vsMI2_5000perm_minnbchan0.mat'), ...
     'stat', 'neighbours', 'cfg', 'MI1', 'MI2', '-v7.3')

% return to scripts folder
cd(fullfile(MAINPATH, 'scripts', filesep));

% end of script