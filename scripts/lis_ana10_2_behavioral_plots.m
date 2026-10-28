%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana10_2_behavioral_plots.m
%
% This script visualizes block-wise attention and tiredness ratings during
% the intervention for the MVF and sham groups.
%
% The following steps are performed:
%           - Load participant-level attention and tiredness ratings
%           - Identify group membership (MVF, sham)
%           - Extract attention and tiredness ratings for each of the three
%             intervention blocks
%           - Compute the group mean and 95% confidence interval separately
%             for attention and tiredness in each intervention block
%           - Plot block-wise attention and tiredness ratings with 95%
%             confidence intervals for both groups
%           - Apply a small horizontal offset between groups to improve
%             visibility of overlapping confidence intervals
%           - Save the resulting behavioral figure
%
% Input:    - Int_behavioral_summary.xlsx:
%             Participant-level attention and tiredness ratings for the
%             three intervention blocks, including group information
%
% Note:     The file 'Int_behavioral_summary.xlsx' must be manually copied
%           into the Script 10 input folder (PATHIN) before running this
%           script.
%
% Output:   - behavior_blocks_attention_tiredness_mean95CI.png:
%             Mean attention and tiredness ratings for the MVF and sham
%             groups across the three intervention blocks with 95%
%             confidence intervals
%
% Linn Schwarz 03/03/2026
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
% NOTE: 'Int_behavioral_summary.xlsx' must be manually copied into
% PATHIN before running this script
fileNameXLS = fullfile(PATHIN,'Int_behavioral_summary.xlsx');

%% LOAD BEHAVIORAL DATA

% load participant-level behavioral data
T = readtable(fileNameXLS);

% obtain variable names
vn = string(T.Properties.VariableNames);

% identify group column using preferred variable names
if any(strcmpi(vn,"mt_sh"))
    gcol = "mt_sh";
elseif any(strcmpi(vn,"group"))
    gcol = "group";
else

    % if no predefined group column is found, search for the first column
    % containing both "mt" and "sh" group labels
    gcol = "";
    for k = 1:numel(vn)
        vname = vn(k);
        if iscellstr(T.(vname)) || isstring(T.(vname)) || iscategorical(T.(vname))
            tmp = string(T.(vname));
            tmp = lower(strtrim(tmp));
            if any(tmp=="mt") && any(tmp=="sh")
                gcol = vname;
                break
            end
        end
    end

    % stop execution if no valid group column can be identified
    if gcol == ""
        error('Could not find a group column. Rename it to "mt_sh" or "group".');
    end
end

% extract group labels and convert them to lowercase strings
grp = lower(strtrim(string(T.(gcol))));

%% EXTRACT ATTENTION AND TIREDNESS RATINGS

% define required rating columns for the three intervention blocks
reqCols = ["Block1_attention","Block2_attention","Block3_attention", ...
           "Block1_tiredness","Block2_tiredness","Block3_tiredness"];

% verify that all required rating columns are present
for c = reqCols
    if ~any(strcmpi(vn,c))
        error('Missing column: %s', c);
    end
end

% extract block-wise attention ratings
% rows = participants; columns = intervention blocks
att = [T.Block1_attention,  T.Block2_attention,  T.Block3_attention];

% extract block-wise tiredness ratings
% rows = participants; columns = intervention blocks
tir = [T.Block1_tiredness,  T.Block2_tiredness,  T.Block3_tiredness];

% retain only rows belonging to the MVF or sham group
valid = (grp=="mt" | grp=="sh");
grp = grp(valid);
att = att(valid,:);
tir = tir(valid,:);

%% ANALYSIS SETTINGS

% define group colors
col.mt_base = [0.2 0.6 0.85];   % MVF group
col.sh_base = [0.85 0.3 0.3];   % sham group

% define group labels
groups.mt = "mt";
groups.sh = "sh";
labels.mt = "MVF group";
labels.sh = "Sham group";

% define x-axis positions for intervention blocks
x = [1 2 3];

%% COMPUTE GROUP MEANS AND 95% CONFIDENCE INTERVALS

% identify participants belonging to each group
idx_mt = grp == groups.mt;
idx_sh = grp == groups.sh;

% compute mean and 95% confidence interval for attention ratings
[M_att_mt, CI_att_mt] = local_mean_ci95(att(idx_mt,:));
[M_att_sh, CI_att_sh] = local_mean_ci95(att(idx_sh,:));

% compute mean and 95% confidence interval for tiredness ratings
[M_tir_mt, CI_tir_mt] = local_mean_ci95(tir(idx_mt,:));
[M_tir_sh, CI_tir_sh] = local_mean_ci95(tir(idx_sh,:));

%% CREATE ATTENTION AND TIREDNESS FIGURE

% create figure with separate panels for attention and tiredness
figure('Color','w','Units','pixels','Position',[150 150 980 420]);
tl = tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

