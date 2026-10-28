%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lis_ana06_1_tf_map.m
%
% This script visualizes the time-frequency ERD/ERS results at the
% single-subject and group level.
%
% For each dataset, ERD/ERS time-frequency matrices from four sensorimotor
% electrodes (FC1, FC2, C3, C4) are averaged to obtain an additional
% sensorimotor average. Subject-level time-frequency figures are then
% generated for the four individual electrodes and their average.
%
% Subsequently, grand-average time-frequency representations are computed
% across participants separately for each experimental group and motor
% imagery session.
%
% The following steps are performed:
%           - Load subject-level time-frequency ERD/ERS data from lis05
%           - Compute the sensorimotor average across FC1, FC2, C3, and C4
%             for each dataset
%           - Add the sensorimotor average (sensm_avg) to the data structure
%           - Generate subject-level time-frequency figures for each dataset
%             showing the four electrodes and their sensorimotor average
%           - Mark the predefined analysis window (8-12 Hz, 500-2500 ms)
%           - Compute grand-average ERD/ERS maps across participants
%             separately for group (mirror therapy, sham) and session
%             (MI1, MI2)
%           - Generate grand-average time-frequency figures for each
%             group x session condition
%           - Save the updated data structure and grand-average matrices
%
% Input:    - time_frequency_data_struct.mat:
%             Subject-level ERD/ERS time-frequency matrices and dataset
%             information
%           - frequencies.mat:
%             Frequency vector (freqs_check)
%           - times.mat:
%             Time vector (times_check)
%
% Output:   - time_frequency_data_struct.mat:
%             Updated structure including the sensorimotor average
%             (sensm_avg)
%           - Subject-level time-frequency figures for each dataset
%           - Grand-average time-frequency figures for each group x session
%             condition
%           - MI1_sh_GA.mat
%           - MI1_mt_GA.mat
%           - MI2_sh_GA.mat
%           - MI2_mt_GA.mat
%
% Adapted by Linn Schwarz 08/10/2025
% Linn Schwarz 26/11/2023
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DIRECTORIES

clear; close all;

% execute this script from within the 'scripts' folder
MAINPATH = fileparts(pwd);
PATHIN  = fullfile(MAINPATH,'data','lis05',filesep);      % path containing input data                   
PATHOUT = fullfile(MAINPATH, 'data','lis06',filesep);  % path for script output

% create output folder if it does not exist yet
if ~exist(PATHOUT)
    mkdir(PATHOUT);
end

% load subject-level time-frequency data, frequency vector, and time vector
cd(PATHIN)
load('time_frequency_data_struct.mat')
load('frequencies.mat')
load('times.mat')

%% FIGURE SETTINGS

% define figure dimensions
figW = 1200;  % px
figH = 650;   % px

%% COMPUTE SENSORIMOTOR AVERAGE AND CREATE SUBJECT-LEVEL FIGURES

% define electrodes of interest and corresponding structure fields
e_label = {'FC1','FC2','C3','C4'};
e_num = [21,22,5,6];

% fields to be visualized: four individual electrodes and their average
tf_all = {'FC1','FC2','C3','C4','sensm_avg'};
tf_all_name = {'Left central','Right central','Left centro-parietal','Right centro-parietal','Sensorimotor average'};

