%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana09_timecourseERD_4cond.m
%
% This script visualizes the temporal course of mu-band ERD/ERS (8-12 Hz)
% for the four group x session conditions.
%
% The following steps are performed:
%           - Load the subject-level time-frequency ERD/ERS data
%           - Extract the mu-band (8-12 Hz) time course from the
%             sensorimotor average for each dataset
%           - Separate the time courses by group (MVF, sham) and session
%             (MI1, MI2)
%           - Compute the mean and 95% confidence interval across
%             participants for each condition
%           - Plot all four condition means with 95% confidence intervals
%           - Mark the baseline and predefined analysis window
%           - Save the resulting time-course figure
%
% Input:    - time_frequency_data_struct.mat:
%             Subject-level ERD/ERS time-frequency matrices including
%             the sensorimotor average (sensm_avg)
%           - frequencies.mat:
%             Frequency vector (freqs_check)
%           - times.mat:
%             Time vector (times_check)
%
% Output:   - muERD_timecourse_4cond_CI95_grey.png:
%             Mu-band ERD/ERS time courses for all four group x session
%             conditions with 95% confidence intervals
%
% Linn Schwarz 26/02/2026
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DIRECTORIES

clear; close all;

% execute this script from within the 'scripts' folder
MAINPATH = fileparts(pwd);
PATHIN1  = fullfile(MAINPATH,'data','lis05',filesep);      % frequency and time vectors  
PATHIN2  = fullfile(MAINPATH,'data','lis06',filesep);      % time-frequency data    
PATHOUT = fullfile(MAINPATH, 'data','lis09',filesep);      % path for script output

% create output folder if it does not exist yet
if ~exist(PATHOUT)
    mkdir(PATHOUT);
end

% load frequency and time vectors
cd(PATHIN1)
load('frequencies.mat')
load('times.mat')

% load subject-level time-frequency ERD/ERS data
cd(PATHIN2)
load('time_frequency_data_struct.mat')

%% ANALYSIS SETTINGS

% define mu frequency band and time windows
muBand   = [8 12];              % Hz
baseWin  = [-1000 -500];        % ms (for shading only)
anaWin   = [500 2500];          % ms (for shading only)

% define group colors
col.mt = [0.2 0.6 0.85];   % MVF group
col.sh = [0.85 0.3 0.3];   % sham group

%% EXTRACT SUBJECT-LEVEL MU ERD/ERS TIME COURSES

% identify frequency bins corresponding to the mu band
mu_idx = freqs_check >= muBand(1) & freqs_check <= muBand(2);

% initialize condition-specific matrices
% rows = participants/datasets; columns = time points
tc_mt_MI1 = [];
tc_mt_MI2 = [];
tc_sh_MI1 = [];
tc_sh_MI2 = [];

% loop over datasets
for s = 1:numel(time_frequency_data)

    % extract sensorimotor ERD/ERS matrix (frequency x time)
    M = time_frequency_data(s).sensm_avg;  % 61 x 200 (freq x time)

    % verify expected matrix dimensions
    if isempty(M) || any(size(M) ~= [numel(freqs_check), numel(times_check)])
        error('Unexpected matrix size at entry %d.', s);
    end

    % average across mu-band frequencies to obtain one time course per dataset
    tc = mean(M(mu_idx,:), 1);

    % obtain group and session information
    grp = time_frequency_data(s).group;
    ses = time_frequency_data(s).session;

    % assign time course to corresponding group x session condition
    if strcmp(grp,'mt') && strcmp(ses,'MI1')
        tc_mt_MI1(end+1,:) = tc;
    elseif strcmp(grp,'mt') && strcmp(ses,'MI2')
        tc_mt_MI2(end+1,:) = tc;
    elseif strcmp(grp,'sh') && strcmp(ses,'MI1')
        tc_sh_MI1(end+1,:) = tc;
    elseif strcmp(grp,'sh') && strcmp(ses,'MI2')
        tc_sh_MI2(end+1,:) = tc;
    end
end

%% COMPUTE CONDITION MEANS AND 95% CONFIDENCE INTERVALS

% compute condition mean and two-sided 95% confidence interval across
% participants using the Student's t distribution
% ci95 represents the distance from the mean to each confidence limit
compute_mean_ci95 = @(X) deal( ...
    mean(X, 1, 'omitnan'), ...
    tinv(0.975, size(X,1)-1) .* ...
    std(X, 0, 1, 'omitnan') ./ sqrt(size(X,1)) ...
    );