% define plotting parameters
lw = 2.6;
ms = 7;

% apply a small horizontal offset between groups to reduce overlap of
% confidence intervals while preserving the intervention block positions
dx = 0.07;         
x_mt = x - dx;        % MVF group slightly to the left
x_sh = x + dx;        % sham group slightly to the right

%% PLOT ATTENTION RATINGS

% create attention panel
ax1 = nexttile; hold on

% plot sham group first so that the MVF group remains visually on top
errorbar(x_sh, M_att_sh, CI_att_sh, '-o', ...
    'Color', col.sh_base, ...
    'MarkerFaceColor', col.sh_base, ...
    'MarkerEdgeColor', 'w', ...
    'LineWidth', lw, ...
    'MarkerSize', ms, ...
    'CapSize', 10);

% plot MVF group second
errorbar(x_mt, M_att_mt, CI_att_mt, '-o', ...
    'Color', col.mt_base, ...
    'MarkerFaceColor', col.mt_base, ...
    'MarkerEdgeColor', 'w', ...
    'LineWidth', lw, ...
    'MarkerSize', ms, ...
    'CapSize', 10);

% add panel title
title('Attention');

% format x-axis
xlim([0.7 3.3]);
xticks(x);
xticklabels({'Block 1','Block 2','Block 3'});
xlabel('Block');

% format y-axis according to the 7-point Likert scale
ylim([1 7]);
yticks(1:7);
ylabel('Rating (Likert 1–7)');

% format axes
box off;
set(ax1,'FontSize',12);

%% PLOT TIREDNESS RATINGS

% create tiredness panel
ax2 = nexttile; hold on

% plot sham group first so that the MVF group remains visually on top
h_sh = errorbar(x_sh, M_tir_sh, CI_tir_sh, '-o', ...
    'Color', col.sh_base, ...
    'MarkerFaceColor', col.sh_base, ...
    'MarkerEdgeColor', 'w', ...
    'LineWidth', lw, ...
    'MarkerSize', ms, ...
    'CapSize', 10);

% plot MVF group second
h_mt = errorbar(x_mt, M_tir_mt, CI_tir_mt, '-o', ...
    'Color', col.mt_base, ...
    'MarkerFaceColor', col.mt_base, ...
    'MarkerEdgeColor', 'w', ...
    'LineWidth', lw, ...
    'MarkerSize', ms, ...
    'CapSize', 10);

% add panel title
title('Tiredness');

% format x-axis
xlim([0.7 3.3]);
xticks(x);
xticklabels({'Block 1','Block 2','Block 3'});
xlabel('Block');

% format y-axis according to the 7-point Likert scale
ylim([1 7]);
yticks(1:7);
ylabel('Rating (Likert 1–7)');

% format axes
box off;
set(ax2,'FontSize',12);

%% FIGURE FORMATTING

% add legend to the tiredness panel
% handles are specified explicitly to retain MVF-first legend order even
% though the sham group is plotted first
legend([h_mt h_sh], {labels.mt, labels.sh}, ...
       'Location','northeast', ...
       'Box','off');

% add overall figure title
t = title(tl, 'Block-wise ratings during intervention (Mean \pm 95% CI)');
t.FontWeight = 'bold';

%% SAVE FIGURE

% save behavioral attention and tiredness figure
fileName = 'behavior_blocks_attention_tiredness_mean95CI.png';
exportgraphics(gcf, fullfile(PATHOUT, fileName), ...
    'Resolution', 300);

% display output path in command window
disp(['Saved plot to: ' fullfile(PATHOUT, fileName)]);

% return to scripts folder
cd(fullfile(MAINPATH,'scripts',filesep));

% end of main script

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOCAL FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [M, CI] = local_mean_ci95(Y)
% LOCAL_MEAN_CI95 computes column-wise means and 95% confidence intervals.
%
% Input:
%   Y   - Data matrix with participants in rows and intervention blocks
%         in columns
%
% Output:
%   M   - Row vector containing the mean for each intervention block
%   CI  - Row vector containing the two-sided 95% confidence interval
%         half-width for each intervention block

% determine number of intervention blocks
k = size(Y,2);

% initialize output vectors
M  = nan(1,k);
CI = nan(1,k);

% calculate mean and confidence interval separately for each block
for j = 1:k

    % extract ratings for current block and remove missing values
    y = Y(:,j);
    y = y(~isnan(y));

    % determine number of available participants
    n = numel(y);

    % calculate mean rating
    M(j) = mean(y);

    % calculate two-sided 95% confidence interval using the
    % Student's t distribution
    if n >= 2
        sem     = std(y) / sqrt(n);
        tcrit   = tinv(0.975, n-1);
        CI(j)   = tcrit * sem;
    else
        CI(j) = NaN;
    end
end

end