% loop over datasets
for s = 1:length(time_frequency_data)

    % initialize a 3-D matrix containing the time-frequency ERD/ERS data
    % from all four electrodes of interest (frequency x time x electrode)
    allElecData = zeros(size(time_frequency_data(s).(e_label{1}),1), ...
        size(time_frequency_data(s).(e_label{1}),2), ...
        length(e_label));

    % collect time-frequency data from the four electrodes
    for electrodeidx = 1:length(e_label)
        fld = e_label{electrodeidx};
        allElecData(:,:,electrodeidx) = time_frequency_data(s).(fld);
    end

    % compute mean ERD/ERS across the four sensorimotor electrodes
    sensm_avg = mean(allElecData, 3);

    % store sensorimotor average in the time-frequency data structure
    time_frequency_data(s).sensm_avg = sensm_avg;

    % create subject-level figure
    figure('Position',[100 100 figW figH]); 
    t = tiledlayout(2,3,'TileSpacing','loose','Padding','loose');

    % define boundaries of the analysis window
    % frequency range: 8-12 Hz; time range: 500-2500 ms
    yValue = 8;
    yValue2 = 12;
    xRange = [500, 2500];
    
    xValue = 500;
    xValue2 = 2500;
    yRange = [8, 12];

    % plot the four electrodes and their sensorimotor average
    for electrodeidx = 1:length(tf_all)

        nexttile;
        hold on;

        % plot time-frequency ERD/ERS representation and configure axes
        imagesc(times_check, flip(freqs_check), flip(time_frequency_data(s).(tf_all{electrodeidx})));
        axis xy;
        colormap('jet');
        caxis([-100, 100]); % setting color axis limits
        xlabel('Time [ms]');
        ylabel('Frequency [Hz]');
        xlim([times_check(1) times_check(end)]);
        ylim([5 35]);
        xticks(-2000:1000:8000);
        yticks(5:5:35);
        set(gca, 'TickDir', 'out', 'Layer', 'top','FontSize', 8)

        % add subplot title indicating session and electrode/region
        title(sprintf('%s - %s', time_frequency_data(s).session, tf_all_name{electrodeidx}), "FontSize",10); 

        % mark the predefined analysis window (8-12 Hz, 500-2500 ms)
        hold on;
        hline = line([xRange(1), xRange(2)], [yValue, yValue]);
        hline.Color = 'k';  % set the color of the line
        hline.LineWidth = 2;  % set the line width
        hline = line([xRange(1), xRange(2)], [yValue2, yValue2]);
        hline.Color = 'k';  % set the color of the line
        hline.LineWidth = 2;  % set the line width
        vline = line([xValue, xValue], [yRange(1), yRange(2)]);
        vline.Color = 'k';  % set the color of the line
        vline.LineWidth = 2;  % set the line width
        vline = line([xValue2, xValue2], [yRange(1), yRange(2)]);
        vline.Color = 'k';  % set the color of the line
        vline.LineWidth = 2;  % set the line width
        hold off;
    end

    % add shared colorbar
    cb = colorbar('eastoutside');             
    ylabel(cb, 'ERD%');

    % save subject-level figure
    fileName = [time_frequency_data(s).subject, '_', time_frequency_data(s).group, '_', time_frequency_data(s).session, '_', '.png'];      % set the filename
    fullFilePath = fullfile(PATHOUT, fileName);   % combining the directory and filename to create the full file path
    saveas(gcf, fullFilePath);  % saving the figure
end

close all;

% save updated time-frequency data structure including sensm_avg
fullFilePath = fullfile(PATHOUT, 'time_frequency_data_struct.mat');
save(fullFilePath, 'time_frequency_data', '-v7.3');

%% COMPUTE GRAND-AVERAGE TIME-FREQUENCY MAPS

% initialize arrays for the four group x session conditions
MI1_sh  = [];
MI1_mt  = [];
MI2_sh  = [];
MI2_mt  = [];

% initialize participant counters for each condition
counter_a = 1;
counter_b = 1;
counter_c = 1;
counter_d = 1;

% loop over datasets
for s = 1:length(time_frequency_data)

    % collect time-frequency data for each electrode/average separately
    % according to experimental group and motor imagery session
    for electrodeidx = 1:length(tf_all)
        if strcmp(time_frequency_data(s).session, 'MI1') && strcmp(time_frequency_data(s).group, 'sh')
            MI1_sh(:,:,electrodeidx,counter_a) = time_frequency_data(s).(tf_all{electrodeidx});
        elseif strcmp(time_frequency_data(s).session, 'MI1') && strcmp(time_frequency_data(s).group, 'mt')
            MI1_mt(:,:,electrodeidx,counter_b) = time_frequency_data(s).(tf_all{electrodeidx});
        elseif strcmp(time_frequency_data(s).session, 'MI2') && strcmp(time_frequency_data(s).group, 'sh')
            MI2_sh(:,:,electrodeidx,counter_c) = time_frequency_data(s).(tf_all{electrodeidx});
        elseif strcmp(time_frequency_data(s).session, 'MI2') && strcmp(time_frequency_data(s).group, 'mt')
            MI2_mt(:,:,electrodeidx,counter_d) = time_frequency_data(s).(tf_all{electrodeidx});
        end
    end

    % update participant counter for the corresponding condition
    if strcmp(time_frequency_data(s).session, 'MI1') && strcmp(time_frequency_data(s).group, 'sh')
        counter_a = counter_a + 1;
    elseif strcmp(time_frequency_data(s).session, 'MI1') && strcmp(time_frequency_data(s).group, 'mt')
        counter_b = counter_b + 1;
    elseif strcmp(time_frequency_data(s).session, 'MI2') && strcmp(time_frequency_data(s).group, 'sh')
        counter_c = counter_c + 1;
    elseif strcmp(time_frequency_data(s).session, 'MI2') && strcmp(time_frequency_data(s).group, 'mt')
        counter_d = counter_d + 1;
    end
