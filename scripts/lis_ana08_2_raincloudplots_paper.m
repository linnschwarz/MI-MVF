%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana08_2_raincloudplots_paper.m
%
% This script generates a publication-oriented raincloud figure of
% participant-level mu-band ERD/ERS and hemispheric lateralization measures
% for the MVF and Sham groups across MI1 and MI2.
%
% The following steps are performed:
%           - Load participant-level ERD/ERS and lateralization measures
%           - Plot left- and right-hemisphere mu ERD/ERS for both groups
%           - Plot general hemispheric lateralization (LH - RH)
%           - Display individual data, distributions, and group means
%           - Save the combined three-panel figure as a high-resolution PNG
%
% Input:    - stat_input.mat
%
% Output:   - Hyp1_Hyp2_general_combined.png
%
% Linn Schwarz 28/01/2026
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DIRECTORIES

clear all; close all; clc

% execute this script from within the 'scripts' folder
MAINPATH = fileparts(pwd);
PATHIN  = fullfile(MAINPATH,'data','lis07_8-12Hz_500-2500ms_LI',filesep);      % path containing input data                   
PATHOUT = fullfile(MAINPATH, 'data','lis08_8-12Hz_500-2500ms_LI',filesep);  % path for script output

% create output folder if it does not exist yet
if ~exist(PATHOUT)
    mkdir(PATHOUT);
end

%% LOAD DATA

% load participant-level ERD/ERS and lateralization measures generated
% in lis_ana07_1_pre_stat.m
cd(PATHIN)
load( 'stat_input.mat')

% return to scripts folder
cd(fullfile(MAINPATH, 'scripts'));

%% PLOT SETTINGS

% use shorter variable name for statistical input structure
S = stat_input;

% extract participant group assignments
grp = string({S.group});

% identify participants belonging to each experimental group
idx_mt = grp == "mt";
idx_sh = grp == "sh";

% define group identifiers and corresponding figure labels
groups    = ["mt","sh"];
groups_MA = ["MVF group","Sham group"];

% define horizontal jitter for individual participant values
jit = 0.06; 

% define base colors for experimental groups
col.mt_base = [0.2 0.6 0.85];   % MVF group
col.sh_base = [0.85 0.3 0.3];   % Sham group

% helper function for generating lighter shades of a base color
% w = 0 returns the original color; increasing w approaches white
blend = @(c, w) c + (1-c)*w;    % w in [0..1], larger -> lighter

% define hemisphere-specific colors for half-violin distributions
% left hemisphere = darker; right hemisphere = lighter
col.mt_LH = blend(col.mt_base, 0.00); 
col.mt_RH = blend(col.mt_base, 0.50); 

col.sh_LH = blend(col.sh_base, 0.00); 
col.sh_RH = blend(col.sh_base, 0.50); 

% define group colors for the lateralization panel
col.mt_lat = blend(col.mt_base, 0.10);
col.sh_lat = blend(col.sh_base, 0.10);

% define hemisphere-specific colors for individual participant data
% left hemisphere = moderately saturated; right hemisphere = lighter
col.mt_LH_ind = blend(col.mt_base, 0.20);
col.mt_RH_ind = blend(col.mt_base, 0.70);

col.sh_LH_ind = blend(col.sh_base, 0.20);
col.sh_RH_ind = blend(col.sh_base, 0.70);

% helper function for generating lighter individual-data colors in the
% lateralization panel
tintInd = @(c) blend(c, 0.40); 

% define line widths and point transparency
lwInd   = 1;    
meanLW  = 4;

%% Y-LIMITS FOR HYPOTHESIS 1: LEFT- AND RIGHT-HEMISPHERE ERD/ERS

% combine all ERD/ERS values to determine common y-axis limits across
% groups, hemispheres, and motor imagery sessions
Y2 = [ ...
    [S(idx_mt).LHMI1]'; [S(idx_mt).LHMI2]'; [S(idx_mt).RHMI1]'; [S(idx_mt).RHMI2]'; ...
    [S(idx_sh).LHMI1]'; [S(idx_sh).LHMI2]'; [S(idx_sh).RHMI1]'; [S(idx_sh).RHMI2]' ...
];

