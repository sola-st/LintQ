# Create a New Dataset

1. Create the configuration file on which files you want to download in `config/github_download_files_vXX.yaml`. The file contains the following fields. See `config/github_download_files_v02.yaml` as an example.

2. Create a folder: `data/github_query_results/exp_vXX`.

3. Download the files metadata using the following command:
    ```bash
    screen -L -Logfile data/github_query_results/exp_vXX/log.txt -S new_github_query python -m rdlib.github downloadfiles --config config/github_download_files_vXX.yaml
    ```

4. Create a folder: `data/datasets/exp_vXX`.

5. Define the processing steps you want to perform in your dataset in `config/dataset_creation_exp_vXX.yaml`. See `config/dataset_creation_exp_v02.yaml` as an example.


6. Download the actual file content and create the dataset with the following command:
    ```bash
    screen -L -Logfile data/datasets/exp_vXX/log.txt -S new_dataset_creation python -m rdlib.github createdataset --config config/dataset_creation_exp_vXX.yaml
    ```