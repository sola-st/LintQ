"""Run the Pylint static detectors on the given folder."""

import click
import os
import yaml
import pathlib
import ast
import shutil
from tqdm import tqdm
import pandas as pd

from multiprocessing import Pool
from functools import partial


def get_metric_class(metric_name: str):
    """Return the class of the metric."""
    raise NotImplementedError()
    if metric_name == 'LPQ':
        return LPQ()
    elif metric_name == 'NC':
        return NC()
    else:
        raise ValueError('Unknown metric name: %s' % metric_name)


def analyze_file(
        filepath: str, metric_name: str,
        metric_output_folder: str,
        error_output_folder: str):
    """Analyze the file and return the metric.

    It uses pylint via: python pylint2sarif.py ex1.py --sarif-output ex1.sarif
    """
    # get current name
    current_name = os.path.basename(filepath)
    # add the sarif extension
    sarif_filepath = os.path.join(
        metric_output_folder, current_name.replace('.py', '.sarif'))
    # get the path of the folder where this file is
    current_folder = os.path.dirname(os.path.abspath(__file__))
    # run pylint
    try:
        os.system(
            f'python {os.path.join(current_folder, "pylint2sarif.py")} ' + \
            f'{filepath} --sarif-output {sarif_filepath}')
    except Exception as e:
        # copy the file to the error folder
        print(f"Error while running pylint on {filepath}: {e}")
        print(f"Copying {filepath} to {error_output_folder}")
        shutil.copy(filepath, error_output_folder)


@click.command()
@click.argument('config_file', type=click.Path(exists=True))
def cli(config_file):
    """Run the analysis on the given folder."""
    with open(config_file) as f:
        config = yaml.safe_load(f)

    input_folder = config['input_folder']
    output_folder = config['output_folder']
    metrics_to_compute = config['metrics_to_compute']
    files_to_focus_on = config.get('subset_files_to_analyze', None)

    # Compute list of files to analyze (in folder input)
    # ending with .py
    filepaths_to_analyze = [
        os.path.join(input_folder, f)
        for f in os.listdir(input_folder)
        if f.endswith('.py')
    ]

    # if a subset file is given, then only analyze the files in the subset
    if files_to_focus_on is not None:
        filepaths_to_analyze = [
            f for f in filepaths_to_analyze
            if os.path.basename(f) in files_to_focus_on
        ]

    # Create the output folder if it does not exist
    pathlib.Path(output_folder).mkdir(parents=True, exist_ok=True)
    for metric_name in metrics_to_compute:
        metric_output_folder = os.path.join(output_folder, metric_name)
        pathlib.Path(metric_output_folder).mkdir(parents=True, exist_ok=True)
        error_output_folder = os.path.join(
            output_folder, metric_name + '_errors')
        pathlib.Path(error_output_folder).mkdir(parents=True, exist_ok=True)
        # # sequential version
        # for filepath in tqdm(filepaths_to_analyze):
        #     analyze_file(
        #         filepath=filepath,
        #         metric_name=metric_name,
        #         metric_output_folder=metric_output_folder,
        #         error_output_folder=error_output_folder)

        # apply the analyze function in parallel and collect all the records
        with Pool() as p:
            records = p.map(
                partial(
                    analyze_file,
                    metric_name=metric_name,
                    metric_output_folder=metric_output_folder,
                    error_output_folder=error_output_folder),
                filepaths_to_analyze)

        # merge all the result in the output folder
        all_sarif_files = [
            os.path.join(metric_output_folder, f)
            for f in os.listdir(metric_output_folder)
            if f.endswith('.sarif')
        ]
        # merge all the sarif files
        # sarif copy [-h] [--output FILE] [--blame-filter FILE]
        #           [--timestamp] [file_or_dir [file_or_dir ...]]
        os.system(
            f'sarif copy --output {os.path.join(output_folder, "data.sarif")} ' + \
            ' '.join(all_sarif_files))


        # # Write the results to a csv file
        # df = pd.DataFrame.from_records(records)
        # df.to_csv(
        #     os.path.join(output_folder, metric_name + '.csv'), index=False)


if __name__ == '__main__':
    cli()
