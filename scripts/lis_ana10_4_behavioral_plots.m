%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana10_4_behavioral_plots.m
%
% This script visualizes post-procedure questionnaire ratings for the MVF
% and sham groups. The questionnaire was administered once at the end of
% the experimental procedure and comprised three 7-point Likert-scale items.
%
% The following steps are performed:
%           - Load participant-level post-procedure questionnaire data
%           - Identify group membership (MVF, sham)
%           - Extract the three post-procedure questionnaire items
%           - Compute the group mean and 95% confidence interval separately
%             for each questionnaire item
%           - Plot item-wise mean ratings with 95% confidence intervals for
%             both groups
%           - Apply a small horizontal offset between groups to improve
%             visibility of overlapping confidence intervals
%           - Display questionnaire items as separate data points without
%             connecting lines, as the items do not represent a time course
%           - Save the resulting behavioral figure
%
% Input:    - Post_behavioral_summary.xlsx:
%             Participant-level post-procedure questionnaire ratings for
%             both groups, including group information
%
% Note:     The file 'Post_behavioral_summary.xlsx' must be manually copied
%           into the Script 10 input folder (PATHIN) before running this
%           script.
%
% Output:   - behavior_post_questionnaire_mean95CI.png:
%             Mean post-procedure questionnaire ratings for the MVF and
%             sham groups with 95% confidence intervals
%
% Linn Schwarz 13/04/2026
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DIRECTORIES

clear; close all; clc

% execute this script from within the 'scripts' folder
MAINPATH = fileparts(pwd);
PATHIN  = fullfile(MAINPATH,'data','lis10',filesep);        % path containing input data
PATHOUT = fullfile(MAINPATH,'data','lis10',filesep);        % path for script output

% create output folder if it does not exist yet
if ~exist(PATHOUT,'dir')
    mkdir(PATHOUT);
end

% define path to behavioral input file
% NOTE: 'Post_behavioral_summary.xlsx' must be manually copied into
% PATHIN before running this script
fileNameXLS = fullfile(PATHIN,'Post_behavioral_summary.xlsx');

%% LOAD BEHAVIORAL DATA

% load participant-level post-procedure questionnaire data while preserving
% the original Excel variable names
T = readtable(fileNameXLS, 'VariableNamingRule','preserve');

% obtain variable names
vn = string(T.Properties.VariableNames);

%% IDENTIFY GROUP MEMBERSHIP

% identify group column using preferred variable names
if any(strcmpi(vn,"mt/sh?"))
    gcol = "mt/sh?";
elseif any(strcmpi(vn,"mt_sh"))
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
            tmp = lower(strtrim(string(T.(vname))));
            if any(tmp=="mt") && any(tmp=="sh")
                gcol = vname;
                break
            end
        end
    end

    % stop execution if no valid group column can be identified
    if gcol == ""
        error('Could not find a group column. Rename it to "mt/sh?" or "mt_sh" or "group".');
    end
end

% extract group labels and convert them to lowercase strings
grp = lower(strtrim(string(T.(gcol))));

%% IDENTIFY POST-PROCEDURE QUESTIONNAIRE ITEMS

% define the three questionnaire items using the exact Excel headers
itemCols = [ ...
    "1) difficulty of experiment", ...
    "2) clarity of instructions", ...
    "3) feeling after experiment" ...
];

