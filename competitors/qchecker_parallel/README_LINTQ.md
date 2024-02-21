# QChcker Static Analysis on LintQ

To run the QChecker static analysis tool on the LintQ dataset, you have to run the following command (from the main root):
```shell
python -m competitors.qchecker_parallel.run_qchecker_folder config/competitors/qchecker_v08.yaml
```

Note that all the file `qchecker_v08.yaml` will contain the relevant pointers to the dataset and the detectors you want to run:

```yaml
# Input of the analysis containing parsable python files
input_folder: data/datasets/exp_v08/files_selected

# output_folder: where to store the individual csv of the metrics
output_folder: data/datasets/exp_v08/qchecker

# metrics: each must have a .py file with the same name
# and should expose a method compute_metric(ast, output_file_path)
# a new subfolder will be created for each metric
metrics_to_compute:
  - IIS
  - PE
  - CE
  - CM
  - IM
  - QE
  - IG
  - DO
  - MI
```

The output will create many small sarif files, to condense them use the command:
```shell
python -m automation_scripts.merge_sarif_files data/datasets/exp_v08/qchecker
```
This will create a single sarif file with all the warnings called `all_detectors.sarif` in the same folder.
