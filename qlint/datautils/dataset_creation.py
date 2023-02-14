"""This file is responsible for scraping the dataset of quantum programs."""

import os
import click
import yaml
import pathlib
import pandas as pd

from typing import List, Dict, Any, Tuple


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

    processing_steps = config_dict['processing_steps']

    df_summary = pd.read_csv(
        os.path.join(dir_dataset_folder, 'df_summary.csv'))
    df_current = df_summary

    dir_input = dir_raw_files
    for i, step_info in enumerate(processing_steps):
        print("-" * 80)
        print(f'Running processing step {step_info["name"]}...')
        dir_name = f'{i}_{step_info["name"]}'
        dir_output = os.path.join(dir_intermediate_results, dir_name)
        pathlib.Path(dir_output).mkdir(parents=True, exist_ok=True)
        processing_function = get_function(
            function_name=step_info['function_name'])
        df_next = processing_function(
            df_current,
            input_folder=dir_input,
            output_folder=dir_output,
            **step_info.get('parameters', {}))
        df_next.to_csv(
            os.path.join(dir_output, f'df_{i}_{step_info["name"]}.csv'),
            index=False)
        df_current = df_next
        dir_input = dir_output
        print(f'Output size: {len(df_current)}')



@cli.command()
@click.option(
    '--config', default='config.json', help='Path to the config file.')
def createselection(config):
    """Take the programs of the last intermediate step and create a selection."""
    config_dict = load_config_and_check(config)
    dir_dataset_folder = config_dict['dataset_folder']

    dir_files_selected = os.path.join(dir_dataset_folder, 'files_selected')
    dir_intermediate_results = \
        os.path.join(dir_dataset_folder, 'intermediate_results')

    all_steps = os.listdir(dir_intermediate_results)
    last_step = sorted(all_steps)[-1]

    dir_last_step = os.path.join(
        dir_intermediate_results, last_step)
    # copy the content of the last step to the files_selected folder
    print(f'Copying the content of {dir_last_step} to {dir_files_selected}...')
    shutil.copytree(dir_last_step, dir_files_selected)



if __name__ == '__main__':
    cli()