% verify that all required questionnaire items are present
for i = 1:numel(itemCols)

    if ~any(vn == itemCols(i))

        % display available variable names to facilitate troubleshooting
        disp("Available column names are:");
        disp(vn');

        error('Could not find column for item: "%s".', itemCols(i));
    end
end

%% EXTRACT POST-PROCEDURE RATINGS

% extract questionnaire ratings
% rows = participants; columns = questionnaire items
Y = double([ ...
    T.(itemCols(1)), ...
    T.(itemCols(2)), ...
    T.(itemCols(3)) ...
]);

% replace non-finite values with NaN
Y(~isfinite(Y)) = NaN;

% retain only rows belonging to the MVF or sham group
valid = (grp=="mt" | grp=="sh");
grp = grp(valid);
Y   = Y(valid,:);

%% ANALYSIS SETTINGS

% define group colors
col.mt_base = [0.2 0.6 0.85];   % MVF group
col.sh_base = [0.85 0.3 0.3];   % sham group

% define group labels
labels.mt = "MVF group";
labels.sh = "Sham group";

% define x-axis positions for the three questionnaire items
x = 1:3;

%% COMPUTE GROUP MEANS AND 95% CONFIDENCE INTERVALS

% compute mean and 95% confidence interval separately for each
% questionnaire item and group
[M_mt, CI_mt] = local_mean_ci95(Y(grp=="mt",:));
[M_sh, CI_sh] = local_mean_ci95(Y(grp=="sh",:));

%% CREATE POST-PROCEDURE QUESTIONNAIRE FIGURE

% create figure
figure('Color','w','Units','pixels','Position',[200 200 880 420]); hold on

% define plotting parameters
ms = 9;     % marker size
lw = 1.8;   % line width

% apply a small horizontal offset between groups to reduce overlap of
% confidence intervals while preserving the questionnaire item positions
dx = 0.12;
x_mt = x - dx;      % MVF group slightly to the left
x_sh = x + dx;      % sham group slightly to the right

% plot sham group first so that the MVF group remains visually on top
h_sh = errorbar(x_sh, M_sh, CI_sh, 'o', ...
    'Color', col.sh_base, ...
    'MarkerFaceColor', col.sh_base, ...
    'MarkerEdgeColor', 'w', ...
    'LineWidth', lw, ...
    'MarkerSize', ms, ...
    'CapSize', 10, ...
    'LineStyle','none');

% plot MVF group second
h_mt = errorbar(x_mt, M_mt, CI_mt, 'o', ...
    'Color', col.mt_base, ...
    'MarkerFaceColor', col.mt_base, ...
    'MarkerEdgeColor', 'w', ...
    'LineWidth', lw, ...
    'MarkerSize', ms, ...
    'CapSize', 10, ...
    'LineStyle','none');

%% FIGURE FORMATTING

% format x-axis
xlim([0.5 3.5]);
xticks(1:3);
xticklabels({'1','2','3'});
xlabel('Items Post-Procedure Questionnaire');

% format y-axis according to the 7-point Likert scale
ylim([0.5 7]);
yticks(1:7);
ylabel('Rating (Likert 1–7)');

% format axes
box off
set(gca,'FontSize',12);

% add figure title
title('Post Questionnaire (Mean \pm 95% CI)', 'FontWeight','bold');

% add legend
% handles are specified explicitly to retain MVF-first legend order even
% though the sham group is plotted first
legend([h_mt h_sh], {labels.mt, labels.sh}, 'Location','northeast', 'Box','off');

%% SAVE FIGURE

% save post-procedure questionnaire figure
fileName = 'behavior_post_questionnaire_mean95CI.png';
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
%   Y   - Data matrix with participants in rows and questionnaire items
%         in columns
%
% Output:
%   M   - Row vector containing the mean for each questionnaire item
%   CI  - Row vector containing the two-sided 95% confidence interval
%         half-width for each questionnaire item

% determine number of questionnaire items
k = size(Y,2);

% initialize output vectors
M  = nan(1,k);
CI = nan(1,k);

% calculate mean and confidence interval separately for each item
for j = 1:k

    % extract ratings for current item and remove missing values
    y = Y(:,j);
    y = y(~isnan(y));

    % determine number of available participants
    n = numel(y);

    % continue to next item if no valid observations are available
    if n == 0
        continue
    end

    % calculate mean rating
    M(j) = mean(y);

    % calculate two-sided 95% confidence interval using the
    % Student's t distribution
    if n >= 2
        sem   = std(y) / sqrt(n);
        tcrit = tinv(0.975, n-1);
        CI(j) = tcrit * sem;
    else
        CI(j) = NaN;
    end
end

end