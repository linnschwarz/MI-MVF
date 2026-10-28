%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana10_3_behavioral_plots.m
%
% This script visualizes MVF-specific questionnaire items assessing the
% subjective experience of the mirror illusion during the intervention.
% These items were administered only to participants in the MVF group and
% are therefore summarized descriptively.
%
% The following steps are performed:
%           - Load participant-level intervention questionnaire data
%           - Identify the six MVF-specific questionnaire items
%           - Extract ratings for each questionnaire item
%           - Compute the mean and standard deviation across participants
%             for each item
%           - Plot item-wise mean ratings with standard deviations
%           - Display questionnaire items as separate data points without
%             connecting lines, as the items do not represent a time course
%           - Save the resulting behavioral figure
%
% Input:    - Int_behavioral_summary.xlsx:
%             Participant-level intervention questionnaire data including
%             the MVF-specific mirror illusion items
%
% Note:     The file 'Int_behavioral_summary.xlsx' must be manually copied
%           into the Script 10 input folder (PATHIN) before running this
%           script.
%
% Output:   - behavior_MVF_intervention_items_meanSD.png:
%             Mean ratings and standard deviations for the six MVF-specific
%             intervention questionnaire items
%
% Linn Schwarz 24/03/2026
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
% NOTE: 'Int_behavioral_summary.xlsx' must be manually copied into
% PATHIN before running this script
fileNameXLS = fullfile(PATHIN,'Int_behavioral_summary.xlsx');

%% LOAD BEHAVIORAL DATA

% load participant-level intervention questionnaire data
T = readtable(fileNameXLS);

% obtain variable names
vn = string(T.Properties.VariableNames);

%% IDENTIFY MVF-SPECIFIC QUESTIONNAIRE ITEMS

% define the six MVF-specific intervention questionnaire items
itemCols = [ ...
    "mt_mirror illusion realism", ...
    "mt_increasing realism", ...
    "mt_mirror arm not mine", ...
    "mt_only left arm movement", ...
    "mt_only right arm movement", ...
    "mt_both arms movement" ...
];

% initialize array for mapped variable names
mapped = strings(1, numel(itemCols));

% identify the corresponding table variable for each questionnaire item
for i = 1:numel(itemCols)

    % convert target item name to lowercase and remove leading/trailing spaces
    target = lower(strtrim(itemCols(i)));

    % first, search for an exact match
    hit = find(lower(vn) == target, 1);

    % if no exact match is found, search for a matching variable name
    % without spaces in the target string
    if isempty(hit)
        hit = find(contains(lower(vn), erase(target," ")), 1);
    end

    % if still no match is found, search for the complete target string
    if isempty(hit)
        hit = find(contains(lower(vn), target), 1);
    end

    % stop execution if the questionnaire item cannot be identified
    if isempty(hit)
        error('Could not find column for item: "%s".', itemCols(i));
    end

    % store identified variable name
    mapped(i) = vn(hit);
end

%% EXTRACT MVF-SPECIFIC RATINGS

% extract questionnaire ratings
% rows = participants; columns = questionnaire items
Y = T{:, mapped};

% convert ratings to numeric values
Y = double(Y);

% replace non-finite values with NaN
Y(~isfinite(Y)) = NaN;

%% COMPUTE DESCRIPTIVE STATISTICS

% compute mean and standard deviation across participants for each item
M  = mean(Y, 1, 'omitnan');
SD = std(Y,  0, 1, 'omitnan');

% define x-axis positions for the six questionnaire items
x = 1:6;

%% ANALYSIS SETTINGS

% define MVF group color
col.mt_base = [0.2 0.6 0.85];

%% CREATE MVF QUESTIONNAIRE FIGURE

% create figure
figure('Color','w','Units','pixels','Position',[200 200 820 420]); hold on

% define plotting parameters
ms = 9;       % marker size
lw = 1.8;     % line width

% plot item-wise means and standard deviations
% no connecting lines are used because the questionnaire items represent
% separate constructs rather than consecutive time points
h = errorbar(x, M, SD, 'o', ...
    'Color', col.mt_base, ...
    'MarkerFaceColor', col.mt_base, ...
    'MarkerEdgeColor', 'w', ...
    'LineWidth', lw, ...
    'MarkerSize', ms, ...
    'CapSize', 10, ...
    'LineStyle','none'); 

%% FIGURE FORMATTING

% format x-axis
xlim([0.5 6.5]);
xticks(1:6);
xticklabels({'1','2','3','4','5','6'});
xlabel('Items Intervention Questionnaire');

% format y-axis according to the 7-point Likert scale
ylim([0.7 7.2]);
yticks(1:7);
ylabel('Rating (Likert 1–7)');

% format axes
box off
set(gca,'FontSize',12);

% add figure title
title('MVF Intervention Questionnaire (Mean \pm SD)', ...
      'FontWeight','bold');

% add legend
legend(h, {'MVF group'}, ...
       'Location','northeast', ...
       'Box','off');


%% SAVE FIGURE

% save MVF intervention questionnaire figure
fileName = 'behavior_MVF_intervention_items_meanSD.png';
exportgraphics(gcf, fullfile(PATHOUT, fileName), ...
    'Resolution', 300);

% display output path in command window
disp(['Saved plot to: ' fullfile(PATHOUT, fileName)]);

% return to scripts folder
cd(fullfile(MAINPATH,'scripts',filesep));

% end of script