% exclude missing values before calculating axis limits
Y2 = Y2(~isnan(Y2));

% determine common y-axis limits with additional padding
pad2 = max(0.2 * range(Y2), 12);
yl2 = [min(Y2)-pad2, max(Y2)+pad2];

%% Y-LIMITS FOR HYPOTHESIS 2: GENERAL LATERALIZATION

% combine general lateralization values to determine common y-axis limits
% across groups and motor imagery sessions
Y4 = [ ...
    [S(idx_mt).LHminusRHMI1]'; [S(idx_mt).LHminusRHMI2]'; ...
    [S(idx_sh).LHminusRHMI1]'; [S(idx_sh).LHminusRHMI2]' ...
];

% exclude missing values before calculating axis limits
Y4 = Y4(~isnan(Y4));

% determine common y-axis limits with additional padding
pad4 = max(0.2 * range(Y4), 12);
yl4 = [min(Y4)-pad4, max(Y4)+pad4];

%% COMBINED PUBLICATION FIGURE

% create three-panel figure:
%   panel 1 = MVF group ERD/ERS
%   panel 2 = Sham group ERD/ERS
%   panel 3 = general lateralization for both groups
figure('Color','w','Units','pixels','Position',[100 100 1650 900]);
tl = tiledlayout(1,3,'TileSpacing','compact','Padding','loose');

%% HYPOTHESIS 1: LEFT- AND RIGHT-HEMISPHERE MU ERD/ERS

