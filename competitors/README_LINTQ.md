# QSmell Static Analysis on LintQ

To run the QSmell static analysis tool on the LintQ dataset, you have to run the following command (from the main root):
```
python -m competitors.qsmell_static.run_qsmell_folder config/competitors/qsmell_v08.yaml
```

Note that all the file `qsmell_v08.yaml` will contain the relevant pointers to the dataset and the detectors you want to run:

```yaml
# Input of the analysis containing parsable python files
input_folder: data/datasets/exp_v08/files_selected

# output_folder: where to store the individual csv of the metrics
output_folder: data/datasets/exp_v08/qsmell

# metrics: each must have a .py file with the same name
# and should expose a method compute_metric(ast, output_file_path)
# a new subfolder will be created for each metric
metrics_to_compute:
  - NC
  - LPQ
```


# PYLint Static Analysis on LintQ

To run the PYLint static analysis tool on the LintQ dataset, you have to run the following command (from the main root):
```
python -m competitors.pylint.run_pylint_folder config/competitors/pylint_v08.yaml
```

Make sure to use the `LintQEnv` conda environment. From the root repo run:
```
conda env create -f virtualenv/conda/environment.yml
```