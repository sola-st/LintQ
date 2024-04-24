# LintQ: A Static Analysis Framework for Qiskit Quantum Programs


LintQ is a framework for static analysis of quantum programs written in Qiskit.
It comprises:
1. **LintQ Core**: a set of quantum-specific concepts that supports the definition of static analysis of quantum programs.
2. **LintQ Analyses**: a set of analyses build on top of the abstractions offered by the core.


## Use Cases
You can run LintQ with two objectives:

- [Replication Package Level 1](#replicate-the-paper-figures-level-1): reproduce the figures and tables from the paper.
- [Replication Package Level 2](#run-lintq-to-analyze-a-new-dataset-level-2): analyze a new dataset of quantum programs with LintQ.

## Getting Started

- Check that your setup meets the [REQUIREMENTS.md](REQUIREMENTS.md).
- Follow the installation instructions in [INSTALL.md](INSTALL.md).


## Reproduce the Paper Figures (Level 1)

This replication level allows to independently reproduce the results of our paper starting from the experimental data we collected during our empirical evaluation.

Follow these steps:

1. Download the datasets used in our evaluation from [here](https://figshare.com/s/8a120be10fe2292f4520)
1. Unzip it and place it at the path: [`data/datasets/exp_v08`](data/datasets/exp_v08)
1. Open the Jupyter notebook [`notebooks/RQs_Reproduce_Analysis_Results_LintQ_REVISION.ipynb`](notebooks/RQs_Reproduce_Analysis_Results_LintQ_REVISION.ipynb) and run it top to bottom to reproduce the figures and tables from the paper.
1. The output will be stored in the folder [`notebooks/paper_figures_revision`](notebooks/paper_figures_revision). To open the Jupyter notebook run:
    ```
    conda activate LintQEnv
    jupyter notebook
    ```
    In the jupyter notebook web interface, navigate to and execute top-to-bottom the target notebook.

## Run LintQ to Analyze a new Dataset (Level 2)

This replication level allows to run LintQ queries on any folder containing quantum progams.

Follow these steps:

1. Place your folder containing quantum programs in the [`data/datasets`](data/datasets) folder (e.g. `data/datasets/my_programs`)
1. Convert the python files in the target folder to a database of facts about the quantum programs, the new database will be store at the given path (e.g. `data/datasets/my_database`):
    ```bash
    docker run -v $(pwd):/home/codeql/project -it --rm codeql-for-lintq \
        codeql database create /home/codeql/project/data/datasets/my_database \
        --language=python \
        --source-root /home/codeql/project/data/datasets/my_programs
    ```
1. Enter in the docker in interactive mode:
    ```
    docker run -v $(pwd):/home/codeql/project -it --rm codeql-for-lintq
    ```
1. Move to the folder with the LintQ package to install:
    ```bash
    cd /home/codeql/project/qlint/codeql/src
    ```
1. Install the LintQ package dependencies:
    ```bash
    codeql pack install
    ```
    Take note of the path where the dependencies are stored (e.g. `/home/<username>/.codeql/packages`).
1. Go back to the main path of the repo (while staying inside the docker container):
    ```bash
    cd /home/codeql/project/
    ```
1. Run the queries on the demo dataset and produce an analysis output at the given path (e.g., `data/datasets/my_results.sarif`)
    ```bash
    codeql database analyze \
        --format=sarifv2.1.0 \
        --threads=10 \
        --output=/home/codeql/project/data/datasets/my_results.sarif \
        --rerun \
        -- /home/codeql/project/data/datasets/my_database \
        /home/codeql/project/qlint/codeql/src
    ```
1. Congratulations you have successfully analyzed your first quantum programs with LintQ and collected some warnings! Your static analysis warnings are store in a file in SARIF format, an interoperable format for warnings, read more [here](https://docs.github.com/en/code-security/code-scanning/integrating-with-code-scanning/sarif-support-for-code-scanning#about-sarif-support)




## Detailed Content of the Repository

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
    - Found at the path: [`<repo_root>/data/analysis_results/exp_v08/codeql_2024-03-01_08-43-53`](data/analysis_results/exp_v08/codeql_2024-03-01_08-43-53)
1. **Manual annotations** of the warnings:
    - Download: not needed, already in this repo.
    - To place at the path: [`<repo_root>/data/analysis_results/exp_v08/codeql_2024-03-01_08-43-53/Annotation_06_data_sample_representative_10.csv`](data/analysis_results/exp_v08/codeql_2024-03-01_08-43-53/Annotation_06_data_sample_representative_10.csv)
1. **True Positives Issues**:
    - Download: not needed, already in this repo.
    - Found at the path: [`<repo_root>/bug_reports/true_positives_found`](bug_reports/true_positives_found)
1. **Annotation Protocol**:
    - Download: not needed, already in this repo.
    - Found at the path: [`<repo_root>/bug_reports/true_positives_found/annotation_protocol.csv`](/bug_reports/true_positives_found/annotation_protocol.csv)


## Run the notebook

Open and run top to bottom the notebook at the following path:
[`<repo_root>/notebooks/RQs_Reproduce_Analysis_Results_LintQ_REVISION.ipynb`](notebooks/RQs_Reproduce_Analysis_Results_LintQ_REVISION.ipynb)

# Extra Details

## Advanced

If you want to collect a new dataset on GitHub you can have a look at the [`DATASET.md`](DATASET.md) file.

## Environment Versions
- **CodeQL** command-line toolchain release 2.11.2. Available [here](https://github.com/github/codeql-cli-binaries/releases/tag/v2.11.2)
- **Ubuntu**: 18.04.6 LTS
- **Python**: 3.10 (see conda environment)
- **Qiskit**: 0.45.2 (see conda environment)
- **Codeql CLI Version**: 2.11.2 :
- **CodeQL for Visual Studio Code extension**: 1.7.4 (precisely). Available [here](https://github.com/github/vscode-codeql/blob/main/extensions/ql-vscode/CHANGELOG.md#174---29-october-2022).


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




