"""Run the QSmell static detectors on the given folder."""

import click
import os
import yaml
import pathlib
import ast
import shutil
from tqdm import tqdm
import pandas as pd

from  competitors.qsmell_static.LPQ import LPQ
from competitors.qsmell_static.NC import NC
from competitors.qsmell_static.ISmell import ISmell

from multiprocessing import Pool
from functools import partial


def get_metric_class(metric_name: str) -> ISmell:
    """Return the class of the metric."""
    if metric_name == 'LPQ':
        return LPQ()
    elif metric_name == 'NC':
        return NC()
    else:
        raise ValueError('Unknown metric name: %s' % metric_name)


def parse_ast(py_filepath: str) -> ast.Module:
    """Open the file and parse its ast."""
    try:
        with open(py_filepath) as f:
            tree = ast.parse(f.read())
            return tree
    except Exception as e:
        print('Error parsing file %s: %s' % (py_filepath, e))
        return None


def analyze_file(
        filepath: str, metric_name: str,
        metric_output_folder: str,
        error_output_folder: str):
    """Analyze the file and return the metric."""
    metric_object = get_metric_class(metric_name)
    tree = parse_ast(filepath)
    if tree is not None:
        csv_base_name = \
            os.path.basename(filepath).replace('.py', '.csv')
        csv_out_path = os.path.join(
            metric_output_folder, csv_base_name)
        metric_value = metric_object.compute_metric(tree, csv_out_path)
        return {
            'filename': os.path.basename(filepath),
            'metric': metric_name,
            'value': metric_value
        }
    else:
        # copy the file in the error folder
        base_name = os.path.basename(filepath)
        dest_path = os.path.join(error_output_folder, base_name)
        shutil.copy(filepath, dest_path)
        return {
            'filename': os.path.basename(filepath),
            'metric': metric_name,
            'value': 'error'
        }


@click.command()
@click.argument('config_file', type=click.Path(exists=True))
def cli(config_file):
    """Run the analysis on the given folder."""
    with open(config_file) as f:
        config = yaml.safe_load(f)

    input_folder = config['input_folder']
    output_folder = config['output_folder']
    metrics_to_compute = config['metrics_to_compute']

    # Compute list of files to analyze (in folder input)
    # ending with .py
    filepaths_to_analyze = [
        os.path.join(input_folder, f)
        for f in os.listdir(input_folder)
        if f.endswith('.py')
    ]

    # Create the output folder if it does not exist
    pathlib.Path(output_folder).mkdir(parents=True, exist_ok=True)
    for metric_name in metrics_to_compute:
        metric_output_folder = os.path.join(output_folder, metric_name)
        pathlib.Path(metric_output_folder).mkdir(parents=True, exist_ok=True)
        error_output_folder = os.path.join(
            output_folder, metric_name + '_errors')
        pathlib.Path(error_output_folder).mkdir(parents=True, exist_ok=True)
        # apply the analyze function in parallel and collect all the records
        with Pool() as p:
            records = p.map(
                partial(
                    analyze_file,
                    metric_name=metric_name,
                    metric_output_folder=metric_output_folder,
                    error_output_folder=error_output_folder),
                filepaths_to_analyze)

        # Write the results to a csv file
        df = pd.DataFrame.from_records(records)
        df.to_csv(
            os.path.join(output_folder, metric_name + '.csv'), index=False)


if __name__ == '__main__':
    cli()
