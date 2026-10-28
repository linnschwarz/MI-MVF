%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana06_2_tf_map_20panel.m
%
% This script visualizes the grand-average time-frequency ERD/ERS results
% generated in lis_ana06_1 in a single 20-panel figure.
%
% The four group x session grand averages are arranged in rows, while the
% four sensorimotor electrodes and their average are arranged in columns.
% This allows direct visual comparison of the time-frequency ERD/ERS
% patterns between experimental groups, motor imagery sessions, and
% sensorimotor regions.
%
% Figure layout:
%           Rows:
%             1 - MVF group, MI1
%             2 - MVF group, MI2
%             3 - Sham group, MI1
%             4 - Sham group, MI2
%
%           Columns:
%             1 - Left central (FC1)
%             2 - Right central (FC2)
%             3 - Left centro-parietal (C3)
%             4 - Right centro-parietal (C4)
%             5 - Sensorimotor average (FC1, FC2, C3, C4)
%
% The following steps are performed:
%           - Load the four group x session grand-average ERD/ERS matrices
%             generated in lis_ana06_1
%           - Load the corresponding time and frequency vectors
%           - Arrange all grand-average maps in a 4 x 5 tiled layout
%           - Apply identical time, frequency, and color-axis limits to all
%             panels
%           - Mark motor imagery onset and offset at 0 and 6000 ms
%           - Mark the predefined analysis window (8-12 Hz, 500-2500 ms)
%           - Add shared time and frequency labels and a shared colorbar
%           - Add group and session labels to each figure row
%           - Save the complete 20-panel figure
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
% Output:   - grand_average_20panel_tf_map_boxed_new.png:
%             20-panel figure containing all group x session grand-average
%             time-frequency ERD/ERS maps
%
% Linn Schwarz 17/04/2026
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

%% FIGURE SETTINGS

% define figure dimensions
figW = 1800;  % width in pixels
figH = 1100;  % height in pixels

% arrange grand averages according to figure rows
grandaverages = {MI1_mt_GA, MI2_mt_GA, MI1_sh_GA, MI2_sh_GA};

% define group and session labels for each row
rowLabels = { {'MVF group', 'MI1'}, ...
              {'MVF group', 'MI2'}, ...
              {'Sham group', 'MI1'}, ...
              {'Sham group', 'MI2'} };

% define electrode/region labels for each column
colLabels = {'Left central', ...
             'Right central', ...
             'Left centro-parietal', ...
             'Right centro-parietal', ...
             'Sensorimotor average'};

% define common axis limits and ticks for all panels
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

%% CREATE 20-PANEL GRAND-AVERAGE FIGURE

% create 4 x 5 tiled layout:
% rows = group x session conditions
% columns = electrodes/regions
fig = figure('Position',[100 100 figW figH]);
t = tiledlayout(4,5,'TileSpacing','compact','Padding','loose');

% initialize matrix for storing axes handles
axMat = gobjects(4,5);

% loop over group x session conditions
for row = 1:4

    % select grand-average matrix for current row
    currentGA = grandaverages{row};

    % loop over four electrodes and sensorimotor average
    for col = 1:5
        ax = nexttile;
        axMat(row,col) = ax;
        hold(ax,'on');

        % plot grand-average time-frequency ERD/ERS representation
        imagesc(ax, times_check, freqs_check, currentGA(:,:,col));
        axis(ax,'xy');
        colormap(ax,'jet');
        caxis(ax,[-75 75]);

        % apply identical axis limits and ticks to all panels
        xlim(ax,xlims);
        ylim(ax,ylims);
        xticks(ax,xt);
        yticks(ax,yt);
        set(ax, 'TickDir','out', 'Layer','top', 'FontSize',8)

        % show time tick labels only in the bottom row
        if row < 4
            xticklabels(ax,[]);
        end

        % show frequency tick labels only in the left column
        if col > 1
            yticklabels(ax,[]);
        end

        % individual axis labels are omitted because shared labels are used
        xlabel(ax,'');
        ylabel(ax,'');

        % add electrode/region titles only above the first row
        if row == 1
            title(ax, colLabels{col}, 'FontSize', 12, 'FontWeight', 'bold', ...
                'Units','normalized', 'Position',[0.5 1.08 0]);
        else
            title(ax,'');
        end

        % mark motor imagery onset (0 ms) and offset (6000 ms)
        xline(ax, 0, '--k', 'LineWidth', 1);
        xline(ax, 6000, '--k', 'LineWidth', 1);

        % mark the predefined analysis window (8-12 Hz, 500-2500 ms)
        line(ax, [xRange(1), xRange(2)], [yValue,  yValue],  'Color','k', 'LineWidth',2);
        line(ax, [xRange(1), xRange(2)], [yValue2, yValue2], 'Color','k', 'LineWidth',2);
        line(ax, [xValue,  xValue],  [yRange(1), yRange(2)], 'Color','k', 'LineWidth',2);
        line(ax, [xValue2, xValue2], [yRange(1), yRange(2)], 'Color','k', 'LineWidth',2);

        hold(ax,'off');
    end
end

% shared axis labels
xlabel(t, 'Time [ms]', 'FontSize', 12);
ylabel(t, 'Frequency [Hz]', 'FontSize', 12);

% shared colorbar
cb = colorbar;
cb.Layout.Tile = 'east';
cb.Label.String = 'ERD/ERS [%]';
cb.FontSize = 10;

% update figure before accessing final axes positions
drawnow;

%% ADD GROUP AND SESSION ROW LABELS

% add group and session information to the left of each figure row
for row = 1:4

    % obtain position of the first panel in the current row
    pos = axMat(row,1).Position;   % [left bottom width height]

    % define annotation position to the left of the first column
    xAnno = 0;
    yAnno = pos(2) + pos(4)/2 - 0.02;
    wAnno = 0.10;
    hAnno = 0.04;

    % add group and session label
    annotation(fig, 'textbox', ...
        [xAnno, yAnno, wAnno, hAnno], ...
        'String', rowLabels{row}, ...
        'LineStyle', 'none', ...
        'HorizontalAlignment', 'left', ...
        'VerticalAlignment', 'middle', ...
        'FontSize', 12, ...
        'FontWeight', 'bold', ...
        'FitBoxToText', 'off');
end

%% SAVE FIGURE 

% save complete 20-panel grand-average figure
fileName = 'grand_average_20panel_tf_map_boxed_new.png';
exportgraphics(fig, fullfile(PATHOUT, fileName), ...
    'Resolution', 600);

% return to scripts folder
cd(fullfile(MAINPATH, 'scripts', filesep));

% end of script
