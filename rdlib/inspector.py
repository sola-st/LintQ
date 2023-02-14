'''Select a random file and show it to the user.

This script randomly picks a "java" file from the list of all java files
'''

import random
import os
import sys
import click
import yaml
import json
from typing import Dict, List, Any, Callable
import tinydb
from os.path import join
from tinydb import TinyDB, Query
import time
import re
from sarif import loader
from deprecated import deprecated
import hashlib
from termcolor import colored


class SkipNextFileException(Exception):
    """Raise this exception to skip the next file."""

    pass


def get_open_function(config_dict: Dict[str, Any]):
    """Get the corresponding file opening function."""
    def open_vscode(filename):
        os.system(f'code {filename}')
    mode = config_dict.get('file_inspection').get('file_open_command')
    if mode == "vscode":
        return open_vscode


def single_query(attribute_name: str, type: str) -> str:
    """Ask the user a single query."""
    print(f"{attribute_name}? (Enter if not applicable.)")
    attribute_value = input()
    if type == "str":
        attribute_value = str(attribute_value)
    elif type == "int":
        attribute_value = int(attribute_value)
    # escape the value to prepare for json file
    attribute_value = attribute_value.replace('"', '\\"')
    return attribute_value


def query_user_for_attributes(
        attributes_to_log_dict: Dict[str, Any], fields_to_exclude: List[str]):
    """Ask the user the attributes for this inspection."""
    print("Please annotate the current file with the following attributes:")
    all_attributes = attributes_to_log_dict.keys()
    all_attributes_values = {}
    for attribute_name in all_attributes:
        if attribute_name in fields_to_exclude:
            continue
        if attributes_to_log_dict[attribute_name].get('values', None):
            current_answer = \
                query_multiple_choice(
                    choices=attributes_to_log_dict[attribute_name]['values'])
        else:
            current_answer = \
                single_query(
                    attribute_name=attribute_name,
                    type=attributes_to_log_dict[attribute_name]['type'])
        all_attributes_values[attribute_name] = current_answer
        if current_answer == "skip":
            raise SkipNextFileException
    return all_attributes_values


@deprecated(version='0.0.1', reason="You should use pick_random_static_analysis_result")
def pick_random(
        all_file_paths: List[str], all_projects: List[str], sampling_mode: str):
    """Pick a path randomly."""
    if sampling_mode == 'random':
        # randomly select a file
        random_file_path = random.choice(all_file_paths)
    elif sampling_mode == 'stratified':
        i_project = random.choice(all_projects)
        # keep only the part after the /
        i_project = i_project.split("/")[-1]
        print("project:", i_project)
        # get all the paths for the random project
        all_i_project_paths = [
            path for path in all_file_paths if i_project in path]
        # randomly select a file
        random_file_path = random.choice(all_i_project_paths)
    return random_file_path


def pick_random_static_analysis_result(
        static_analysis_results: List[Dict[str, Any]],
        sampling_mode: str,
        code_filter: str = None):
    """Pick a static analysis result randomly."""
    if sampling_mode == 'random':
        pass
    elif sampling_mode == 'stratified':
        all_codes = [
            result["ruleId"] for result in static_analysis_results]
        if len(all_codes) == 0:
            print(colored("No more results to annotate.", 'green'))
            sys.exit(0)
        code_filter = random.choice(all_codes)
    if code_filter is not None:
        # keep only the results with the right code
        static_analysis_results = [
            result for result in static_analysis_results
            if result["ruleId"] == code_filter]
    if len(static_analysis_result) == 0:
        print(colored("No more results to annotate.", 'green'))
        sys.exit(0)
    # randomly select a file
    static_analysis_result = \
        random.choice(static_analysis_results)
    return static_analysis_result


def time_loop(max_time_in_minutes: int, function_to_call: Callable):
    """Call the same function until the timer has expired.

    Note the time must be in minutes.
    """
    start_time = time.time()
    while True:
        function_to_call()
        if (time.time() - start_time) / 60 > max_time_in_minutes:
            break


def remove_already_annotated_results(
        static_analysis_results: List[Dict[str, Any]],
        sarif_path: str,
        config_dict):
    """Remove the results already annotated."""
    db_annotation_path = join(
        config_dict["annotation_folder"], 'annotations.json'
    )
    already_present_pairs = get_already_inspected_files(
        tiny_db_path=db_annotation_path,
        sarif_path=sarif_path)

    # keep only results which are not already annotated
    static_analysis_results = [
        result
        for result in static_analysis_results
        # hash the partialFingerprints filed of result
        if (
                hashlib.sha256(str(result["partialFingerprints"]).encode('utf-8')).hexdigest()[:6],
                sarif_path
            ) not in already_present_pairs]
    return static_analysis_results


