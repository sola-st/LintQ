"""This file is responsible for scraping the dataset of quantum programs."""

import os
import click
import yaml
import pathlib
import pandas as pd
import shutil
import glob
from tqdm import tqdm
from termcolor import colored

from typing import List, Dict, Any, Tuple, Optional


from rdlib.fsh import load_config_and_check
from rdlib.datalake import extract_url_hash_filename
from rdlib.datalake import download_files
from rdlib.fsh import read_data_in_parallel
from rdlib.fsh import read_json_file


from qlint.datautils.processing_steps import convert_ipynb_to_content_only
from qlint.datautils.processing_steps import create_summary_dataframe
from qlint.datautils.processing_steps import create_repo_statistic_dataframe
from qlint.datautils.processing_steps import filter_out
from qlint.datautils.processing_steps import remove_selected_duplicates
from qlint.datautils.processing_steps import convert_ipynb_to_content_only
from qlint.datautils.processing_steps import remove_unparsable_python
from qlint.datautils.processing_steps import keep_based_on_attribute
from qlint.datautils.processing_steps import remove_too_long_filenames
from qlint.datautils.processing_steps import content_regex_filter
from qlint.datautils.processing_steps import add_hash_of_the_content
from qlint.datautils.processing_steps import remove_duplicates
from qlint.datautils.processing_steps import sanitize_filenames

from qlint.datautils.processing_function import RemoveLongNames
from qlint.datautils.processing_function import ProcessingFunction
from qlint.datautils.processing_function import AddHashAsExtraMetadata
from qlint.datautils.processing_function import RemoveDuplicates
from qlint.datautils.processing_function import KeepBasedOnAttributeValue
from qlint.datautils.processing_function import RemoveBasedOnAttributeValue
from qlint.datautils.processing_function import ConvertNotebooksToScripts
from qlint.datautils.processing_function import ContentRegexFilter
from qlint.datautils.processing_function import RemoveUnparsable
from qlint.datautils.processing_function import UnrollLoops

def get_function(function_name: str) -> str:
    """Get the function name from given string."""
    if function_name == "filter_out":
        return filter_out
    elif function_name == "remove_selected_duplicates":
        return remove_selected_duplicates
    elif function_name == "convert_ipynb_to_content_only":
        return convert_ipynb_to_content_only
    elif function_name == "remove_unparsable_python":
        return remove_unparsable_python
    elif function_name == "keep_based_on_attribute":
        return keep_based_on_attribute
    elif function_name == "remove_too_long_filenames":
        return remove_too_long_filenames
    elif function_name == "content_regex_filter":
        return content_regex_filter
    elif function_name == "add_hash_of_the_content":
        return add_hash_of_the_content
    elif function_name == "remove_duplicates":
        return remove_duplicates
    elif function_name == "sanitize_filenames":
        return sanitize_filenames
    else:
        raise ValueError(f'Unknown function name: {function_name}')


def get_function_from_string(function_name: str) -> ProcessingFunction:
    if function_name == "remove_too_long_filenames":
        return RemoveLongNames
    elif function_name == "add_hash_of_the_content":
        return AddHashAsExtraMetadata
    elif function_name == "remove_duplicates":
        return RemoveDuplicates
    elif function_name == "keep_based_on_attribute":
        return KeepBasedOnAttributeValue
    elif function_name == "filter_out":
        return RemoveBasedOnAttributeValue
    elif function_name == "convert_ipynb_to_content_only":
        return ConvertNotebooksToScripts
    elif function_name == "content_regex_filter":
        return ContentRegexFilter
    elif function_name == "remove_unparsable_python":
        return RemoveUnparsable
    elif function_name == "unroll_loops":
        return UnrollLoops
    else:
        raise ValueError(f'Unknown function name: {function_name}')


@click.group()
def cli():
    """Download files from GitHub given the links and create a dataset."""
    pass


@cli.command()
@click.option(
    '--config', default='config.json', help='Path to the config file.')
