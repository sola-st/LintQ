# De-duplicate Dataset

Steps to deduplciate your dataset:

1. Open the terminal in this directory.
1. create a sub-folder with your python files in the folder `data/ipynb_07/projects`, such as `data/ipynb_07/projects/my_project`. You can have an arbitrary number of subfolders.
2. run the following command to generate the token-level of all the files in the `projects` folder and store it in the `tokenized_files` folder:
    ```
    python qlint/datautils/tokenizer/tokenizepythoncorpus.py data/program_filtered/exp_v01/ data/program_filtered/exp_v01/tokenized_files/
    ```
3. Activate your virtual environment with:
    ```
    source /home/paltenmo/projects/TestingAssumptions/venv38/bin/activate
    ```
4. run the following command to generate the list of duplicate files:
    ```
    python qlint/datautils/pythonDedup/deduplicationcli.py data/program_filtered/exp_v01/tokenized_files/ dedup.json.gz
    ```
5. unzip the output archive and inspect it:
    ```
    gzip -d dedup.json.gz
    ```