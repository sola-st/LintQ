# Configuration/Experiment Files

This folder contains the files with the settings of the experiments.
Some info you would like to consider adding to the settings are:
- hyperparameters of a machine learning model (e.g., no of trees in a random forest model)
- the setting of a fuzzing run
- the input and output folders of a fuzzing run
A common format is yaml or json.
The yaml files are recommended since you can add also comment in them and keep a changelog at the beginning of each configuration file.

The suggested naming convention is the following: `exp_v01.yaml` or `exp_v01.json`. Where the prefix `exp` stays consistent across different runs and `v01` is the version number, which always increases.