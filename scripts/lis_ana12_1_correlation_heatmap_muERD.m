%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana12_1_correlation_heatmap_muERD.m
%
% This script examines associations between changes in left-hemispheric
% mu-band ERD and subjective ratings using Spearman rank correlations.
% Correlations are calculated between the change in mu ERD from MI1 to MI2
% (MI2 minus MI1) and questionnaire ratings collected during the experiment.
%
% The following steps are performed:
%           - Load the statistical input data
%           - Separate participants by experimental group (MVF, sham)
%           - Compute Spearman correlations between the change in
%             left-hemispheric mu ERD and MVF-specific ratings for the
%             MVF group
%           - Compute Spearman correlations between the change in
%             left-hemispheric mu ERD and ratings collected in both groups,
%             separately for the MVF and sham groups
%           - Visualize the correlation coefficients in two heatmaps using
%             a common diverging color scale ranging from -1 to 1
%           - Save the resulting two-panel correlation heatmap
%
% Input:    - stat_input_correlation.mat:
%             Structure containing participant-level questionnaire ratings,
%             group information, and the change in left-hemispheric mu ERD
%             from MI1 to MI2
%
% Output:   - Correlation_heatmap_muERD.png:
%             Two-panel heatmap showing Spearman correlation coefficients
%             between changes in left-hemispheric mu ERD and subjective
%             ratings for the MVF and sham groups
%
% Linn Schwarz 23/06/2026
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DIRECTORIES

clear; close all;

% execute this script from within the 'scripts' folder
MAINPATH = fileparts(pwd);
PATHIN  = fullfile(MAINPATH,'data','lis07_8-12Hz_500-2500ms_LI',filesep);   % statistical input data             
PATHOUT = fullfile(MAINPATH, 'data','lis12',filesep);                       % path for figure output

% create output folder if it does not exist yet
if ~exist(PATHOUT,'dir')
    mkdir(PATHOUT);
end

%% LOAD DATA

% load participant-level data containing questionnaire ratings, group
% information, and change in left-hemispheric mu ERD from MI1 to MI2
cd(PATHIN)
load( 'stat_input_correlation.mat')

%% DEFINE DIVERGING COLORMAP

% create blue-white-red colormap for visualization of correlation
% coefficients, with blue indicating negative correlations, white
% indicating zero, and red indicating positive correlations
n = 256;

bottom = [0 0 1];      % blue
middle = [1 1 1];      % white
top    = [1 0 0];      % red

r = [linspace(bottom(1),middle(1),n/2), ...
     linspace(middle(1),top(1),n/2)]';

g = [linspace(bottom(2),middle(2),n/2), ...
     linspace(middle(2),top(2),n/2)]';

b = [linspace(bottom(3),middle(3),n/2), ...
     linspace(middle(3),top(3),n/2)]';

redblue = [r g b];

%% IDENTIFY GROUPS

% identify participants belonging to each experimental group
group = string({stat_input.group});

idx_mvf  = group=="mt";
idx_sham = group=="sh";

%% COMPUTE CORRELATIONS FOR MVF-SPECIFIC RATINGS

% define ratings that were collected only in the MVF group
vars_mvf = { ...
    'Vividness_of_illusion'
    'Increasing_realism'
    'Mirror_arm_not_mine'
    'Only_left_arm_movement'
    'Only_right_arm_movement'
    'Both_arms_movement'};

% initialize array for Spearman correlation coefficients
R_mvf = nan(length(vars_mvf),1);

% correlate each MVF-specific rating with the change in left-hemispheric
% mu ERD from MI1 to MI2; participants with missing values are excluded
% separately for each correlation
for i = 1:length(vars_mvf)

    y = [stat_input.(vars_mvf{i})];
    x = [stat_input.LHMI2minusLHMI1];

    idx = idx_mvf & ~isnan(x) & ~isnan(y);

    R_mvf(i) = corr( ...
        x(idx)', ...
        y(idx)', ...
        'Type','Spearman');

end

%% COMPUTE CORRELATIONS FOR RATINGS COLLECTED IN BOTH GROUPS

% define ratings that were collected in both experimental groups
vars_all = { ...
    'Session_challenging'
    'Avg_attention'
    'Avg_tiredness'};

% initialize matrix for group-specific Spearman correlation coefficients
% column 1 = MVF group, column 2 = sham group
R_groups = nan(length(vars_all),2);

% correlate each rating with the change in left-hemispheric mu ERD
% separately for the MVF and sham groups
for i = 1:length(vars_all)

    y = [stat_input.(vars_all{i})];
    x = [stat_input.LHMI2minusLHMI1];

    % MVF group
    idx = idx_mvf & ~isnan(x) & ~isnan(y);

    R_groups(i,1) = corr( ...
        x(idx)', ...
        y(idx)', ...
        'Type','Spearman');

    % sham group
    idx = idx_sham & ~isnan(x) & ~isnan(y);

    R_groups(i,2) = corr( ...
        x(idx)', ...
        y(idx)', ...
        'Type','Spearman');

end

%% CREATE CORRELATION HEATMAPS

% create 1 x 2 tiled layout
figure('Color','w','Position',[100 100 1000 500])
tiledlayout(1,2,'TileSpacing','loose','Padding','loose')

% plot correlations for MVF-specific ratings
nexttile
imagesc(R_mvf)
clim([-1 1])

% define descriptive labels for visualization
vars_mvf = { ...
    'Illusion realism'
    'Increasing realism'
    'Ownership (reversed)'
    'Left-arm movement'
    'Right-arm movement'
    'Bilateral movement'};

yticks(1:length(vars_mvf))
yticklabels(strrep(vars_mvf,'_',' '))

xticks(1)
xticklabels({'MVF'})

ax = gca;
ax.FontSize = 15;

title('MVF-specific ratings', 'FontSize',17);
subtitle(' ', FontSize=4);

% display Spearman correlation coefficient within each heatmap cell
for i = 1:size(R_mvf,1)

    text(1,i,...
        sprintf('%.2f',R_mvf(i)),...
        'HorizontalAlignment','center',...
        'FontSize',15);

end

% plot correlations for ratings collected in both groups
nexttile
imagesc(R_groups)
clim([-1 1])

% define descriptive labels for visualization
vars_all = { ...
    'Task demand'
    'Attention'
    'Tiredness'};

yticks(1:length(vars_all))
yticklabels(strrep(vars_all,'_',' '))

xticks([1 2])
xticklabels({'MVF','Sham'})

ax = gca;
ax.FontSize = 15;

title('Ratings collected in both groups', 'FontSize',17)
subtitle(' ', FontSize=4);

% display Spearman correlation coefficients within each heatmap cell
for row = 1:size(R_groups,1)

    for col = 1:size(R_groups,2)

        text(col,row,...
            sprintf('%.2f',R_groups(row,col)),...
            'HorizontalAlignment','center',...
             'FontSize',15);

    end

end

% apply common blue-white-red colormap and correlation limits
colormap(redblue)
clim([-1 1])

% add shared colorbar
cb = colorbar;
cb.Layout.Tile = 'east';
cb.FontSize = 15;
ylabel(cb,'Spearman ρ')

%% SAVE FIGURE

% save two-panel correlation heatmap
fileName = 'Correlation_heatmap_muERD.png';
exportgraphics(gcf, fullfile(PATHOUT, fileName), ...
    'Resolution',600);

% return to scripts folder
cd(fullfile(MAINPATH,'scripts',filesep));

% end of script