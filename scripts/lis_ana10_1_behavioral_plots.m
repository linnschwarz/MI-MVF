%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana10_1_behavioral_plots.m
%
% This script visualizes subjective motor imagery (MI) difficulty ratings
% for the two MI sessions (MI1 and MI2) in the MVF and sham groups.
%
% The following steps are performed:
%           - Load participant-level MI difficulty ratings
%           - Extract or calculate mean MI difficulty ratings separately
%             for MI1 and MI2
%           - Separate participants by group (MVF, sham)
%           - Compute the group mean and 95% confidence interval for each
%             MI session
%           - Plot mean MI difficulty ratings with 95% confidence intervals
%             for both groups across MI1 and MI2
%           - Apply a small horizontal offset between groups to improve
%             visibility of overlapping confidence intervals
%           - Save the resulting behavioral figure
%
% Input:    - MI_behavioral_summary.xlsx:
%             Participant-level MI difficulty ratings for MI1 and MI2,
%             including group information
%
% Note:     The file 'MI_behavioral_summary.xlsx' must be manually copied
%           into the Script 10 input folder (PATHIN) before running this
%           script.
%
% Output:   - behavior_MI_mean95CI.png:
%             Mean MI difficulty ratings for the MVF and sham groups across
%             MI1 and MI2 with 95% confidence intervals
%
% Linn Schwarz 14/04/2026
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DIRECTORIES

clear; close all; clc

% execute this script from within the 'scripts' folder
MAINPATH = fileparts(pwd);
PATHIN  = fullfile(MAINPATH,'data', 'lis10',filesep);       % path containing input data
PATHOUT = fullfile(MAINPATH,'data','lis10',filesep);        % path for script output

% create output folder if it does not exist yet
if ~exist(PATHOUT,'dir')
    mkdir(PATHOUT);
end

% define path to behavioral input file
% NOTE: 'MI_behavioral_summary.xlsx' must be manually copied into
% PATHIN before running this script
fileNameXLS = fullfile(PATHIN,'MI_behavioral_summary.xlsx');

%% LOAD BEHAVIORAL DATA

% load participant-level behavioral data
T = readtable(fileNameXLS);

% identify group column and convert group labels to lowercase strings
if any(strcmpi(T.Properties.VariableNames,'mt_sh'))
    grp = lower(strtrim(string(T.mt_sh)));
elseif any(strcmpi(T.Properties.VariableNames,'group'))
    grp = lower(strtrim(string(T.group)));
else
    error('Could not find group column.');
end

%% EXTRACT MI DIFFICULTY RATINGS

% use precomputed session averages if available
hasMI1avg = any(strcmpi(T.Properties.VariableNames,'MI1_avg'));
hasMI2avg = any(strcmpi(T.Properties.VariableNames,'MI2_avg'));

if hasMI1avg && hasMI2avg

    % extract precomputed mean MI difficulty ratings for each session
    MI1 = T.MI1_avg;
    MI2 = T.MI2_avg;
else

    % identify individual MI rating columns for each session
    mi1Cols = startsWith(T.Properties.VariableNames,'MI1_');
    mi2Cols = startsWith(T.Properties.VariableNames,'MI2_');

    % calculate participant-level mean MI difficulty ratings across prompts
    % separately for MI1 and MI2
    MI1 = mean(T{:,mi1Cols}, 2, 'omitnan');
    MI2 = mean(T{:,mi2Cols}, 2, 'omitnan');
end

% remove rows with missing group information or missing ratings for both
% MI sessions
valid = ~(ismissing(grp) | (isnan(MI1) & isnan(MI2)));
grp = grp(valid);
MI1 = MI1(valid);
MI2 = MI2(valid);

%% ANALYSIS SETTINGS

% define group colors
col.mt_base = [0.2 0.6 0.85];
col.sh_base = [0.85 0.3 0.3];

% define group labels
groups = ["mt","sh"];
labels = ["MVF group","Sham group"];

% define x-axis positions for MI sessions
x = [1 2];

%% COMPUTE GROUP MEANS AND 95% CONFIDENCE INTERVALS

% initialize matrices
% rows = groups (MVF, sham); columns = sessions (MI1, MI2)
M  = nan(2,2);
CI = nan(2,2);

% loop over groups
for g = 1:2

    % identify participants belonging to the current group
    idx = grp == groups(g);

    % collect MI1 and MI2 ratings
    y = {MI1(idx), MI2(idx)};

    % calculate mean and 95% confidence interval separately for each session
    for s = 1:2

        % remove missing values
        ys = y{s};
        ys = ys(~isnan(ys));

        % determine number of available participants
        n  = numel(ys);

        % calculate group mean
        M(g,s) = mean(ys);

        % calculate two-sided 95% confidence interval using the
        % Student's t distribution
        if n >= 2
            sem   = std(ys) / sqrt(n);
            tcrit = tinv(0.975, n-1);
            CI(g,s) = tcrit * sem;
        end
    end
end

%% CREATE MI DIFFICULTY FIGURE

% create figure
figure('Color','w','Units','pixels','Position',[150 150 780 520]); hold on

% define plotting parameters
lw = 2.8;      % line width
ms = 8;        % marker size

% apply a small horizontal offset between groups to reduce overlap of
% confidence intervals while preserving the MI1 and MI2 session positions
dx = 0.06;          
x_sh = x + dx;      % sham slightly right
x_mt = x - dx;      % mt slightly left

% plot sham group first so that the MVF group remains visually on top
h_sh = errorbar(x_sh, M(2,:), CI(2,:), '-o', ...
    'Color', col.sh_base, ...
    'MarkerFaceColor', col.sh_base, ...
    'MarkerEdgeColor', 'w', ...
    'LineWidth', lw, ...
    'MarkerSize', ms, ...
    'CapSize', 10);

% plot MVF group second
h_mt = errorbar(x_mt, M(1,:), CI(1,:), '-o', ...
    'Color', col.mt_base, ...
    'MarkerFaceColor', col.mt_base, ...
    'MarkerEdgeColor', 'w', ...
    'LineWidth', lw, ...
    'MarkerSize', ms, ...
    'CapSize', 10);

%% FIGURE FORMATTING

% format x-axis
xlim([0.7 2.3]);
xticks([1 2]);
xticklabels({'MI1','MI2'});
xlabel('MI Session');

% format y-axis according to the 7-point Likert scale
ylim([1 7]);
yticks(1:7);
ylabel('MI Scale (Likert 1–7)');

% format axes
box off
set(gca,'FontSize',12);

% add legend
% handles are specified explicitly to retain MVF-first legend order even
% though the sham group is plotted first
legend([h_mt h_sh], labels, 'Location','northeast', 'Box','off');

% add figure title
title('Behavioral ratings across MI sessions (Mean \pm 95% CI)');

%% SAVE FIGURE

% save behavioral MI difficulty figure
fileName = 'behavior_MI_mean95CI.png';
exportgraphics(gcf, fullfile(PATHOUT, fileName), ...
    'Resolution', 300);

% display output path in command window
disp(['Saved plot to: ' fullfile(PATHOUT, fileName)]);

% return to scripts folder
cd(fullfile(MAINPATH,'scripts',filesep));

% end of script