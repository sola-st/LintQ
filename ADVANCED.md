# Advanced
In this section you find extra information, such as:
- [Run Competitors](#run-competitors)
- [Development Mode](#development-mode)
- [Scrape a new Dataset of Quantum Programs](#create-the-dataset-of-programs)

## Run Competitors
To run the competitors on the same dataset see the following [README](competitors/README_LINTQ.md)


## Development Mode

To modify the query files or the library and run the modified version use this command, note to replace the path to codeql database and the output sarif accordingly, the main difference is the `LintQ-dev.qls` and the mounting of the entire content of the main repo.

```bash
docker run \
    -v "$(pwd):/home/codeql/project" \
    -it --rm LintQ \
codeql database analyze \
    --format=sarifv2.1.0 \
    --threads=10 \
    --output=/home/codeql/project/data/datasets/demo/my_results.sarif \
    --rerun \
    -- /home/codeql/project/data/datasets/demo/codeql_db \
    /home/codeql/project/LintQ-dev.qls
```

# Create the Dataset of Programs

## Github Scrape

The configuration file defining all the mining details is store at `config/github_download_files.yaml`. The file contains the following fields:
- `github_token_path`: path to the file containing the github token
- `file_mining`: the settings to define how to mine the files with the github search API. Namely the `output_folder` where to save the metadata pointing to the final files. `language` is the programming language to search for. `min_file_size` and `max_file_size` define the range of the admissible size of the returned files in bytes. Note that since it is not possible to retrieve all the results with a single queries, we use the size range to form smaller queries for which all the results can be read and proceed until we obtain all the files in the range. `chunk_size` is used to define the sub-ranges to query and it is automatically adjusted until all the possible files are collected.
- `keywords`: the list of keywords to search for in the github search API. They are in logical or, namely the search will return all the files containing at least one of the keywords.

To effectively run the query we use the CLI program `rdlib/github.py` with the following command:
```bash
screen -L -Logfile log_long.txt -S first_run python -m rdlib.github downloadfiles --config config/github_download_files.yaml --output secret/files.json --incremental
```
Note that the prefix `screen -L -Logfile log_long.txt -S first_run` is needed if you want to have the program run also if you close the terminal. It is usually recommended.




## Dataset Filtering (NEW)
1. **Query GitHub**. Prepare a configuration file in the `config` folder (typically called `github_download_files_vXX`). See `github_download_files_v03.yaml` for an example.

1. Run the following command to download the files:
    ```bash
    screen -L -Logfile data/github_query_results/exp_vXX/log.txt -S qiskit_download python -m rdlib.github queryfilesmetadata --config config/github_download_files_vXX.yaml
    ```
    Note that the prefix `screen -L -Logfile data/github_query_results/exp_vXX/log.txt -S qiskit_download` is needed if you want to have the program run also if you close the terminal. It is usually recommended, you can change the folder where to save the log file and the name of the screen session.

1. **Download Files**. Prepare the configuration file in the `config` folder (typically called `dataset_creation_exp_vXX.yaml`). See `dataset_creation_exp_v03.yaml` for an example.

1. To download the actual files from the metadata, run the following command:
    ```bash
    screen -L -Logfile data/datasets/exp_vXX/log_download.txt -S qiskit_dataset_creation python -m qlint.datautils.dataset_creation downloadfiles --config config/dataset_creation_exp_vXX.yaml
    ```

1. To filter the dataset based on the `processing_steps` in the config file, run the following command:
    ```bash
    screen -L -Logfile data/datasets/exp_vXX/log_filter.txt -S qiskit_dataset_creation python -m qlint.datautils.dataset_creation filterdataset --config config/dataset_creation_exp_vXX.yaml
    ```

1. Move the selected programs in a dedicated folder (typically called `files_selected`) by running:
    ```bash
    screen -L -Logfile data/datasets/exp_vXX/log_filter.txt -S qiskit_dataset_creation python -m qlint.datautils.dataset_creation createselection --config config/dataset_creation_exp_vXX.yaml
    ```

1. Create the CodeQL database for the filtered dataset:
    ```bash
    screen -L -Logfile data/datasets/exp_vXX/log.txt -S codeql_database_creation codeql database create --language=python --threads=10 --source-root=data/datasets/exp_vXX/files_selected/ -- data/datasets/exp_vXX/codeql
    ```

# Miscellanea

## Run the Test CodeQL Queries

Follow these steps:
1. Clone this repository
2. Install the CodeQL CLI from [here](https://codeql.github.com/docs/codeql-cli/getting-started-with-the-codeql-cli/)
3. Move to the source directory `qlint/codeql/src` containing the `qlpack.yml` and install the external packs (e.g. the python-all dependencies) with the following command:
    ```bash
    cd qlint/codeql/src
    codeql pack install
    ```
    Take note of the path where the dependencies are stored (e.g. `/home/<username>/.codeql/packages`).
4. Move to the repo root and run the following command including this path:
    ```bash
    codeql test run qlint/codeql/test/query-tests/Measurement --additional-packs=~/.codeql/packages --threads=10
    ```
    This will run the tests of the specific folder `query-tests/Measurement` and will use the dependencies installed in the previous step.
    Note, change path to test the library concept, e.g. `codeql test run qlint/codeql/test/library-test/qiskit/circuit --additional-packs=~/.codeql/packages --threads=10`.

## Run the Query on the Full Dataset

Follow these steps:
1. Run the queries in the `qlint/codeql/src` folder on the dataset (in the folder `data/datasets/exp_vXX/codeql_db`) with the following command:
The output will be stored in the folder `data/analysis_results/exp_vXX/codeql_{current_date_time}`. Note: add `--rerun` to the command if you want to re-run the analysis on the same dataset without using the cache.
    ```bash
    export CURRENT_DATE_TIME=`date "+%Y-%m-%d_%H-%M-%S"`; \
    export OUTPUT_DIR=data/analysis_results/exp_vXX/codeql_${CURRENT_DATE_TIME}; \
    mkdir -p $OUTPUT_DIR; \
    codeql database analyze --format=sarifv2.1.0 --threads=10 --output=$OUTPUT_DIR/data.sarif -- data/datasets/exp_vXX/codeql_db/ qlint/codeql/src
    ```
    Demo version:
    ```bash
    export CURRENT_DATE_TIME=`date "+%Y-%m-%d_%H-%M-%S"`; \
    export OUTPUT_DIR=data/analysis_results/demo/codeql_${CURRENT_DATE_TIME}; \
    mkdir -p $OUTPUT_DIR; \
    codeql database analyze --format=sarifv2.1.0 --rerun --output=$OUTPUT_DIR/data.sarif -- data/demo_dataset_output/ qlint/codeql/src
    ```


## Inspect the Generated Warning

To inspect the generated warnings use the following command:
```bash
python -m rdlib.inspector --config config/annotations/inspection_exp_vXX.yaml
```
Remember to create the configuration file in the `config/annotations` folder.
You can see an example of the configuration file in `config/annotations/inspection_exp_v04.yaml`.


## Troubleshooting

1. **missing packages**: if you run the quick evaluation in the VSCode environment, be sure to have opened the folder `/home/<username>/.codeql/packages` in your VSCode workspace. Otherwise, the CodeQL extension will not be able to find the dependencies.
This operation will create a file named `qlint.code-workspace` in the repo folder, it will not uploaded to git but it is important you keep it.

2. **performance**: for historic reason CodeQL looks for codeql libraries (`qlpack.yml`) in the sibling directories of the one you are running it, thus if you clone this repo in a directory with many other folders (e.g. `~/Documents/`) the codeql run will be significantly slower (see [this issue](https://github.com/github/vscode-codeql/issues/1259)).
To solve the problem you can clone the repo in a brand new empty folder, following these steps:
```shell
mkdir lintq_home
cd lintq_home
git clone <this repo url>
```