def single_inspection_task(
        config_dict: Dict[str, Any],
        static_analysis_results: Dict[str, Any],
        root_path: str,
        code_filter: str,
        sarif_path: str,
        open_function: Callable,
        db: TinyDB):
    """Perform a single inspection task."""
    # remove static analysis results already annotated
    static_analysis_results = remove_already_annotated_results(
        static_analysis_results=static_analysis_results,
        sarif_path=sarif_path,
        config_dict=config_dict)
    static_analysis_result = \
        pick_random_static_analysis_result(
            static_analysis_results=static_analysis_results,
            sampling_mode=config_dict["sampling_mode"],
            code_filter=code_filter)
    physical_loc = static_analysis_result["locations"][0]["physicalLocation"]
    basepath = physical_loc["artifactLocation"]["uri"]
    line = physical_loc["region"].get("startLine", 1)
    column = physical_loc["region"].get("startColumn", 1)
    filepath = os.path.join(root_path, basepath) + ":" + str(line) + ":" + str(column)
    goto_filepath = '--goto "' + filepath + '"'
    print(filepath)
    msg = static_analysis_result["message"]["text"]
    print("Message: ", colored(msg, "red"))
    # open the file
    open_function(goto_filepath)
    field_name_for_path = config_dict["file_inspection"]["filepath_field_name"]
    # ask the user for attributes
    try:
        new_record = query_user_for_attributes(
            attributes_to_log_dict=config_dict["attributes_to_log"],
            fields_to_exclude=[field_name_for_path])
        new_record[field_name_for_path] = filepath.strip()
        new_record["sarif_path"] = config_dict["sarif_path"]
        new_record["hash"] = hashlib.sha256(
            str(static_analysis_result["partialFingerprints"]).encode('utf-8')).hexdigest()[:6]
        # write the record to the json file with
        db.insert(new_record)
    except SkipNextFileException:
        return


def get_already_inspected_files(tiny_db_path: str, sarif_path: str):
    """Get the list of already inspected files."""
    db = TinyDB(tiny_db_path)
    all_records = db.all()
    already_present_pairs = [
        (record["hash"], sarif_path)
        for record in all_records
        if record["sarif_path"] == sarif_path]
    return already_present_pairs


def query_multiple_choice(choices: List[str]) -> str:
    """Query the user for a choice among a list of choices."""
    for i, choice in enumerate(choices):
        print(f"{i}: {choice}")
    choice = input("Please select a number: ")
    return choices[int(choice)]


@click.command()
@click.option('--config', default='config/inspection_v01.yaml', help='The config file')
@click.option('--sarif_path', default=None, help='The sarif file path containing the warnings, if not specified in the config file')
@click.option('--code_filter', default=None, help='The warning code to filter on')
def cli(config, sarif_path, code_filter):
    """Select a random file and show it to the user."""
    with open(config, 'r') as f:
        config_dict = yaml.load(f, Loader=yaml.FullLoader)
    if sarif_path is None:
        sarif_path = config_dict["sarif_path"]
    sarif_run = int(config_dict["sarif_run"])
    sarif_file = loader.load_sarif_file(sarif_path)
    sarif_data = sarif_file.data
    results = sarif_data["runs"][sarif_run]["results"]

    # connect to the database
    db_annotation_path = join(
        config_dict["annotation_folder"], 'annotations.json'
    )
    db = TinyDB(db_annotation_path)
    already_present_pairs = get_already_inspected_files(
        tiny_db_path=db_annotation_path,
        sarif_path=sarif_path)

    # keep only results which are not already annotated
    static_analysis_results = [
        result
        for result in results
        # hash the partialFingerprints filed of result
        if (
                hashlib.sha256(str(result["partialFingerprints"]).encode('utf-8')).hexdigest()[:6],
                sarif_path
            ) not in already_present_pairs]

    open_function = get_open_function(config_dict)

    fixed_parameters = {
        "config_dict": config_dict,
        "static_analysis_results": static_analysis_results,
        "root_path": config_dict["root_path"],
        "code_filter": code_filter,
        "sarif_path": sarif_path,
        "open_function": open_function,
        "db": db
    }
    inspection_budget = config_dict["inspection_budget"]
    single_inspection_task_w_params = \
        lambda: single_inspection_task(**fixed_parameters)
    if inspection_budget:
        if re.match(r'\d+min', inspection_budget):
            max_time_in_minutes = int(inspection_budget[:-3])
            time_loop(
                max_time_in_minutes=max_time_in_minutes,
                function_to_call=single_inspection_task_w_params)
        elif re.match(r'\d+files', inspection_budget):
            max_files = int(inspection_budget[:-5])
            for _ in range(max_files):
                single_inspection_task_w_params()
    else:
        while True:
            single_inspection_task_w_params()


if __name__ == '__main__':
    cli()
