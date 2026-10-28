%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana08_1_raincloudplots.m
%
% This script visualizes participant-level mu-band ERD/ERS and hemispheric
% lateralization measures for the MVF and Sham groups across MI1 and MI2
% using raincloud-style plots.
%
% The following steps are performed:
%           - Load participant-level ERD/ERS and lateralization measures
%           - Plot left- and right-hemisphere mu ERD/ERS
%           - Plot general, central, and parieto-central lateralization
%           - Plot the corresponding normalized lateralization indices
%           - Save all figures as high-resolution PNG files
%
% Input:    - stat_input.mat
%
% Output:   - Hyp1.png
%           - Hyp2_general.png
%           - Hyp2_C.png
%           - Hyp2_PC.png
%           - Hyp2_general_LI.png
%           - Hyp2_C_LI.png
%           - Hyp2_PC_LI.png
%
% Note:     Due to the shifted EEG cap configuration, FC1/FC2 are interpreted
%           as central electrodes and C3/C4 as parieto-central electrodes.
%
% Linn Schwarz 28/01/2026
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DIRECTORIES

clear; close all; clc;

% execute this script from within the 'scripts' folder
MAINPATH = fileparts(pwd);
PATHIN  = fullfile(MAINPATH,'data','lis07_8-12Hz_500-2500ms_LI',filesep);
PATHOUT = fullfile(MAINPATH,'data','lis08_8-12Hz_500-2500ms_LI',filesep);

% create output directory if it does not exist
if ~exist(PATHOUT,'dir')
    mkdir(PATHOUT);
end

%% LOAD DATA

% load participant-level ERD/ERS and lateralization measures generated
% in lis_ana07_1_pre_stat.m
cd(PATHIN)
load('stat_input.mat')

% return to scripts folder
cd(fullfile(MAINPATH,'scripts'));

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
blend = @(c,w) c + (1-c)*w;

% define hemisphere-specific shades
% left hemisphere = darker; right hemisphere = lighter
col.mt_LH = blend(col.mt_base,0.00);
col.mt_RH = blend(col.mt_base,0.55);

col.sh_LH = blend(col.sh_base,0.00);
col.sh_RH = blend(col.sh_base,0.55);

% define group colors used for lateralization measures
col.mt_lat = blend(col.mt_base,0.10);
col.sh_lat = blend(col.sh_base,0.10);

% generate light group-specific colors for individual participant lines
tint = @(c) blend(c,0.70);


%% HYPOTHESIS 1: LEFT- AND RIGHT-HEMISPHERE MU ERD/ERS

% combine all ERD/ERS values to determine common y-axis limits across
% groups, hemispheres, and motor imagery sessions
Y2 = [ ...
    [S(idx_mt).LHMI1]'; [S(idx_mt).LHMI2]'; ...
    [S(idx_mt).RHMI1]'; [S(idx_mt).RHMI2]'; ...
    [S(idx_sh).LHMI1]'; [S(idx_sh).LHMI2]'; ...
    [S(idx_sh).RHMI1]'; [S(idx_sh).RHMI2]' ...
];

% exclude missing values before calculating axis limits
Y2 = Y2(~isnan(Y2));

% determine common y-axis limits with additional padding
dataMin   = min(Y2);
dataMax   = max(Y2);
dataRange = dataMax - dataMin;
pad       = max(0.2 * dataRange,12);
yl2       = [dataMin-pad, dataMax+pad];

