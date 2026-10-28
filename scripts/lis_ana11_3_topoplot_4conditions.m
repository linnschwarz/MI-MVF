%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana11_3_topoplot_4conditions.m
%
% This script creates grand-average topographic maps of mu-band ERD/ERS for
% the four group x session conditions based on the channel-wise values
% extracted in lis_ana11_extract_topo_muERD.m.
%
% The following steps are performed:
%           - Load the channel-wise mu-band ERD/ERS values
%           - Separate the data by group (MVF, sham) and session (MI1, MI2)
%           - Average the channel-wise values across participants within
%             each of the four group x session conditions
%           - Determine common symmetric color limits across conditions
%           - Create four grand-average topographic maps
%           - Highlight the sensorimotor electrodes of interest
%             (FC1, FC2, C3, C4)
%           - Save the resulting four-panel topographic figure
%
% Input:    - topo_muERD.mat:
%             Channel-wise mu-band ERD/ERS values (8-12 Hz, 500-2500 ms)
%             and corresponding dataset and channel-location information
%
% Output:   - grand_average_topoplots_4conditions.png:
%             Four-panel figure showing grand-average mu-band ERD/ERS
%             topographies for MVF MI1, MVF MI2, sham MI1, and sham MI2
%
% Linn Schwarz 19/04/2026
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

%% IDENTIFY GROUP X SESSION CONDITIONS

% identify datasets belonging to each group x session condition
idx_mt_MI1 = strcmp({topo_muERD.group},'mt') & strcmp({topo_muERD.session},'MI1');
idx_mt_MI2 = strcmp({topo_muERD.group},'mt') & strcmp({topo_muERD.session},'MI2');
idx_sh_MI1 = strcmp({topo_muERD.group},'sh') & strcmp({topo_muERD.session},'MI1');
idx_sh_MI2 = strcmp({topo_muERD.group},'sh') & strcmp({topo_muERD.session},'MI2');

%% COMPUTE CONDITION GRAND AVERAGES

% average channel-wise mu ERD/ERS values across participants separately
% for each group x session condition
GA_mt_MI1 = mean(vertcat(topo_muERD(idx_mt_MI1).muERD), 1, 'omitnan');
GA_mt_MI2 = mean(vertcat(topo_muERD(idx_mt_MI2).muERD), 1, 'omitnan');
GA_sh_MI1 = mean(vertcat(topo_muERD(idx_sh_MI1).muERD), 1, 'omitnan');
GA_sh_MI2 = mean(vertcat(topo_muERD(idx_sh_MI2).muERD), 1, 'omitnan');

% obtain channel locations for topographic visualization
chanlocs = topo_muERD(find(idx_mt_MI1,1)).chanlocs;

%% DEFINE ELECTRODES OF INTEREST

% identify sensorimotor electrodes of interest from channel labels
e_label = {'FC1','FC2','C3','C4'};
chanLabels = {chanlocs.labels};
[~, chanOI] = ismember(e_label, chanLabels);

%% DEFINE COMMON COLOR LIMITS

% combine grand-average values across all four conditions
allGA = [GA_mt_MI1; GA_mt_MI2; GA_sh_MI1; GA_sh_MI2];

% determine overall minimum and maximum
clim = [min(allGA(:)) max(allGA(:))];

% define symmetric color limits around zero for all topoplots
m = max(abs(clim));
clim = [-m m];

%% CREATE FOUR-CONDITION GRAND-AVERAGE TOPOPLOTS

% create 2 x 2 tiled layout
fig = figure('Position',[100 100 1000 800]);
t = tiledlayout(2,2,'TileSpacing','compact','Padding','compact');

% plot MVF group MI1
nexttile;
topoplot(GA_mt_MI1, chanlocs, ...
    'electrodes', 'on', ...
    'emarker2', {chanOI, 'o', 'r', 8, 1});
caxis(clim);
title('MVF Group MI1','FontSize', 14);

% plot MVF group MI2
nexttile;
topoplot(GA_mt_MI2, chanlocs, ...
    'electrodes', 'on', ...
    'emarker2', {chanOI, 'o', 'r', 8, 1});
caxis(clim);
title('MVF Group MI2','FontSize', 14);

% plot sham group MI1
nexttile;
topoplot(GA_sh_MI1, chanlocs, ...
    'electrodes', 'on', ...
    'emarker2', {chanOI, 'o', 'r', 8, 1});
caxis(clim);
title('Sham Group MI1','FontSize', 14);

% plot sham group MI2
nexttile;
topoplot(GA_sh_MI2, chanlocs, ...
    'electrodes', 'on', ...
    'emarker2', {chanOI, 'o', 'r', 8, 1});
caxis(clim);
title('Sham Group MI2','FontSize', 14);

% add shared colorbar
cb = colorbar;
cb.Layout.Tile = 'east';
cb.FontSize = 14;
ylabel(cb, 'Mu ERD/ERS [%]','FontSize', 14);

% add figure title
title(t, 'Grand-average Mu ERD/ERS topoplots (8–12 Hz, 500–2500 ms)');

%% SAVE FIGURE

% save four-condition grand-average topographic figure
fileName = 'grand_average_topoplots_4conditions.png';
saveas(fig, fullfile(PATHOUT, fileName));

% return to scripts folder
cd(fullfile(MAINPATH, 'scripts', filesep));

% end of script