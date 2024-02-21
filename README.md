# LintQ: A Static Analysis Framework for Qiskit Quantum Programs


LintQ is a framework for static analysis of quantum programs written in Qiskit.
It comprises:
1. **LintQ Core**: a set of quantum-specific concepts that supports the definition of static analysis of quantum programs.
2. **LintQ Analyses**: a set of analyses build on top of the abstractions offered by the core.

# Artifacts

The current research work contains and shares the following resources:

1. **LintQ Core**, implemented via CodeQL libraries:
    - Download: not needed, already in this repo.
    - Found at the path: [`<repo_root>/qlint/codeql/lib/qiskit`](qlint/codeql/lib/qiskit)
1. **Analyses**, implemented as CodeQL queries:
    - Download: not needed, already in this repo.
    - Found at the path: [`<repo_root>/qlint/codeql/src`](qlint/codeql/src)
1. **Dataset of quantum programs**, including the compiled CodeQL database.
    - Download: [here](https://figshare.com/s/8a120be10fe2292f4520)
    - To place at the path: [`<repo_root>/data/datasets/exp_v08`](data/datasets/exp_v08)
1. **LintQ warnings** in SARIF format (Static Analysis Results Interchange Format):
    - Download: not needed, already in this repo.
    - Found at the path: [`<repo_root>/data/analysis_results/exp_v08/codeql_2023-09-18_17-17-54`](data/analysis_results/exp_v08/codeql_2023-09-18_17-17-54/)
1. **Manual annotations** of the warnings:
    - Download: not needed, already in this repo.
    - To place at the path: [`<repo_root>/data/annotations/manual_inspection/manual_inspection_data_sample_fixed_10_codeql_2023-09-18_17-17-54.csv`](data/annotations/manual_inspection/manual_inspection_data_sample_fixed_10_codeql_2023-09-18_17-17-54.csv)
1. **True Positives Issues**:
    - Download: not needed, already in this repo.
    - Found at the path: [`<repo_root>/bug_reports/true_positives_found`](bug_reports/true_positives_found)
1. **Issue filed on GitHub** as consequence of some true positive warnings:
    - Download: not needed, already in this repo.
    - Found at the path: [`<repo_root>/bug_reports`](bug_reports)
    - Check [bug_reports/true_positives_found/PAPER_MAPPING.md](bug_reports/true_positives_found/PAPER_MAPPING.md) for the mapping between the issues and the paper.
    - Check the folder [`<repo_root>/bug_reports/inspection_codeql_2023-09-18_17-17-54`](bug_reports/inspection_codeql_2023-09-18_17-17-54) for the issues reported in our latest inspection.


# Reproducibility

To recreate the paper figures and tables  then you need to install the dependencies to run the Python notebook.

## Install dependencies

1. make sure you have conda installed, otherwise install it from [here](https://docs.conda.io/en/latest/miniconda.html)
2. create a conda virtual environment from our configuration file [here](virtualenv/conda/environment.yml):
    ```bash
    conda env create -f virtualenv/conda/environment.yml
    ```
3. activate the virtual environment:
    ```bash
    conda activate LintQEnv
    ```

Extra info: the environment was exported using.
```bash
conda env export --file virtualenv/conda/environment.yml
```

## Run the notebook

Open and run top to bottom the notebook at the following path:
[`<repo_root>/notebooks/RQs_Reproduce_Analysis_Results_LintQ.ipynb`](notebooks/RQs_Reproduce_Analysis_Results_LintQ.ipynb)

# Extra Details

## Environment Versions
- **CodeQL** command-line toolchain release 2.11.2.
- **Ubuntu**: 18.04.6 LTS
- **Python**: 3.10 (see conda environment)
- **Qiskit**: 0.44.1 (see conda environment)


## Run Analyses on LintQ Dataset

1. Place your dataset (downloaded from Figshare) into the folder `/data/datasets/`
2. Unzip it there and place its content in a folder (e.g. `data/dataset/exp_v08`)
3. Go to the folder `automation_scripts`
4. Run the analyses with:
```bash
./run_queries_on_quantum_database.sh
```
5. Select your database
6. Congrats! The SARIF files with the warnings are now in the folder `data/analysis_results/<your_database_name>/codeql_<date>_<time>/`

## Run Competitors
To run the competitors on the same dataset see the following [README](competitors/README_LINTQ.md)