% create one panel for each experimental group
figure('Color','w','Units','pixels','Position',[100 100 1100 520]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

for g = 1:2

    ax = nexttile;
    hold(ax,'on');

    % select participants belonging to the current group
    idx = grp == groups(g);

    % select group-specific colors for the two hemispheres
    if groups(g) == "mt"
        cLH = col.mt_LH;
        cRH = col.mt_RH;
    else
        cLH = col.sh_LH;
        cRH = col.sh_RH;
    end

    % extract left- and right-hemisphere ERD/ERS values for both sessions
    LH1 = [S(idx).LHMI1]';
    LH2 = [S(idx).LHMI2]';
    RH1 = [S(idx).RHMI1]';
    RH2 = [S(idx).RHMI2]';

    % plot half-violin distributions for both hemispheres and sessions
    half_violin(1,LH1,"left",cLH)
    half_violin(1,RH1,"right",cRH)
    half_violin(2,LH2,"left",cLH)
    half_violin(2,RH2,"right",cRH)

    % generate jittered x-positions for individual participant values
    x1_LH = 1 + (rand(numel(LH1),1)-0.5)*2*jit;
    x2_LH = 2 + (rand(numel(LH1),1)-0.5)*2*jit;
    x1_RH = 1 + (rand(numel(RH1),1)-0.5)*2*jit;
    x2_RH = 2 + (rand(numel(RH1),1)-0.5)*2*jit;

    % plot individual participant trajectories and endpoints
    for i = 1:numel(LH1)

        plot([x1_LH(i) x2_LH(i)],[LH1(i) LH2(i)],'-', ...
            'Color',tint(cLH),'LineWidth',1,'HandleVisibility','off');

        plot([x1_RH(i) x2_RH(i)],[RH1(i) RH2(i)],'-', ...
            'Color',tint(cRH),'LineWidth',1,'HandleVisibility','off');

        scatter([x1_LH(i) x2_LH(i)],[LH1(i) LH2(i)],18,'filled', ...
            'MarkerFaceColor',cLH,'MarkerFaceAlpha',0.55, ...
            'MarkerEdgeColor','none','HandleVisibility','off');

        scatter([x1_RH(i) x2_RH(i)],[RH1(i) RH2(i)],18,'filled', ...
            'MarkerFaceColor',cRH,'MarkerFaceAlpha',0.55, ...
            'MarkerEdgeColor','none','HandleVisibility','off');
    end

    % calculate group means for both hemispheres and sessions
    mLH = [mean(LH1,'omitnan') mean(LH2,'omitnan')];
    mRH = [mean(RH1,'omitnan') mean(RH2,'omitnan')];

    % plot mean trajectories and endpoints
    plot([1 2],mLH,'-','Color',cLH,'LineWidth',3, ...
        'HandleVisibility','off');

    plot([1 2],mRH,'-','Color',cRH,'LineWidth',3, ...
        'HandleVisibility','off');

    scatter([1 2],mLH,70,'filled', ...
        'MarkerFaceColor',cLH,'MarkerEdgeColor','w', ...
        'LineWidth',0.8,'HandleVisibility','off');

    scatter([1 2],mRH,70,'filled', ...
        'MarkerFaceColor',cRH,'MarkerEdgeColor','w', ...
        'LineWidth',0.8,'HandleVisibility','off');

    % format axes
    title(groups_MA(g))
    xlim([0.5 2.5])
    ylim(yl2)
    xticks([1 2])
    xticklabels({'MI1','MI2'})
    xlabel('MI Session')
    box off

    % display y-axis label only in the left panel
    if g == 1
        ylabel('Mu ERD/ERS [%]')
    end

    % create legend handles representing individual and mean trajectories
    hLHS = plot(nan,nan,'-','Color',cLH,'LineWidth',1);
    hRHS = plot(nan,nan,'-','Color',cRH,'LineWidth',1);
    hLHM = plot(nan,nan,'-','Color',cLH,'LineWidth',3);
    hRHM = plot(nan,nan,'-','Color',cRH,'LineWidth',3);

    leg = legend([hLHS hRHS hLHM hRHM], ...
        {'LH individual data','RH individual data','LH mean','RH mean'}, ...
        'Location','northeastoutside');

    leg.Box = 'on';
    leg.LineWidth = 0.5;
end

% save left- and right-hemisphere ERD/ERS figure
fileName = 'Hyp1.png';
exportgraphics(gcf,fullfile(PATHOUT,fileName),'Resolution',300);


%% HYPOTHESIS 2: GENERAL LATERALIZATION

% combine general lateralization values to determine common y-axis limits
% across groups and motor imagery sessions
Y4 = [ ...
    [S(idx_mt).LHminusRHMI1]'; [S(idx_mt).LHminusRHMI2]'; ...
    [S(idx_sh).LHminusRHMI1]'; [S(idx_sh).LHminusRHMI2]' ...
];

% exclude missing values before calculating axis limits
Y4 = Y4(~isnan(Y4));

% determine common y-axis limits with additional padding
dataMin   = min(Y4);
dataMax   = max(Y4);
dataRange = dataMax - dataMin;
pad       = max(0.2 * dataRange,12);
yl4       = [dataMin-pad, dataMax+pad];

% create one panel for each experimental group
figure('Color','w','Units','pixels','Position',[130 130 1100 520]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

for g = 1:2

    ax = nexttile;
    hold(ax,'on');

    % select participants belonging to the current group
    idx = grp == groups(g);

    % select group-specific lateralization color
    if groups(g) == "mt"
        c = col.mt_lat;
    else
        c = col.sh_lat;
    end

    % extract general lateralization values for both sessions
    y1 = [S(idx).LHminusRHMI1]';
    y2 = [S(idx).LHminusRHMI2]';

    % plot half-violin distributions
    half_violin(1,y1,"left",c)
    half_violin(2,y2,"left",c)

    % generate jittered x-positions for individual participant values
    x1 = 1 + (rand(numel(y1),1)-0.5)*2*jit;
    x2 = 2 + (rand(numel(y2),1)-0.5)*2*jit;

    % plot individual participant trajectories and endpoints
    for i = 1:numel(y1)

        plot([x1(i) x2(i)],[y1(i) y2(i)],'-', ...
            'Color',tint(c),'LineWidth',1,'HandleVisibility','off');

        scatter([x1(i) x2(i)],[y1(i) y2(i)],18,'filled', ...
            'MarkerFaceColor',c,'MarkerFaceAlpha',0.55, ...
            'MarkerEdgeColor','none','HandleVisibility','off');
    end

    % calculate and plot group mean trajectory
    m = [mean(y1,'omitnan') mean(y2,'omitnan')];

    plot([1 2],m,'-','Color',c,'LineWidth',3, ...
        'HandleVisibility','off');

    scatter([1 2],m,70,'filled', ...
        'MarkerFaceColor',c,'MarkerEdgeColor','w','LineWidth',0.8, ...
        'HandleVisibility','off');

    % format axes
    title(groups_MA(g))
    xlim([0.5 2.5])
    ylim(yl4)
    xticks([1 2])
    xticklabels({'MI1','MI2'})
    xlabel('MI Session')
    box off

    % display y-axis label only in the left panel
    if g == 1
        ylabel('Mu ERD/ERS lateralization [%] (LH - RH)')
    end

    % create legend handles for individual and mean trajectories
    hSingle = plot(nan,nan,'-','Color',tint(c),'LineWidth',1);
    hMean   = plot(nan,nan,'-','Color',c,'LineWidth',3);

    leg = legend([hSingle hMean],{'Individual data','Mean'}, ...
        'Location','northeastoutside');

    leg.Box = 'on';
    leg.LineWidth = 0.5;
end

% save general lateralization figure
fileName = 'Hyp2_general.png';
exportgraphics(gcf,fullfile(PATHOUT,fileName),'Resolution',300);


%% HYPOTHESIS 2: CENTRAL LATERALIZATION

% combine central left-right differences to determine common y-axis limits
% across groups and motor imagery sessions
Y4 = [ ...
    [S(idx_mt).FC1minusFC2MI1]'; [S(idx_mt).FC1minusFC2MI2]'; ...
    [S(idx_sh).FC1minusFC2MI1]'; [S(idx_sh).FC1minusFC2MI2]' ...
];

% exclude missing values before calculating axis limits
Y4 = Y4(~isnan(Y4));

% determine common y-axis limits with additional padding
dataMin   = min(Y4);
dataMax   = max(Y4);
dataRange = dataMax - dataMin;
pad       = max(0.2 * dataRange,12);
yl4       = [dataMin-pad, dataMax+pad];

% create one panel for each experimental group
figure('Color','w','Units','pixels','Position',[130 130 1100 520]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

for g = 1:2

    ax = nexttile;
    hold(ax,'on');

    % select participants belonging to the current group
    idx = grp == groups(g);

    % select group-specific lateralization color
    if groups(g) == "mt"
        c = col.mt_lat;
    else
        c = col.sh_lat;
    end

    % extract central left-right differences for both sessions
    y1 = [S(idx).FC1minusFC2MI1]';
    y2 = [S(idx).FC1minusFC2MI2]';

    % plot half-violin distributions
    half_violin(1,y1,"left",c)
    half_violin(2,y2,"left",c)

    % generate jittered x-positions for individual participant values
    x1 = 1 + (rand(numel(y1),1)-0.5)*2*jit;
    x2 = 2 + (rand(numel(y2),1)-0.5)*2*jit;

    % plot individual participant trajectories and endpoints
    for i = 1:numel(y1)

        plot([x1(i) x2(i)],[y1(i) y2(i)],'-', ...
            'Color',tint(c),'LineWidth',1,'HandleVisibility','off');

        scatter([x1(i) x2(i)],[y1(i) y2(i)],18,'filled', ...
            'MarkerFaceColor',c,'MarkerFaceAlpha',0.55, ...
            'MarkerEdgeColor','none','HandleVisibility','off');
    end

    % calculate and plot group mean trajectory
    m = [mean(y1,'omitnan') mean(y2,'omitnan')];

    plot([1 2],m,'-','Color',c,'LineWidth',3, ...
        'HandleVisibility','off');

    scatter([1 2],m,70,'filled', ...
        'MarkerFaceColor',c,'MarkerEdgeColor','w','LineWidth',0.8, ...
        'HandleVisibility','off');

    % format axes
    title(groups_MA(g))
    xlim([0.5 2.5])
    ylim(yl4)
    xticks([1 2])
    xticklabels({'MI1','MI2'})
    xlabel('MI Session')
    box off

    % display y-axis label only in the left panel
    if g == 1
        ylabel('Mu ERD/ERS lateralization [%] (left central - right central)')
    end

    % create legend handles for individual and mean trajectories
    hSingle = plot(nan,nan,'-','Color',tint(c),'LineWidth',1);
    hMean   = plot(nan,nan,'-','Color',c,'LineWidth',3);

    leg = legend([hSingle hMean],{'Individual data','Mean'}, ...
        'Location','northeastoutside');

    leg.Box = 'on';
    leg.LineWidth = 0.5;
end

% save central lateralization figure
fileName = 'Hyp2_C.png';
exportgraphics(gcf,fullfile(PATHOUT,fileName),'Resolution',300);


%% HYPOTHESIS 2: PARIETO-CENTRAL LATERALIZATION

% combine parieto-central left-right differences to determine common
% y-axis limits across groups and motor imagery sessions
Y4 = [ ...
    [S(idx_mt).C3minusC4MI1]'; [S(idx_mt).C3minusC4MI2]'; ...
    [S(idx_sh).C3minusC4MI1]'; [S(idx_sh).C3minusC4MI2]' ...
];

% exclude missing values before calculating axis limits
Y4 = Y4(~isnan(Y4));

% determine common y-axis limits with additional padding
dataMin   = min(Y4);
dataMax   = max(Y4);
dataRange = dataMax - dataMin;
pad       = max(0.2 * dataRange,12);
yl4       = [dataMin-pad, dataMax+pad];

% create one panel for each experimental group
figure('Color','w','Units','pixels','Position',[130 130 1100 520]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

for g = 1:2

    ax = nexttile;
    hold(ax,'on');

    % select participants belonging to the current group
    idx = grp == groups(g);

    % select group-specific lateralization color
    if groups(g) == "mt"
        c = col.mt_lat;
    else
        c = col.sh_lat;
    end

    % extract parieto-central left-right differences for both sessions
    y1 = [S(idx).C3minusC4MI1]';
    y2 = [S(idx).C3minusC4MI2]';

    % plot half-violin distributions
    half_violin(1,y1,"left",c)
    half_violin(2,y2,"left",c)

    % generate jittered x-positions for individual participant values
    x1 = 1 + (rand(numel(y1),1)-0.5)*2*jit;
    x2 = 2 + (rand(numel(y2),1)-0.5)*2*jit;

    % plot individual participant trajectories and endpoints
    for i = 1:numel(y1)

        plot([x1(i) x2(i)],[y1(i) y2(i)],'-', ...
            'Color',tint(c),'LineWidth',1,'HandleVisibility','off');

        scatter([x1(i) x2(i)],[y1(i) y2(i)],18,'filled', ...
            'MarkerFaceColor',c,'MarkerFaceAlpha',0.55, ...
            'MarkerEdgeColor','none','HandleVisibility','off');
    end

    % calculate and plot group mean trajectory
    m = [mean(y1,'omitnan') mean(y2,'omitnan')];

    plot([1 2],m,'-','Color',c,'LineWidth',3, ...
        'HandleVisibility','off');

    scatter([1 2],m,70,'filled', ...
        'MarkerFaceColor',c,'MarkerEdgeColor','w','LineWidth',0.8, ...
        'HandleVisibility','off');

    % format axes
    title(groups_MA(g))
    xlim([0.5 2.5])
    ylim(yl4)
    xticks([1 2])
    xticklabels({'MI1','MI2'})
    xlabel('MI Session')
    box off

    % display y-axis label only in the left panel
    if g == 1
        ylabel('Mu ERD/ERS lateralization [%] (left parieto-central - right parieto-central)')
    end

    % create legend handles for individual and mean trajectories
    hSingle = plot(nan,nan,'-','Color',tint(c),'LineWidth',1);
    hMean   = plot(nan,nan,'-','Color',c,'LineWidth',3);

    leg = legend([hSingle hMean],{'Individual data','Mean'}, ...
        'Location','northeastoutside');

    leg.Box = 'on';
    leg.LineWidth = 0.5;
end

% save parieto-central lateralization figure
fileName = 'Hyp2_PC.png';
exportgraphics(gcf,fullfile(PATHOUT,fileName),'Resolution',300);


%% HYPOTHESIS 2: GENERAL LATERALIZATION INDEX

% combine general lateralization indices to determine common y-axis limits
% across groups and motor imagery sessions
Y4 = [ ...
    [S(idx_mt).LIgenMI1]'; [S(idx_mt).LIgenMI2]'; ...
    [S(idx_sh).LIgenMI1]'; [S(idx_sh).LIgenMI2]' ...
];

% exclude missing values before calculating axis limits
Y4 = Y4(~isnan(Y4));

% determine common y-axis limits using padding appropriate for LI values
dataMin   = min(Y4);
dataMax   = max(Y4);
dataRange = dataMax - dataMin;
pad       = max(0.08 * dataRange,2);
yl4       = [dataMin-pad, dataMax+pad];

% create one panel for each experimental group
figure('Color','w','Units','pixels','Position',[130 130 1100 520]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

for g = 1:2

    ax = nexttile;
    hold(ax,'on');

    % select participants belonging to the current group
    idx = grp == groups(g);

    % select group-specific lateralization color
    if groups(g) == "mt"
        c = col.mt_lat;
    else
        c = col.sh_lat;
    end

    % extract general lateralization indices for both sessions
    y1 = [S(idx).LIgenMI1]';
    y2 = [S(idx).LIgenMI2]';

    % plot half-violin distributions
    half_violin(1,y1,"left",c)
    half_violin(2,y2,"left",c)

    % generate jittered x-positions for individual participant values
    x1 = 1 + (rand(numel(y1),1)-0.5)*2*jit;
    x2 = 2 + (rand(numel(y2),1)-0.5)*2*jit;

    % plot individual participant trajectories and endpoints
    for i = 1:numel(y1)

        plot([x1(i) x2(i)],[y1(i) y2(i)],'-', ...
            'Color',tint(c),'LineWidth',1,'HandleVisibility','off');

        scatter([x1(i) x2(i)],[y1(i) y2(i)],18,'filled', ...
            'MarkerFaceColor',c,'MarkerFaceAlpha',0.55, ...
            'MarkerEdgeColor','none','HandleVisibility','off');
    end

    % calculate and plot group mean trajectory
    m = [mean(y1,'omitnan') mean(y2,'omitnan')];

    plot([1 2],m,'-','Color',c,'LineWidth',3, ...
        'HandleVisibility','off');

    scatter([1 2],m,70,'filled', ...
        'MarkerFaceColor',c,'MarkerEdgeColor','w','LineWidth',0.8, ...
        'HandleVisibility','off');

    % format axes
    title(groups_MA(g))
    xlim([0.5 2.5])
    ylim(yl4)
    xticks([1 2])
    xticklabels({'MI1','MI2'})
    xlabel('MI Session')
    box off

    % display y-axis label only in the left panel
    if g == 1
        ylabel('Mu LI (central and parieto-central electrodes)')
    end

    % create legend handles for individual and mean trajectories
    hSingle = plot(nan,nan,'-','Color',tint(c),'LineWidth',1);
    hMean   = plot(nan,nan,'-','Color',c,'LineWidth',3);

    leg = legend([hSingle hMean],{'Individual data','Mean'}, ...
        'Location','northeastoutside');

    leg.Box = 'on';
    leg.LineWidth = 0.5;
end

% save general lateralization-index figure
fileName = 'Hyp2_general_LI.png';
exportgraphics(gcf,fullfile(PATHOUT,fileName),'Resolution',300);


%% HYPOTHESIS 2: CENTRAL LATERALIZATION INDEX

% combine central lateralization indices to determine common y-axis limits
% across groups and motor imagery sessions
Y4 = [ ...
    [S(idx_mt).LIcenMI1]'; [S(idx_mt).LIcenMI2]'; ...
    [S(idx_sh).LIcenMI1]'; [S(idx_sh).LIcenMI2]' ...
];

% exclude missing values before calculating axis limits
Y4 = Y4(~isnan(Y4));

% determine common y-axis limits using padding appropriate for LI values
dataMin   = min(Y4);
dataMax   = max(Y4);
dataRange = dataMax - dataMin;
pad       = max(0.08 * dataRange,2);
yl4       = [dataMin-pad, dataMax+pad];

% create one panel for each experimental group
figure('Color','w','Units','pixels','Position',[130 130 1100 520]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

for g = 1:2

    ax = nexttile;
    hold(ax,'on');

    % select participants belonging to the current group
    idx = grp == groups(g);

    % select group-specific lateralization color
    if groups(g) == "mt"
        c = col.mt_lat;
    else
        c = col.sh_lat;
    end

    % extract central lateralization indices for both sessions
    y1 = [S(idx).LIcenMI1]';
    y2 = [S(idx).LIcenMI2]';

    % plot half-violin distributions
    half_violin(1,y1,"left",c)
    half_violin(2,y2,"left",c)

    % generate jittered x-positions for individual participant values
    x1 = 1 + (rand(numel(y1),1)-0.5)*2*jit;
    x2 = 2 + (rand(numel(y2),1)-0.5)*2*jit;

    % plot individual participant trajectories and endpoints
    for i = 1:numel(y1)

        plot([x1(i) x2(i)],[y1(i) y2(i)],'-', ...
            'Color',tint(c),'LineWidth',1,'HandleVisibility','off');

        scatter([x1(i) x2(i)],[y1(i) y2(i)],18,'filled', ...
            'MarkerFaceColor',c,'MarkerFaceAlpha',0.55, ...
            'MarkerEdgeColor','none','HandleVisibility','off');
    end

    % calculate and plot group mean trajectory
    m = [mean(y1,'omitnan') mean(y2,'omitnan')];

    plot([1 2],m,'-','Color',c,'LineWidth',3, ...
        'HandleVisibility','off');

    scatter([1 2],m,70,'filled', ...
        'MarkerFaceColor',c,'MarkerEdgeColor','w','LineWidth',0.8, ...
        'HandleVisibility','off');

    % format axes
    title(groups_MA(g))
    xlim([0.5 2.5])
    ylim(yl4)
    xticks([1 2])
    xticklabels({'MI1','MI2'})
    xlabel('MI Session')
    box off

    % display y-axis label only in the left panel
    if g == 1
        ylabel('Mu LI (central electrodes)')
    end

    % create legend handles for individual and mean trajectories
    hSingle = plot(nan,nan,'-','Color',tint(c),'LineWidth',1);
    hMean   = plot(nan,nan,'-','Color',c,'LineWidth',3);

    leg = legend([hSingle hMean],{'Individual data','Mean'}, ...
        'Location','northeastoutside');

    leg.Box = 'on';
    leg.LineWidth = 0.5;
end

% save central lateralization-index figure
fileName = 'Hyp2_C_LI.png';
exportgraphics(gcf,fullfile(PATHOUT,fileName),'Resolution',300);


%% HYPOTHESIS 2: PARIETO-CENTRAL LATERALIZATION INDEX

% combine parieto-central lateralization indices to determine common
% y-axis limits across groups and motor imagery sessions
Y4 = [ ...
    [S(idx_mt).LIpcenMI1]'; [S(idx_mt).LIpcenMI2]'; ...
    [S(idx_sh).LIpcenMI1]'; [S(idx_sh).LIpcenMI2]' ...
];

% exclude missing values before calculating axis limits
Y4 = Y4(~isnan(Y4));

% determine common y-axis limits using padding appropriate for LI values
dataMin   = min(Y4);
dataMax   = max(Y4);
dataRange = dataMax - dataMin;
pad       = max(0.08 * dataRange,2);
yl4       = [dataMin-pad, dataMax+pad];

% create one panel for each experimental group
figure('Color','w','Units','pixels','Position',[130 130 1100 520]);
tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

for g = 1:2

    ax = nexttile;
    hold(ax,'on');

    % select participants belonging to the current group
    idx = grp == groups(g);

    % select group-specific lateralization color
    if groups(g) == "mt"
        c = col.mt_lat;
    else
        c = col.sh_lat;
    end

    % extract parieto-central lateralization indices for both sessions
    y1 = [S(idx).LIpcenMI1]';
    y2 = [S(idx).LIpcenMI2]';

    % plot half-violin distributions
    half_violin(1,y1,"left",c)
    half_violin(2,y2,"left",c)

    % generate jittered x-positions for individual participant values
    x1 = 1 + (rand(numel(y1),1)-0.5)*2*jit;
    x2 = 2 + (rand(numel(y2),1)-0.5)*2*jit;

    % plot individual participant trajectories and endpoints
    for i = 1:numel(y1)

        plot([x1(i) x2(i)],[y1(i) y2(i)],'-', ...
            'Color',tint(c),'LineWidth',1,'HandleVisibility','off');

        scatter([x1(i) x2(i)],[y1(i) y2(i)],18,'filled', ...
            'MarkerFaceColor',c,'MarkerFaceAlpha',0.55, ...
            'MarkerEdgeColor','none','HandleVisibility','off');
    end

    % calculate and plot group mean trajectory
    m = [mean(y1,'omitnan') mean(y2,'omitnan')];

    plot([1 2],m,'-','Color',c,'LineWidth',3, ...
        'HandleVisibility','off');

    scatter([1 2],m,70,'filled', ...
        'MarkerFaceColor',c,'MarkerEdgeColor','w','LineWidth',0.8, ...
        'HandleVisibility','off');

    % format axes
    title(groups_MA(g))
    xlim([0.5 2.5])
    ylim(yl4)
    xticks([1 2])
    xticklabels({'MI1','MI2'})
    xlabel('MI Session')
    box off

    % display y-axis label only in the left panel
    if g == 1
        ylabel('Mu LI (parieto-central electrodes)')
    end

    % create legend handles for individual and mean trajectories
    hSingle = plot(nan,nan,'-','Color',tint(c),'LineWidth',1);
    hMean   = plot(nan,nan,'-','Color',c,'LineWidth',3);

    leg = legend([hSingle hMean],{'Individual data','Mean'}, ...
        'Location','northeastoutside');

    leg.Box = 'on';
    leg.LineWidth = 0.5;
end

% save parieto-central lateralization-index figure
fileName = 'Hyp2_PC_LI.png';
exportgraphics(gcf,fullfile(PATHOUT,fileName),'Resolution',300);


%% FINISH

% return to scripts folder
cd(fullfile(MAINPATH,'scripts',filesep));

% end of script