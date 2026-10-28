%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana11_4_topoplot_2groups.m
%
% This script creates grand-average topographic maps of mu-band ERD/ERS for
% the two experimental groups based on the channel-wise values extracted in
% lis_ana11_extract_topo_muERD.m. Values are averaged across MI1 and MI2
% within each group.
%
% The following steps are performed:
%           - Load the channel-wise mu-band ERD/ERS values
%           - Separate the data by group (MVF, sham)
%           - Average the channel-wise values across participants and
%             sessions within each group
%           - Determine common symmetric color limits across groups
%           - Create one grand-average topographic map per group
%           - Highlight the sensorimotor electrodes of interest
%             (FC1, FC2, C3, C4)
%           - Save the resulting two-panel topographic figure
%
% Input:    - topo_muERD.mat:
%             Channel-wise mu-band ERD/ERS values (8-12 Hz, 500-2500 ms)
%             and corresponding dataset and channel-location information
%
% Output:   - grand_average_topoplots_2groups.png:
%             Two-panel figure showing grand-average mu-band ERD/ERS
%             topographies for the MVF and sham groups averaged across
%             MI1 and MI2
%
% Linn Schwarz 22/07/2026
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

% load channel-wise mu ERD/ERS values generated in
% lis_ana11_extract_topo_muERD.m
cd(PATHIN)
load('topo_muERD.mat')

%% IDENTIFY GROUPS

% identify datasets belonging to each experimental group
idx_mt = strcmp({topo_muERD.group},'mt');
idx_sh = strcmp({topo_muERD.group},'sh');

%% COMPUTE GROUP GRAND AVERAGES

% average channel-wise mu ERD/ERS values across participants and sessions
% separately for each experimental group
GA_mt = mean(vertcat(topo_muERD(idx_mt).muERD), 1, 'omitnan');
GA_sh = mean(vertcat(topo_muERD(idx_sh).muERD), 1, 'omitnan');

% obtain channel locations for topographic visualization
chanlocs = topo_muERD(find(idx_mt,1)).chanlocs;

%% DEFINE ELECTRODES OF INTEREST

% identify sensorimotor electrodes of interest from channel labels
e_label = {'FC1','FC2','C3','C4'};
chanLabels = {chanlocs.labels};
[~, chanOI] = ismember(e_label, chanLabels);

%% DEFINE COMMON COLOR LIMITS

% combine grand-average values across both groups
allGA = [GA_mt; GA_sh];

% determine overall minimum and maximum
clim = [min(allGA(:)) max(allGA(:))];

% define symmetric color limits around zero for both topoplots
m = max(abs(clim));
clim = [-m m];

%% CREATE TWO-GROUP GRAND-AVERAGE TOPOPLOTS

% create 1 x 2 tiled layout
fig = figure('Position',[100 100 1000 800]);
t = tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

% plot MVF group
nexttile;
topoplot(GA_mt, chanlocs, ...
    'electrodes', 'on', ...
    'emarker2', {chanOI, 'o', 'r', 6, 1});
caxis(clim);
h = title('MVF Group','FontSize',19);
h.Units = 'normalized';
h.Position(2) = 1.12;

% plot sham group
nexttile;
topoplot(GA_sh, chanlocs, ...
    'electrodes', 'on', ...
    'emarker2', {chanOI, 'o', 'r', 6, 1});
caxis(clim);
h = title('Sham Group','FontSize',19);
h.Units = 'normalized';
h.Position(2) = 1.12;

% add shared colorbar
cb = colorbar;
cb.Layout.Tile = 'east';
cb.FontSize = 19;
ylabel(cb, 'Mu ERD/ERS [%]','FontSize', 19);

%% SAVE FIGURE

% save two-group grand-average topographic figure
fileName = 'grand_average_topoplots_2groups.png';
saveas(fig, fullfile(PATHOUT, fileName));

% return to scripts folder
cd(fullfile(MAINPATH, 'scripts', filesep));

% end of script