end

% compute grand-average ERD/ERS maps across participants
MI1_sh_GA = mean(MI1_sh, 4);
MI1_mt_GA = mean(MI1_mt, 4);
MI2_sh_GA = mean(MI2_sh, 4);
MI2_mt_GA = mean(MI2_mt, 4);

% store grand averages and corresponding names for plotting
grandaverages_names = {'MI1_sh_GA', 'MI1_mt_GA', 'MI2_sh_GA', 'MI2_mt_GA'};
grandaverages = {MI1_sh_GA, MI1_mt_GA, MI2_sh_GA, MI2_mt_GA};

%% CREATE GRAND-AVERAGE FIGURES

% loop over the four group x session conditions
for ga = 1:length(grandaverages)

    % create grand-average figure
    figure('Position',[100 100 figW figH]);
    t = tiledlayout(2,3,'TileSpacing','loose','Padding','loose');

    % define boundaries of the analysis window
    % frequency range: 8-12 Hz; time range: 500-2500 ms    
    yValue = 8;
    yValue2 = 12;
    xRange = [500, 2500];
    
    xValue = 500;
    xValue2 = 2500;
    yRange = [8, 12];

    % plot the four electrodes and their sensorimotor average
    for electrodeidx = 1:length(tf_all)
        nexttile;
        hold on;

        % plot grand-average time-frequency ERD/ERS representation and configure axes
        imagesc(times_check, flip(freqs_check), flip(grandaverages{ga}(:,:,electrodeidx)));
        axis xy;
        colormap('jet');
        caxis([-75, 75]); % setting color axis limits
        xlabel('Time [ms]');
        ylabel('Frequency [Hz]');
        xlim([times_check(1) times_check(end)]);
        ylim([5 35]);
        xticks(-2000:1000:8000);
        yticks(5:5:35);
        set(gca, 'TickDir', 'out', 'Layer', 'top','FontSize', 8)

        % add subplot title indicating electrode/region
        title(tf_all_name{electrodeidx},"FontSize",10);

        % mark the predefined analysis window (8-12 Hz, 500-2500 ms)
        hold on;
        hline = line([xRange(1), xRange(2)], [yValue, yValue]);
        hline.Color = 'k';  % set the color of the line
        hline.LineWidth = 2;  % set the line width
        hline = line([xRange(1), xRange(2)], [yValue2, yValue2]);
        hline.Color = 'k';  % set the color of the line
        hline.LineWidth = 2;  % set the line width
        vline = line([xValue, xValue], [yRange(1), yRange(2)]);
        vline.Color = 'k';  % set the color of the line
        vline.LineWidth = 2;  % set the line width
        vline = line([xValue2, xValue2], [yRange(1), yRange(2)]);
        vline.Color = 'k';  % set the color of the line
        vline.LineWidth = 2;  % set the line width
        hold off;
    end

    % add shared colorbar
    cb = colorbar('eastoutside');
    ylabel(cb, 'ERD%');

    % save grand-average figure
    fileName = [grandaverages_names{ga}, '.png'];      % set the filename
    fullFilePath = fullfile(PATHOUT, fileName);   % combining the directory and filename to create the full file path
    saveas(gcf, fullFilePath);  % saving the figure
end

close all;


% save grand-average matrices separately for each group x session condition
fullFilePath = fullfile(PATHOUT, 'MI1_sh_GA.mat');
save(fullFilePath, 'MI1_sh_GA');

fullFilePath = fullfile(PATHOUT, 'MI1_mt_GA.mat');
save(fullFilePath, 'MI1_mt_GA');

fullFilePath = fullfile(PATHOUT, 'MI2_sh_GA.mat');
save(fullFilePath, 'MI2_sh_GA');

fullFilePath = fullfile(PATHOUT, 'MI2_mt_GA.mat');
save(fullFilePath, 'MI2_mt_GA');

% return to scripts folder
cd(fullfile(MAINPATH, 'scripts', filesep));

% end of script