def downloadfiles(config):
    """Download files from GitHub given the links and create a dataset."""
    config_dict = load_config_and_check(config)
    dir_github_results = config_dict['github_query_results']
    dir_dataset_folder = config_dict['dataset_folder']
    pathlib.Path(dir_dataset_folder).mkdir(parents=True, exist_ok=True)

    # create output folders
    print('Creating output folders...')
    dir_raw_files = os.path.join(dir_dataset_folder, 'raw_files')
    pathlib.Path(dir_raw_files).mkdir(parents=True, exist_ok=True)
    # dir_py_files = os.path.join(dir_dataset_folder, 'py_files_from_ipynb')
    # pathlib.Path(dir_py_files).mkdir(parents=True, exist_ok=True)
    dir_files_selected = os.path.join(dir_dataset_folder, 'files_selected')
    pathlib.Path(dir_files_selected).mkdir(parents=True, exist_ok=True)
    dir_intermediate_results = \
        os.path.join(dir_dataset_folder, 'intermediate_results')
    pathlib.Path(dir_intermediate_results).mkdir(parents=True, exist_ok=True)

    # get the list of files to download
    print('Reading GitHub metadata...')
    files = read_data_in_parallel(
        base_folder=dir_github_results,
        file_type_regex='files_.*\.json',
        read_function=read_json_file,
        n_processes=10)
    flat_files = [item for sublist in files for item in sublist]
    df_summary = create_summary_dataframe(flat_files)
    if config_dict.get('sample_size', None):
        random_seed = config_dict.get('random_seed', 42)
        df_summary = df_summary.sample(
            n=config_dict['sample_size'], random_state=random_seed)
    df_summary.to_csv(
        os.path.join(dir_dataset_folder, 'df_summary.csv'), index=False)

    # create statistics where we count how many files per repository we have
    print('Creating statistics (how many files per repo)...')
    df_repo_stats = create_repo_statistic_dataframe(df_summary)
    df_repo_stats.to_csv(
        os.path.join(dir_dataset_folder, 'df_stats.csv'), index=True)

    # download the files
    print('Downloading files...')
    url_snippets_to_download = df_summary['download_url'].tolist()
    download_files(
        urls=url_snippets_to_download,
        out_folder=dir_raw_files,
        func_url_to_filename=extract_url_hash_filename,
    )


def print_chain_summary(
        dir_intermediate_results: str,
        processing_steps: List[Dict[str, Any]]
    ) -> None:
    """Print the summary of the chain of processing steps.

    It iterates over all the folders in the intermediate results folder and
    it prints all the steps, starting from those which are also in the
    preprocessing_steps list, then it prints the remaining folders.

    For each folder it prints the following information:
    - the name of the folder
    - the content of the source_folder.path file
    - the number of files in the files folder
    """
    folders = [
        folder for folder in os.listdir(dir_intermediate_results)
        if os.path.isdir(os.path.join(dir_intermediate_results, folder))
    ]
    processing_steps_names = [step['name'] for step in processing_steps]
    remaining_folders = [
        folder for folder in folders if folder not in processing_steps_names]
    all_folders = processing_steps_names + remaining_folders

    def get_step_with_name(
            name: str,
            processing_steps: List[Dict[str, Any]]
            ) -> Optional[Dict[str, Any]]:
        for step in processing_steps:
            if step['name'] == name:
                return step
        return None

    for folder in all_folders:
        # color red if it is not active
        # one step could ce inactive if:
        # - it is not in the processing_steps list
        # - it is in the processing_steps list but it is disabled (skip: true)
        color = 'green' if folder in processing_steps_names else 'red'
        step_dict = get_step_with_name(folder, processing_steps)
        if step_dict and step_dict.get('skip', False):
            color = 'red'
        folder_path = os.path.join(dir_intermediate_results, folder)
        print(colored(f'Folder: {folder}', color))
        source_folder_path = os.path.join(
            folder_path, 'source_folder.path')
        if os.path.exists(source_folder_path):
            with open(source_folder_path, 'r') as f:
                print(colored(f'  Source folder: {f.read()}', color))
        else:
            print(colored(f'  Source folder: N/A', color))
        files_folder_path = os.path.join(folder_path, 'files')
        if os.path.exists(files_folder_path):
            files = os.listdir(files_folder_path)
            print(colored(f'  Number of files: {len(files)}', color))
        else:
            print(colored(f'  Number of files: N/A', color))
        print('-' * 80)


def prepare_chain_of_processing_steps(
        dir_dataset_folder: str,
        dir_intermediate_results: str,
        processing_steps: List[Dict[str, Any]]) -> None:
    """Prepare the chain of processing steps.

    This function creates a subfolder for each processing step in the
    intermediate results folder.
    Each of these folders will contain the following elements:
    - csv_metadata.path: the path to the file containing the metadata of the
        files which are being processed. (Note: typically each step will point
        to the df_summary.csv file in the dataset folder)
    - source_folder.path: the path to the folder containing the files which are
        being processed. (Note: typically each step will point to the files
        folder of the previous step in the pipeline, except for the first step
        which will point to the raw_files folder in the dataset folder)
    - files: an empty folder where the processed files will be stored.
    """
    for i, step in enumerate(processing_steps):
        # create the folders
        folder_path = os.path.join(dir_intermediate_results, step['name'])
        pathlib.Path(folder_path).mkdir(parents=True, exist_ok=True)
        # create the files folder
        pathlib.Path(os.path.join(folder_path, 'files')).mkdir(
            parents=True, exist_ok=True)
        # create the csv_metadata.path files
        general_metadata_path = os.path.join(dir_dataset_folder, 'df_summary.csv')
        with open(os.path.join(folder_path, 'csv_metadata.path'), 'w') as f:
            f.write(general_metadata_path)
        # create the source_folder.path files
        if i == 0:
            source_folder_path = os.path.join(dir_dataset_folder, 'raw_files')
        else:
            source_folder_path = os.path.join(
                dir_intermediate_results, processing_steps[i - 1]['name'], 'files')
        with open(os.path.join(folder_path, 'source_folder.path'), 'w') as f:
            f.write(source_folder_path)