% generate one panel for each experimental group
for g = 1:2

    nexttile; hold on

    % select participants belonging to the current group
    idx = grp == groups(g);

    % select group-specific colors for distributions, individual data,
    % and mean trajectories
    if groups(g) == "mt"
        cLH   = col.mt_LH;
        cRH   = col.mt_RH;
        cLHind = col.mt_LH_ind;
        cRHind = col.mt_RH_ind;
        cmean = col.mt_base;
    else
        cLH   = col.sh_LH;
        cRH   = col.sh_RH;
        cLHind = col.sh_LH_ind;
        cRHind = col.sh_RH_ind;
        cmean = col.sh_base;
    end

    % extract left- and right-hemisphere ERD/ERS values for both sessions
    LH1 = [S(idx).LHMI1]'; LH2 = [S(idx).LHMI2]';
    RH1 = [S(idx).RHMI1]'; RH2 = [S(idx).RHMI2]';


    % plot half-violin distributions
    % left hemisphere is shown on the left side of each session position,
    % right hemisphere on the right side
    half_violin(1, LH1, "left",  cLH)
    half_violin(1, RH1, "right", cRH)
    half_violin(2, LH2, "left",  cLH)
    half_violin(2, RH2, "right", cRH)

    % horizontally separate LH and RH individual values around the
    % corresponding MI session positions
    offset = 0.08;

    % left-hemisphere values are positioned to the left of session center
    x1_LH = (1-offset) + (rand(numel(LH1),1)-0.5)*2*jit;
    x2_LH = (2-offset) + (rand(numel(LH1),1)-0.5)*2*jit;

    % right-hemisphere values are positioned to the right of session center
    x1_RH = (1+offset) + (rand(numel(RH1),1)-0.5)*2*jit;
    x2_RH = (2+offset) + (rand(numel(RH1),1)-0.5)*2*jit;

    % plot individual participant trajectories and endpoints
    for i = 1:numel(LH1)
        plot([x1_LH(i) x2_LH(i)], [LH1(i) LH2(i)], '-', ...
            'Color', cLHind, 'LineWidth', lwInd, 'HandleVisibility','off');
        plot([x1_RH(i) x2_RH(i)], [RH1(i) RH2(i)], '-', ...
            'Color', cRHind, 'LineWidth', lwInd, 'HandleVisibility','off');

        scatter([x1_LH(i) x2_LH(i)], [LH1(i) LH2(i)], 18, 'filled', ...
            'MarkerFaceColor', cLHind, 'MarkerFaceAlpha', 1, ...
            'MarkerEdgeColor','none', 'HandleVisibility','off');
        scatter([x1_RH(i) x2_RH(i)], [RH1(i) RH2(i)], 18, 'filled', ...
            'MarkerFaceColor', cRHind, 'MarkerFaceAlpha', 1, ...
            'MarkerEdgeColor','none', 'HandleVisibility','off');
    end

    % calculate group means for both hemispheres and sessions
    mLH = [mean(LH1,'omitnan') mean(LH2,'omitnan')];
    mRH = [mean(RH1,'omitnan') mean(RH2,'omitnan')];

    % position LH and RH means on the same side as their distributions
    xMean_LH = [1-offset 2-offset];
    xMean_RH = [1+offset 2+offset];

    % plot mean trajectories using the saturated group color
    % LH mean = solid line; RH mean = dashed line
    plot(xMean_LH, mLH, '-', 'Color', cmean, 'LineWidth',meanLW, 'HandleVisibility','off');
    plot(xMean_RH, mRH, '--', 'Color', cmean, 'LineWidth',meanLW, 'HandleVisibility','off');

    % plot mean endpoints
    scatter(xMean_LH, mLH, 70, 'filled', 'MarkerFaceColor', cmean, ...
        'MarkerEdgeColor','w', 'LineWidth',0.8, 'HandleVisibility','off');
    scatter(xMean_RH, mRH, 70, 'filled', 'MarkerFaceColor', cmean, ...
        'MarkerEdgeColor','w', 'LineWidth',0.8, 'HandleVisibility','off');


    % format axes
    title(groups_MA(g), 'FontSize',24)
    xlim([0.5 2.5])
    ylim(yl2)
    xticks([1 2])
    xticklabels({'MI1','MI2'})
    xlabel('MI session', 'FontSize',24)
    box off
    ax = gca;
    ax.FontSize = 22;

    % display y-axis label only in the first panel
    if g == 1
        ylabel('Mu ERD/ERS [%]')
    end

    % create legend handles for individual and mean trajectories
    hLHS = plot(nan,nan,'-','Color',cLHind,'LineWidth',lwInd);
    hRHS = plot(nan,nan,'-','Color',cRHind,'LineWidth',lwInd);
    hLHM = plot(nan,nan,'-','Color',cmean,'LineWidth',meanLW);
    hRHM = plot(nan,nan,'--','Color',cmean,'LineWidth',meanLW);

    leg = legend([hLHS hRHS hLHM hRHM], ...
        {'LH individual data','RH individual data','LH mean','RH mean'}, ...
        'Location','southoutside', ...
        'Orientation','vertical');
    leg.Box = 'on';
    leg.LineWidth = 0.5;
    leg.FontSize = 21;

    % increase legend token width so the dashed RH mean is clearly visible
    leg.ItemTokenSize = [50 18];
end

%% HYPOTHESIS 2: GENERAL LATERALIZATION

% create third panel containing both experimental groups
nexttile; hold on

% extract general lateralization values for MVF and Sham participants
mt1 = [S(idx_mt).LHminusRHMI1]';
mt2 = [S(idx_mt).LHminusRHMI2]';
sh1 = [S(idx_sh).LHminusRHMI1]';
sh2 = [S(idx_sh).LHminusRHMI2]';

% plot half-violin distributions
% MVF group is displayed on the left and Sham group on the right
half_violin(1, mt1, "left",  col.mt_lat)
half_violin(1, sh1, "right", col.sh_lat)
half_violin(2, mt2, "left",  col.mt_lat)
half_violin(2, sh2, "right", col.sh_lat)

% generate jittered x-positions while keeping MVF values on the left and
% Sham values on the right of each session position
x1_mt = 1 - 0.08 + (rand(numel(mt1),1)-0.5)*2*jit;
x2_mt = 2 - 0.08 + (rand(numel(mt2),1)-0.5)*2*jit;

