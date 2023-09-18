# LintQ


LintQ is a framework for static analysis of quantum programs written in Qiskit.
It comprises:
1. **LintQ Core**: a set of quantum-specific concepts that supports the definition of static analysis of quantum programs.
2. **LintQ Checkers**: a set of checkers build on top of the abstractions offered by the core.

# Artifacts

The current research work contains and shares the following resources:

1. **LintQ Core**, implemented via CodeQL libraries:
    - Download: not needed, already in this repo.
    - Found at the path: [`<repo_root>/qlint/codeql/lib/qiskit`](qlint/codeql/lib/qiskit)
1. **Checkers**, implemented as CodeQL queries:
    - Download: not needed, already in this repo.
    - Found at the path: [`<repo_root>/qlint/codeql/src`](qlint/codeql/src)
1. **Dataset of quantum programs**, including the compiled CodeQL database.
    - Download: [here](https://figshare.com/s/8a120be10fe2292f4520)
    - To place at the path: [`<repo_root>/data/datasets/exp_v08`](data/datasets/exp_v08)
1. **LintQ warnings** in SARIF format (Static Analysis Results Interchange Format):
    - Download: not needed, already in this repo.
    - Found at the path: [`<repo_root>/data/analysis_results/exp_v08/codeql_2023-03-20_19-13-27`](data/analysis_results/exp_v08/codeql_2023-03-20_19-13-27)
1. **QSmell warnings**, as representative existing work:
    - Download: not needed, same downloadable dataset as above.
    - Found at the path: [`<repo_root>/data/datasets/exp_v08/qsmell/`](data/datasets/exp_v08/qsmell/)
1. **QChecker warnings**: [path](data/datasets/exp_v08/qchecker)
1. **Manual annotations** of the warnings:
    - Download: not needed, already in this repo.
    - To place at the path: [`<repo_root>/data/annotations/manual_inspection/warnings_until_23_03_29.csv`](data/annotations/manual_inspection/warnings_until_23_03_29.csv)
1. **True Positives Issues**:
    - Download: not needed, already in this repo.
    - Found at the path: [`<repo_root>/bug_reports/true_positives_found`](bug_reports/true_positives_found)
1. **Issue filed on GitHub** as consequence of some true positive warnings:
    - Download: not needed, already in this repo.
    - Found at the path: [`<repo_root>/bug_reports`](bug_reports)


# Reproducibility

To recreate the paper figures and tables  then you need to install the dependencies to run the Python notebook.

## Install dependencies

1. make sure you have the virtualenv installed:
    ```bash
    pip install virtualenv
    ```
2. create a virtual environment:
    ```bash
    virtualenv venv38
    ```
3. activate the virtual environment:
    ```bash
    source venv38/bin/activate
    ```
4. install the requirements:
    ```bash
    pip install -r virtualenv/qlint_requirements.txt
    ```

## Run the notebook

Open and run top to bottom the notebook at the following path:
[`<repo_root>/notebooks/RQs_Reproduce_Analysis_Results.ipynb`](notebooks/RQs_Reproduce_Analysis_Results.ipynb)