@cli.command()
@click.option(
    '--config', default='config.json', help='Path to the config file.')
def filterdataset(config):
    """Filter the dataset following the preprocessing steps."""
    config_dict = load_config_and_check(config)
    dir_dataset_folder = config_dict['dataset_folder']

    dir_raw_files = os.path.join(dir_dataset_folder, 'raw_files')
    dir_files_selected = os.path.join(dir_dataset_folder, 'files_selected')
    dir_intermediate_results = \
        os.path.join(dir_dataset_folder, 'intermediate_results')
    pathlib.Path(dir_intermediate_results).mkdir(parents=True, exist_ok=True)
    pathlib.Path(dir_files_selected).mkdir(parents=True, exist_ok=True)

    processing_steps = config_dict['processing_steps']

    prepare_chain_of_processing_steps(
        dir_dataset_folder=dir_dataset_folder,
        dir_intermediate_results=dir_intermediate_results,
        processing_steps=processing_steps,
    )

    print_chain_summary(
        dir_intermediate_results=dir_intermediate_results,
        processing_steps=processing_steps,
    )

    if not click.confirm('Do you want to continue?'):
        return

    for step in processing_steps:
        print(f'Processing step: {step["name"]}')
        function_obj: ProcessingFunction = \
            get_function_from_string(step['function_name'])
        parameters = step.get('parameters', {})
        should_skip = step.get('skip', False)
        if should_skip:
            print('Skipping step.')
            continue
        path_step_dir = os.path.join(dir_intermediate_results, step['name'])
        # read the source_folder.path file to get the path of the source folder
        with open(os.path.join(path_step_dir, 'source_folder.path'), 'r') as f:
            path_source_folder = f.read()
        processor = function_obj(
            name=step['name'],
            prev_step_folder=path_source_folder,
            current_step_folder=path_step_dir)
        processor.run(**parameters)
        processor.save_mapping()
        processor.save_extra_metadata()

    print_chain_summary(
        dir_intermediate_results=dir_intermediate_results,
        processing_steps=processing_steps,
    )
    if not click.confirm('Done. Do you want to continue?'):
        return


@cli.command()
@click.option(
    '--config', default='config.json', help='Path to the config file.')
def createselection(config):
    """Take the programs of the last intermediate step and create a selection."""
    config_dict = load_config_and_check(config)
    dir_dataset_folder = config_dict['dataset_folder']

    dir_files_selected = os.path.join(dir_dataset_folder, 'files_selected')
    pathlib.Path(dir_files_selected).mkdir(parents=True, exist_ok=True)
    dir_intermediate_results = \
        os.path.join(dir_dataset_folder, 'intermediate_results')

    all_steps = config_dict['processing_steps']
    last_step = all_steps[-1]['name']
    print(f'Last step: {last_step}')

    dir_last_step = os.path.join(
        dir_intermediate_results, last_step, 'files')
    mapping_last_step = os.path.join(
        dir_intermediate_results, last_step, 'df_mapping_id_to_filename.csv')
    df_last_step = pd.read_csv(mapping_last_step)
    # keep only rows with filename present in dir_last_step folder
    file_names_last_step = [os.path.basename(f) for f in glob.glob(
        os.path.join(dir_last_step, '*'))]
    df_last_step = df_last_step[
        df_last_step['filename'].isin(file_names_last_step)]
    print(f'Number of files in last step: {len(df_last_step)}')

    original_mapping = os.path.join(
        dir_dataset_folder, 'df_summary.csv')
    # keep unique_id and html_url columns
    df_original_mapping = pd.read_csv(original_mapping)[['unique_id', 'html_url']]

    # merge on unique_id
    df_mapping = df_original_mapping.merge(
        df_last_step, on='unique_id', how='inner')
    # convert to a dictionary mapping from colum filename to column html_url
    mapping = dict(zip(df_mapping['filename'], df_mapping['html_url']))

    # read all the files in dir_last_step and copy them to dir_files_selected
    # while adding html_url as a comment in the file in the first line
    for file_name in tqdm(file_names_last_step):
        with open(os.path.join(dir_last_step, file_name), 'r') as f:
            content = f.read()
        with open(os.path.join(dir_files_selected, file_name), 'w') as f:
            f.write(f'# {mapping[file_name]}\n{content}')


if __name__ == '__main__':
    cli()
