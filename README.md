# No Evidence of an Effect of a Single Mirror Visual Feedback Session on Subsequent Motor Imagery
This project investigates the interaction between two rehabilitation approaches that can engage sensorimotor brain networks without requiring movement of the corresponding limb: motor imagery (MI) and mirror visual feedback (MVF) (Deconinck et al., 2015; Munzert et al., 2009). While both approaches have been studied individually and in concurrent combination, less is known about whether the effects of MVF persist and influence subsequent MI. We therefore investigated whether a single session of MVF modulates sensorimotor EEG activity during subsequent kinesthetic motor imagery (kMI).

The results showed that kMI reliably elicited mu event-related desynchronization (ERD) over sensorimotor regions across groups and sessions, suggesting successful engagement of sensorimotor networks. Mu ERD was also stronger over the contralateral left than the right hemisphere. Contrary to our hypotheses, however, a single session of MVF did not enhance subsequent kMI-related mu ERD or its lateralization compared with a sham intervention. Thus, the findings provide no evidence that a brief session of MVF modulates the neural correlates of subsequent kMI.

## Repository Contents 
This repository contains: 
- **scripts:** MATLAB scripts for processing the EEG data collected during the study, preparing the data for statistical analysis in JASP (JASP Team, 2025, version 0.95.4) as well as creating plots.
- **electrodeposition_digitizer:** .elc files for the digitized electrode positions with the cap positioned as used during data acquisition (i.e., systematic posterior displacement), and with the cap correctly aligned according to the anatomical landmarks nasion, inion, and the left and right preauricular points.

## Required Local Directory Structure
To run the analysis pipeline, the following directory structure is expected:

```
project/
├── rawdata_xdf/
├── scripts/
└── electrodeposition_digitizer/
```

- `rawdata_xdf`: Contains all the raw .xdf files.
- `scripts`: Contains MATLAB scripts for data processing, preparation for statistical analysis in JASP (JASP Team, 2025, version 0.95.4) as well as creating plots.
- `electrodeposition_digitizer`: Contains .elc files for the digitized electrode positions with the cap positioned as used during data acquisition (i.e., systematic posterior displacement), and with the cap correctly aligned according to the anatomical landmarks nasion, inion, and the left and right preauricular points.

## Electrode Positions and Channel Nomenclature

Due to a systematic posterior displacement of the EEG cap during data acquisition, nominal electrode labels do not longer correspond to their locations in the 10-20 system. Electrode positions were digitized for both the intended and actual cap placement, and channel coordinates were adjusted accordingly.

The original channel labels were retained in the data and analysis scripts. Channels used for the sensorimotor analyses (FC1, FC2, C3, and C4) were selected based on their actual spatial locations after accounting for the cap displacement, rather than based on their original channel labels.

## Requirements
- MATLAB
- fieldtrip toolbox (fieldtrip-20260615 from https://github.com/fieldtrip/fieldtrip)
- EEGLAB toolbox (2025.0.0)
- xdfimport extension for eeglab

## Usage
The analysis pipeline expects the `rawdata_xdf` directory to contain the raw .xdf files before running the scripts.

The `rawdata_digitized` and `data` directories do not need to be created or populated manually. They are generated automatically during the analysis pipeline:

- `rawdata_digitized`: Contains all the raw .set files with updated channel locations according to the digitized electrode positions with the cap positioned as used during data acquisition (i.e., systematic posterior displacement).
- `data`: Contains processed data and plots.

The individual scripts access files from `rawdata_xdf`, `rawdata_digitized`, and/or `data`, depending on the respective processing step. Therefore, the scripts should be run in order. 

## Data Availability
The data underlying the analyses are available upon request from the corresponding author.

## License
This project is licensed under the MIT License.