x1_sh = 1 + 0.08 + (rand(numel(sh1),1)-0.5)*2*jit;
x2_sh = 2 + 0.08 + (rand(numel(sh2),1)-0.5)*2*jit;

% plot individual MVF participant trajectories and endpoints
for i = 1:numel(mt1)
    plot([x1_mt(i) x2_mt(i)], [mt1(i) mt2(i)], '-', ...
        'Color', tintInd(col.mt_lat), 'LineWidth',lwInd, 'HandleVisibility','off');

    scatter([x1_mt(i) x2_mt(i)], [mt1(i) mt2(i)], 18, 'filled', ...
        'MarkerFaceColor', tintInd(col.mt_lat), 'MarkerFaceAlpha', 1, ...
        'MarkerEdgeColor','none', 'HandleVisibility','off');
end

% plot individual Sham participant trajectories and endpoints
for i = 1:numel(sh1)
    plot([x1_sh(i) x2_sh(i)], [sh1(i) sh2(i)], '-', ...
        'Color', tintInd(col.sh_lat), 'LineWidth',lwInd, 'HandleVisibility','off');

    scatter([x1_sh(i) x2_sh(i)], [sh1(i) sh2(i)], 18, 'filled', ...
        'MarkerFaceColor', tintInd(col.sh_lat), 'MarkerFaceAlpha', 1, ...
        'MarkerEdgeColor','none', 'HandleVisibility','off');
end

% calculate group means for both sessions
m_mt = [mean(mt1,'omitnan') mean(mt2,'omitnan')];
m_sh = [mean(sh1,'omitnan') mean(sh2,'omitnan')];

% position MVF means on the left and Sham means on the right
xMean_mt = [1-0.08 2-0.08];
xMean_sh = [1+0.08 2+0.08];

% plot group mean trajectories
plot(xMean_mt, m_mt, '-', 'Color', col.mt_lat, 'LineWidth',meanLW, 'HandleVisibility','off');
plot(xMean_sh, m_sh, '-', 'Color', col.sh_lat, 'LineWidth',meanLW, 'HandleVisibility','off');

% plot group mean endpoints
scatter(xMean_mt, m_mt, 70, 'filled', ...
    'MarkerFaceColor', col.mt_lat, 'MarkerEdgeColor','w', ...
    'LineWidth',0.8, 'HandleVisibility','off');
scatter(xMean_sh, m_sh, 70, 'filled', ...
    'MarkerFaceColor', col.sh_lat, 'MarkerEdgeColor','w', ...
    'LineWidth',0.8, 'HandleVisibility','off');

% format axes
xlim([0.5 2.5])
ylim(yl4)
xticks([1 2])
xticklabels({'MI1','MI2'})
xlabel('MI session', 'FontSize',24)
ylabel('Mu ERD/ERS lateralization [%] (LH - RH)', 'FontSize',24)
box off
ax = gca;
ax.FontSize = 22;

% create legend handles for individual and mean trajectories
h1 = plot(nan,nan,'-','Color',tintInd(col.mt_lat),'LineWidth',lwInd);
h2 = plot(nan,nan,'-','Color',tintInd(col.sh_lat),'LineWidth',lwInd);
h3 = plot(nan,nan,'-','Color',col.mt_lat,'LineWidth',meanLW);
h4 = plot(nan,nan,'-','Color',col.sh_lat,'LineWidth',meanLW);

leg = legend([h1 h2 h3 h4], ...
    {'MVF group individual data', ...
    'Sham group individual data', ...
    'MVF group mean', ...
    'Sham group mean'}, ...
    'Location','southoutside', ...
    'Orientation','vertical');

leg.Box = 'on';
leg.LineWidth = 0.5;
leg.FontSize = 21;

%% SAVE FIGURE

% save combined publication figure at high resolution
fileName = ['Hyp1_Hyp2_general_combined', '.png'];
fullFilePath = fullfile(PATHOUT, fileName);
exportgraphics(gcf, fullFilePath, 'Resolution', 300);

