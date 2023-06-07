"""Run the QChecker static detectors on the given folder."""

import click
import os
import yaml
import pathlib
import ast
import shutil
from tqdm import tqdm
import pandas as pd
import json

from competitors.qchecker_parallel.ast_operations import Ast_parser
from competitors.qchecker_parallel.ast_operations import get_attributes, get_operations
from competitors.qchecker_parallel.qchecker import Qchecker
from competitors.qchecker_parallel.qchecker import checker_IIS, checker_PE, checker_CE, checker_CM
from competitors.qchecker_parallel.qchecker import checker_QE, checker_IG, checker_DO, checker_MI, checker_IM

from multiprocessing import Pool
from functools import partial
from typing import List, Dict, Any, Tuple, Callable


ALL_CHECKERS = {
    'IIS': checker_IIS,
    'PE': checker_PE,
    'CE': checker_CE,
    'CM': checker_CM,
    'IM': checker_IM,
    'QE': checker_QE,
    'IG': checker_IG,
    'DO': checker_DO,
    'MI': checker_MI,
}


ALL_DESCRIPTIONS = {
    'IIS': 'Incorrect initial state',
    'PE': 'Parameters error',
    'CE': 'Call error',
    'CM': 'Command misuse',
    'IM': 'Incorrect measurement',
    'QE': 'QASM error',
    'IG': 'Incorrect uses of quantum gates',
    'DO': 'Discarded orders',
    'MI': 'Measurement related issue',
}


def get_detector_checker(metric_name: str) -> Callable:
    """Return the checker given a specific name."""
    if metric_name in ALL_CHECKERS:
        return ALL_CHECKERS[metric_name]
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
    tree = parse_ast(filepath)
    if tree is not None:
        file_text = open(filepath, 'r').read()
        active_checker = get_detector_checker(metric_name)
        file_lines = file_text.split('\n')

        try:
            astparser = Ast_parser()
            astparser.parser(file_text)
            assign_list = astparser.extract_variable_assign()
            call_list = astparser.extract_function_calls()
            attributes, att_line_numbers = get_attributes(assign_list)
            operations, opt_line_numbers = get_operations(call_list)

            # print('\n')
            # print("QP_Attributes:")
            # print('==========================================')
            # print(attributes)
            # print('\n')

            # print("QP_Operations:")
            # print('==========================================')
            # print(operations)
            # print('\n')

            qc = Qchecker(rules={metric_name: active_checker})
            qc.check(
                attributes, att_line_numbers, operations, opt_line_numbers, file_lines)
            all_warnings = qc.get_report()
        except Exception as e:
            # copy the file in the error folder
            base_name = os.path.basename(filepath)
            dest_path = os.path.join(error_output_folder, base_name)
            shutil.copy(filepath, dest_path)
            print('Error analyzing file %s: %s' % (filepath, e))
            return [{
                'filename': os.path.basename(filepath),
                'checker': metric_name,
                'description': ALL_DESCRIPTIONS[metric_name],
                'line': None,
                'message': f'Error analyzing file: {e}',
                'error': True,
                'error_type': 'analysis_error'
            }]
        if len(all_warnings) > 0:
            # copy the file in the error folder
            base_name = os.path.basename(filepath)
            dest_path = os.path.join(metric_output_folder, base_name)
            shutil.copy(filepath, dest_path)
            return [
                {
                    'filename': os.path.basename(filepath),
                    **warning_info,
                    'error': False,
                    'error_type': None
                }
                for warning_info in all_warnings
            ]
        else:
            return [
                {
                    'filename': os.path.basename(filepath),
                    'checker': metric_name,
                    'description': ALL_DESCRIPTIONS[metric_name],
                    'line': None,
                    'message': 'No warnings to report.',
                    'error': False,
                    'error_type': None
                }
            ]
    else:
        # copy the file in the error folder
        base_name = os.path.basename(filepath)
        dest_path = os.path.join(error_output_folder, base_name)
        shutil.copy(filepath, dest_path)
        return [{
            'filename': os.path.basename(filepath),
            'checker': metric_name,
            'description': ALL_DESCRIPTIONS[metric_name],
            'line': None,
            'message': 'Error parsing file',
            'error': True,
            'error_type': 'parsing_error'
        }]


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
            records_nested = p.map(
                partial(
                    analyze_file,
                    metric_name=metric_name,
                    metric_output_folder=metric_output_folder,
                    error_output_folder=error_output_folder),
                filepaths_to_analyze)

        flattened_records = [
            record
            for records in records_nested
            for record in records
        ]
        # Write the results to a csv file
        df = pd.DataFrame.from_records(flattened_records)
        df.to_csv(
            os.path.join(output_folder, metric_name + '.csv'), index=False)

        # keep all the rows with a line number
        df_warnings = df[df['line'].notnull()]
        # convert into sarif format
        sarif_dict = {
            'version': '2.1.0',
            'runs': [
                {
                    "tool": {
                        'driver': {
                            'name': 'QChecker',
                            'version': '0.1.0',
                            'rules': [
                                {
                                    'id': metric_name,
                                    'name': metric_name,
                                    'shortDescription': {
                                        'text': ALL_DESCRIPTIONS[metric_name]
                                    }
                                }
                            ]
                        }
                    },
                    'results': [
                        {
                            'ruleId': metric_name,
                            'ruleIndex': 0,
                            'level': 'warning',
                            'message': {
                                'text': row['message']
                            },
                            'locations': [
                                {
                                    'physicalLocation': {
                                        'artifactLocation': {
                                            'uri': f"file:///{row['filename']}",
                                            'uriBaseId': '%SRCROOT%'
                                        },
                                        'region': {
                                            'startLine': row['line'],
                                            'startColumn': 1,
                                            'endLine': row['line'],
                                            'endColumn': 1
                                        }
                                    }
                                }
                            ]
                        }
                        for _, row in df_warnings.iterrows()
                    ]
                }
            ]
        }
        with open(os.path.join(output_folder, metric_name + '.sarif'), 'w') as f:
            json.dump(sarif_dict, f, indent=4)


if __name__ == '__main__':
    cli()
