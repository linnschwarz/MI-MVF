%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana06_3_tf_map_2panel_group.m
%
% This script visualizes group-level time-frequency ERD/ERS patterns
% based on the sensorimotor average across FC1, FC2, C3, and C4 and
% averaged across motor imagery sessions (MI1 and MI2).
%
% The sensorimotor grand-average maps generated in lis_ana06_1 are averaged
% across MI1 and MI2 separately for the mirror visual feedback (MVF) and
% sham groups. The resulting group-level time-frequency maps are displayed
% side by side to allow direct visual comparison between groups.
%
% Figure layout:
%           Panel 1 - MVF group, averaged across MI1 and MI2
%           Panel 2 - Sham group, averaged across MI1 and MI2
%
% The following steps are performed:
%           - Load the four group x session grand-average ERD/ERS matrices
%             generated in lis_ana06_1
%           - Load the corresponding time and frequency vectors
%           - Extract the sensorimotor average (FC1, FC2, C3, C4) from each
%             group x session grand-average matrix
%           - Average the sensorimotor maps across MI1 and MI2 separately
%             for the MVF and sham groups
%           - Display the resulting group-level maps in a 1 x 2 tiled
%             layout
%           - Apply identical time, frequency, and color-axis limits to
%             both panels
%           - Mark motor imagery onset and offset at 0 and 6000 ms
%           - Add shared frequency labeling and a shared colorbar
%           - Save the resulting two-panel figure
%
% Input:    - MI1_mt_GA.mat
%           - MI2_mt_GA.mat
%           - MI1_sh_GA.mat
%           - MI2_sh_GA.mat
%           - times.mat:
%             Time vector (times_check)
%           - frequencies.mat:
%             Frequency vector (freqs_check)
%
% Output:   - grand_average_2panel_tf_map_group.png:
%             Two-panel figure showing the sensorimotor grand-average
%             time-frequency ERD/ERS maps for the MVF and sham groups,
%             averaged across MI1 and MI2
%
% Linn Schwarz 01/07/2026
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DIRECTORIES

clear; close all; clc;

% execute this script from within the 'scripts' folder
MAINPATH = fileparts(pwd);
PATHIN  = fullfile(MAINPATH,'data','lis06',filesep);        % grand-average data
PATHIN2 = fullfile(MAINPATH,'data','lis05',filesep);        % time and frequency vectors
PATHOUT = fullfile(MAINPATH,'data','lis06',filesep);        % path for figure output

%% LOAD DATA

% load grand-average ERD/ERS matrices generated in lis_ana06_1
cd(PATHIN)
load('MI1_mt_GA.mat')
load('MI2_mt_GA.mat')
load('MI1_sh_GA.mat')
load('MI2_sh_GA.mat')

% load corresponding time and frequency vectors
cd(PATHIN2)
load('times.mat')        % times_check
load('frequencies.mat')  % freqs_check

%% COMPUTE GROUP-LEVEL SENSORIMOTOR GRAND AVERAGES

% extract the sensorimotor average (5th matrix dimension) from MI1 and MI2
% and average across sessions separately for the MVF group
mt_GA_prep(:,:,1) = MI1_mt_GA(:,:,5);
mt_GA_prep(:,:,2) = MI2_mt_GA(:,:,5);
mt_GA = mean(mt_GA_prep,3);

% extract the sensorimotor average from MI1 and MI2 and average across
% sessions separately for the sham group
sh_GA_prep(:,:,1) = MI1_sh_GA(:,:,5);
sh_GA_prep(:,:,2) = MI2_sh_GA(:,:,5);
sh_GA = mean(sh_GA_prep,3);

%% FIGURE SETTINGS

% define figure dimensions
figW = 2150;  % width in pixels
figH = 850;   % height in pixels

% arrange group-level grand averages according to figure panels
grandaverages = {mt_GA, sh_GA};

% define group labels
colLabels = {'MVF Group', ...
             'Sham Group'};

% define common axis limits and ticks for both panels
xlims = [times_check(1) times_check(end)];
ylims = [5 35];
xt = -2000:1000:8000;
yt = 5:5:35;

% define boundaries of the analysis window
% frequency range: 8-12 Hz; time range: 500-2500 ms
xValue  = 500;
xValue2 = 2500;
yValue  = 8;
yValue2 = 12;
xRange  = [500 2500];
yRange  = [8 12];

%% CREATE TWO-PANEL GROUP-LEVEL FIGURE

% create 1 x 2 tiled layout:
% panel 1 = MVF group; panel 2 = sham group
fig = figure('Position',[100 100 figW figH], 'Color','w');
t = tiledlayout(1,2,'TileSpacing','compact','Padding','loose');

% loop over groups
for p = 1:2

    % select group-level grand-average matrix
    currentGA = grandaverages{p};

    ax = nexttile;
    hold(ax,'on');

    % plot group-level time-frequency ERD/ERS representation
    imagesc(ax,times_check, freqs_check, currentGA);
    axis(ax,'xy');
    colormap(ax,'jet');
    caxis(ax,[-65 65]);

    % apply identical axis limits and ticks to both panels
    xlim(ax,xlims);
    ylim(ax,ylims);
    xticks(ax,xt);
    yticks(ax,yt);
    set(ax, 'TickDir','out', 'Layer','top', 'FontSize',31)

    % show frequency tick labels only in the left panel
    if p > 1
        yticklabels(ax,[]);
    end

    % add time-axis label to each panel; shared frequency label is added below
    xlabel(ax,'Time [ms]','FontSize', 35);
    ylabel(ax,'');

%     % optional: add group titles above individual panels
%     title(ax, colLabels{p}, 'FontSize', 14, 'FontWeight', 'bold', ...
%         'Units','normalized', 'Position',[0.5 1.02 0]);


    % mark motor imagery onset (0 ms) and offset (6000 ms)
    xline(ax, 0, '--k', 'LineWidth', 1);
    xline(ax, 6000, '--k', 'LineWidth', 1);

%     % optional: mark the predefined analysis window
%     % (8-12 Hz, 500-2500 ms)
%     line(ax, [xRange(1), xRange(2)], [yValue,  yValue],  'Color','k', 'LineWidth',2);
%     line(ax, [xRange(1), xRange(2)], [yValue2, yValue2], 'Color','k', 'LineWidth',2);
%     line(ax, [xValue,  xValue],  [yRange(1), yRange(2)], 'Color','k', 'LineWidth',2);
%     line(ax, [xValue2, xValue2], [yRange(1), yRange(2)], 'Color','k', 'LineWidth',2);

    hold(ax,'off');
end

% shared y axis labels
ylabel(t, 'Frequency [Hz]', 'FontSize', 35);

% shared colorbar
cb = colorbar;
cb.Layout.Tile = 'east';
cb.Label.String = 'ERD/ERS [%]';
cb.FontSize = 31;

% ensure white figure background for export
set(fig, 'Color','w');
set(fig, 'PaperPositionMode','auto');

%% SAVE FIGURE

% save two-panel group-level grand-average figure
fileName = 'grand_average_2panel_tf_map_group.png';
exportgraphics(fig, fullfile(PATHOUT, fileName), ...
    'Resolution', 600, ...
    'BackgroundColor','white');

% return to scripts folder
cd(fullfile(MAINPATH, 'scripts', filesep));

% end of script