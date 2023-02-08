# QLint

## A. Load the Dependencies

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

## B. Create the Dataset of Programs

### Github Scrape

The configuration file defining all the mining details is store at `config/github_download_files.yaml`. The file contains the following fields:
- `github_token_path`: path to the file containing the github token
- `file_mining`: the settings to define how to mine the files with the github search API. Namely the `output_folder` where to save the metadata pointing to the final files. `language` is the programming language to search for. `min_file_size` and `max_file_size` define the range of the admissible size of the returned files in bytes. Note that since it is not possible to retrieve all the results with a single queries, we use the size range to form smaller queries for which all the results can be read and proceed until we obtain all the files in the range. `chunk_size` is used to define the sub-ranges to query and it is automatically adjusted until all the possible files are collected.
- `keywords`: the list of keywords to search for in the github search API. They are in logical or, namely the search will return all the files containing at least one of the keywords.

To effectively run the query we use the CLI program `rdlib/github.py` with the following command:
```bash
screen -L -Logfile log_long.txt -S first_run python -m rdlib.github downloadfiles --config config/github_download_files.yaml --output secret/files.json --incremental
```
Note that the prefix `screen -L -Logfile log_long.txt -S first_run` is needed if you want to have the program run also if you close the terminal. It is usually recommended.

### Dataset Filtering
1. Open the notebook `qlint/notebooks/01_Quantum_Program_Dataset.ipynb` and run the cells until the `Deduplication` section.

2. To run the de-duplication, run the following command to tokenize the files:
    ```bash
    python qlint/datautils/tokenizer/tokenizepythoncorpus.py data/03_program_filtered/exp_v01/ data/03_program_filtered/exp_v01/tokenized_files/
    ```
    followed by the following command to run the de-duplication:
    ```bash
    python qlint/datautils/pythonDedup/deduplicationcli.py data/03_program_filtered/exp_v01/tokenized_files/ data/03_program_filtered/exp_v01/dedup.json.gz
    ```

3. Go to the target folder and unzip the `dedup.json.gz` file:
    ```bash
    cd data/03_program_filtered/exp_v01/
    gzip -d dedup.json.gz
    ```

3. Go back to the initial notebook and run it until the end.

### Dataset Metadata

1. Open the notebook `qlint/notebooks/01_Quantum_Program_Dataset_Metadata.ipynb` and run all its cells.

## C. Run the Analysis Notebooks
5. run the notebook:
    ```bash
    jupyter notebook
    ```
6. open the notebook `qlint/notebooks/XXX.ipynb` and run the cells.


## D. Run the Test CodeQL Queries

Follow this steps:
1. Clone this repository
2. Install the CodeQL CLI from [here](https://codeql.github.com/docs/codeql-cli/getting-started-with-the-codeql-cli/)
3. Move to the source directory `qlint/codeql/src` containing the `qlpack.yml` and install the external packs (e.g. the python-all dependencies) with the following command:
    ```bash
    codeql pack install
    ```
    Take note of the path where the dependencies are stored (e.g. `/home/<username>/.codeql/packages`).
4. Move to the `qlint/codeql` directory and run the following command including this path:
    ```bash
    codeql test run test/query-tests/Measurement --additional-packs /home/<username>/.codeql/packages
    ```
    This will run the tests of the specific folder `query-tests/Measurement` and will use the dependencies installed in the previous step.
