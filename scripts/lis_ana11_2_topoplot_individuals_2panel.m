%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana11_2_topoplot_individuals_2panel.m
%
% This script creates individual topographic maps of mu-band ERD/ERS for
% MI1 and MI2 based on the channel-wise values extracted in 
% lis_ana11_extract_topo_muERD.m.
%
% The following steps are performed:
%           - Load the channel-wise mu-band ERD/ERS values
%           - Determine common symmetric color limits across all datasets
%           - Identify the MI1 and MI2 data for each participant
%           - Create one two-panel topographic figure per participant
%           - Display MI1 and MI2 using identical color limits
%           - Add participant and group information to each figure
%           - Save the resulting individual topographic figures
%
% Input:    - topo_muERD.mat:
%             Channel-wise mu-band ERD/ERS values (8-12 Hz, 500-2500 ms)
%             and corresponding dataset and channel-location information
%
% Output:   - One two-panel topographic figure per participant:
%             MI1 (left) and MI2 (right)
%
% Linn Schwarz 24/03/2026
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DIRECTORIES

clear; close all;

% execute this script from within the 'scripts' folder
MAINPATH = fileparts(pwd);
PATHIN  = fullfile(MAINPATH,'data','lis11',filesep);        % channel-wise mu ERD/ERS data
PATHOUT = fullfile(MAINPATH,'data','lis11',filesep);        % path for figure output

% create output folder if it does not exist yet
if ~exist(PATHOUT,'dir')
    mkdir(PATHOUT);
end

%% LOAD DATA

% load channel-wise mu ERD/ERS values generated in lis_ana11_extract_topo_muERD.m
cd(PATHIN)
load('topo_muERD.mat')

%% DEFINE COMMON COLOR LIMITS

% combine channel-wise mu ERD/ERS values across all datasets
allVals = vertcat(topo_muERD.muERD);

% determine overall minimum and maximum
clim = [min(allVals(:)) max(allVals(:))];

% define symmetric color limits around zero for all topoplots
m = max(abs(clim));
clim = [-m m];

%% IDENTIFY PARTICIPANTS

% obtain unique participant IDs
subjects = unique({topo_muERD.subject});

%% CREATE INDIVIDUAL TWO-PANEL TOPOPLOTS

% loop over participants
for s = 1:numel(subjects)

    subID = subjects{s};

    % identify MI1 and MI2 entries for current participant
    idx_MI1 = strcmp({topo_muERD.subject}, subID) & strcmp({topo_muERD.session}, 'MI1');
    idx_MI2 = strcmp({topo_muERD.subject}, subID) & strcmp({topo_muERD.session}, 'MI2');

    % skip participant if one of the two sessions is missing
    if ~any(idx_MI1) || ~any(idx_MI2)
        warning('Missing session for subject %s', subID);
        continue
    end

    % extract channel-wise mu ERD/ERS values for both sessions
    data_MI1 = topo_muERD(idx_MI1).muERD;
    data_MI2 = topo_muERD(idx_MI2).muERD;

    % extract channel locations
    chanlocs = topo_muERD(idx_MI1).chanlocs;

    % determine group label
    group    = topo_muERD(idx_MI1).group;

    if strcmp(group,'mt')
        grp_label = 'MVF group';
    else
        grp_label = 'Sham group';
    end

    % create two-panel figure
    fig = figure('Position',[100 100 900 400]);
    t = tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

    % plot MI1 topography
    nexttile;
    topoplot(data_MI1, chanlocs, 'electrodes', 'on');
    caxis(clim);
    title('MI1');

    % plot MI2 topography
    nexttile;
    topoplot(data_MI2, chanlocs, 'electrodes', 'on');
    caxis(clim);
    title('MI2');

    % add shared colorbar
    cb = colorbar;
    cb.Layout.Tile = 'east';
    ylabel(cb, 'Mu ERD/ERS [%]');

    % add participant and group information
    title(t, sprintf('Subject %s | %s', subID, grp_label));

    % save individual two-panel topographic figure
    fileName = sprintf('%s_2panel_topoplot.png', subID);
    saveas(fig, fullfile(PATHOUT, fileName));

    % close current figure before processing the next participant
    close(fig);
end

% return to scripts folder
cd(fullfile(MAINPATH, 'scripts', filesep));

% end of script