[m_mt_MI1, ci95_mt_MI1] = compute_mean_ci95(tc_mt_MI1);
[m_mt_MI2, ci95_mt_MI2] = compute_mean_ci95(tc_mt_MI2);
[m_sh_MI1, ci95_sh_MI1] = compute_mean_ci95(tc_sh_MI1);
[m_sh_MI2, ci95_sh_MI2] = compute_mean_ci95(tc_sh_MI2);

%% CREATE MU ERD/ERS TIME-COURSE FIGURE

% create figure
figure('Position',[100 100 1100 550]);
hold on;

% define helper function for confidence-interval shading
shadeCI = @(x,m,ci,c,alphaVal) ...
    patch([x fliplr(x)], ...
          [m-ci fliplr(m+ci)], ...
          c, ...
          'EdgeColor','none', ...
          'FaceAlpha',alphaVal, ...
          'HandleVisibility','off');

% plot condition means
% color indicates group; line style indicates session
h_sh_MI1 = plot(times_check, m_sh_MI1, '-',  'Color', col.sh, 'LineWidth', 1.3, 'DisplayName','Sham Group MI1');
h_sh_MI2 = plot(times_check, m_sh_MI2, '--', 'Color', col.sh, 'LineWidth', 1.3, 'DisplayName','Sham Group MI2');
h_mt_MI1 = plot(times_check, m_mt_MI1, '-',  'Color', col.mt, 'LineWidth', 1.3, 'DisplayName','MVF Group MI1');
h_mt_MI2 = plot(times_check, m_mt_MI2, '--', 'Color', col.mt, 'LineWidth', 1.3, 'DisplayName','MVF Group MI2');

% set plotting limits
ylim([-45 85]);
xlim([-2000 8000])

% add baseline and analysis-window shading
hBase = patch([baseWin(1) baseWin(2) baseWin(2) baseWin(1)], ...
              [-45 -45 85 85], [0.4 0.4 0.4], ...
              'EdgeColor','none', 'FaceAlpha',0.3, ...
              'DisplayName',sprintf('Baseline (%d to %d ms)', baseWin(1), baseWin(2)));

hAna  = patch([anaWin(1) anaWin(2) anaWin(2) anaWin(1)], ...
              [-45 -45 85 85], [0.6 0.6 0.6], ...
              'EdgeColor','none', 'FaceAlpha',0.2, ...
              'DisplayName',sprintf('Analysis window (%d to %d ms)', anaWin(1), anaWin(2)));

% move time-window shading behind the time courses
uistack(hBase,'bottom');
uistack(hAna,'bottom');

% add 95% confidence intervals
shadeCI(times_check, m_sh_MI1, ci95_sh_MI1, col.sh, 0.12);
shadeCI(times_check, m_sh_MI2, ci95_sh_MI2, col.sh, 0.08);
shadeCI(times_check, m_mt_MI1, ci95_mt_MI1, col.mt, 0.12);
shadeCI(times_check, m_mt_MI2, ci95_mt_MI2, col.mt, 0.08);

% mark motor imagery onset and offset and zero ERD/ERS
xline(0,'--k','HandleVisibility','off');       % MI onset
xline(6000,'--k','HandleVisibility','off');    % MI end
yline(0, '-k', 'HandleVisibility','off');      % 0 line ERD/ERS

% bring condition means to the foreground
uistack([h_sh_MI1 h_sh_MI2 h_mt_MI1 h_mt_MI2],'top');

%% FIGURE FORMATTING

% define font sizes
fontSizeAxes   = 15;   % axes
fontSizeLabels = 17;   % xlabel and ylabel
fontSizeLegend = 14;   % legend

% format axes
ax = gca;
ax.FontSize = fontSizeAxes;
ax.LineWidth = 1.1;

xlabel('Time [ms]', ...
       'FontSize', fontSizeLabels);

ylabel('Mu ERD/ERS [%]', ...
       'FontSize', fontSizeLabels);

grid on;

% add legend
lgd = legend([hAna hBase h_mt_MI1 h_mt_MI2 h_sh_MI1 h_sh_MI2], ...
       {'Analysis window (500 to 2500 ms)', ...
        'Baseline (-1000 to -500 ms)', ...
        'MVF Group MI1', ...
        'MVF Group MI2', ...
        'Sham Group MI1', ...
        'Sham Group MI2'}, ...
       'Location','northwest');

lgd.FontSize = fontSizeLegend;

%% SAVE FIGURE

% save mu ERD/ERS time-course figure
fileName = 'muERD_timecourse_4cond_CI95_grey.png';
exportgraphics(gcf, fullfile(PATHOUT, fileName), ...
    'Resolution', 600);

% return to scripts folder
cd(fullfile(MAINPATH, 'scripts', filesep));

% end of script
