%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% findingROIchannels.m
%
% This script identifies candidate EEG channels in the posteriorly shifted
% electrode montage that are closest to predefined sensorimotor target
% positions from the correctly aligned montage.
%
% The following steps are performed:
%           - Load averaged and symmetrized electrode coordinates from the
%             correctly aligned cap configuration (target montage)
%           - Load averaged and symmetrized electrode coordinates from the
%             cap configuration used during data acquisition (shifted montage)
%           - Define C3, C4, CP1, and CP2 of the correctly aligned montage
%             as anatomical target positions
%           - Calculate the 3D Euclidean distance between each target
%             position and all electrodes of the shifted montage
%           - Identify the three nearest electrodes in the shifted montage
%             for each anatomical target
%           - Save electrode labels and corresponding distances
%
% Input:    - symmetrized_32ch_positions_correct.elc
%             Averaged and symmetrized electrode coordinates for the
%             correctly aligned cap configuration
%           - symmetrized_32ch_positions.elc
%             Averaged and symmetrized electrode coordinates for the
%             posteriorly shifted cap configuration used during data acquisition
%
% Output:   - nearest_neighbors_3_xyz.csv
%             Three nearest electrodes in the shifted montage for each
%             anatomical target and their Euclidean distances [mm]
%
% Note:     The nearest-neighbor calculation is used to identify candidate
%           channels for the sensorimotor ROI. Final ROI selection additionally
%           considers the systematic posterior cap displacement and the
%           anatomical location of the candidate electrodes.
%
% Linn Schwarz 03/04/2026
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% DIRECTORIES

clear all; close all;

% execute this script from within the 'scripts' folder
MAINPATH = fileparts(pwd);

% averaged and symmetrized electrode positions with the cap correctly aligned
% according to nasion, inion, and left/right preauricular landmarks
targetFile = fullfile(MAINPATH,'electrodeposition_digitizer','symmetrized_32ch_positions_correct.elc');

% averaged and symmetrized electrode positions with the cap positioned as
% during data acquisition (systematic posterior displacement)
candidateFile = fullfile(MAINPATH,'electrodeposition_digitizer','symmetrized_32ch_positions.elc');

% output file 
outputCSV = fullfile(MAINPATH,'electrodeposition_digitizer','nearest_neighbors_3_xyz.csv');

%% TARGET ELECTRODES

% sensorimotor electrode positions in the correctly aligned montage that
% serve as anatomical targets for the nearest-neighbor search
targetLabels = {'C3','C4','CP1','CP2'};

%% LOAD CHANNEL LOCATIONS

% load correctly aligned (target) and posteriorly shifted (candidate)
% electrode configurations
targetLocs = readlocs(targetFile);
candLocs   = readlocs(candidateFile);

% extract electrode labels and XYZ coordinates from target montage
targetLabelsAll = {targetLocs.labels}';
targetXYZall    = [[targetLocs.X]' [targetLocs.Y]' [targetLocs.Z]'];

% extract electrode labels and XYZ coordinates from shifted montage
candLabels = {candLocs.labels}';
candXYZ    = [[candLocs.X]' [candLocs.Y]' [candLocs.Z]'];

%% FIND THREE NEAREST NEIGHBORS

% initialize cell array for results
results = cell(numel(targetLabels), 7);

% loop over anatomical target electrodes
for i = 1:numel(targetLabels)

    thisTarget = targetLabels{i};

    % find target electrode in the correctly aligned montage
    idxT = find(strcmpi(targetLabelsAll, thisTarget), 1);
    if isempty(idxT)
        error('Target label %s not found.', thisTarget);
    end

     % XYZ coordinates of current anatomical target
    xyzT = targetXYZall(idxT,:);

    % calculate 3D Euclidean distance between the target position and all
    % electrode positions in the shifted montage
    d = sqrt(sum((candXYZ - xyzT).^2, 2));

    % sort candidate electrodes by increasing distance
    [dSorted, idxSorted] = sort(d, 'ascend');

    % select the three nearest candidate electrodes
    idx1 = idxSorted(1);
    idx2 = idxSorted(2);
    idx3 = idxSorted(3);

    % store target, candidate labels, and corresponding distances [mm]
    results(i,:) = { ...
        thisTarget, ...
        candLabels{idx1}, dSorted(1), ...
        candLabels{idx2}, dSorted(2), ...
        candLabels{idx3}, dSorted(3)};
end

%% DISPLAY RESULTS

% convert results to table for easier inspection
T = cell2table(results, ...
    'VariableNames', { ...
        'TargetLabel', ...
        'Nearest1_Label','Nearest1_Distance_mm', ...
        'Nearest2_Label','Nearest2_Distance_mm', ...
        'Nearest3_Label','Nearest3_Distance_mm'});

disp(T);

%% SAVE RESULTS

% save nearest-neighbor labels and distances as CSV
writetable(T, outputCSV);

fprintf('\nResults saved to:\n%s\n', outputCSV);

% end of script 
