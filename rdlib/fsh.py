"""
Filesystem Helper (fsh).
Make sure that the experiments are well organized and easily accessible.
"""

import os
import re
import pathlib
from typing import List, Dict, Tuple, Any, Callable
import yaml
import json
from multiprocessing import Pool


def load_config_and_check(config_file: str, required_keys: List[str] = []):
    """Load the config file and check that it has the right keys."""
    with open(config_file, "r") as f:
        config = yaml.load(f, Loader=yaml.FullLoader)
    for key in required_keys:
        assert key in config.keys(), f"Missing key: {key}"
    return config


def create_folder_structure(parent_folder: str, structure: Dict[str, Any]):
    """Create the folder as given by the dictionary.
    Note that the keys are the name of the folders and the values are the
    structures of the respecfive subfolder.
    e.g.
    structure = {
        "root": {
            "a": None,
            "b": None,
            "c": {
                "c_2": None,
                "c_3": None
            }
        }
    }
    """
    for folder_name, sub_folder_structure in structure.items():
        folder_path = os.path.join(parent_folder, folder_name)
        pathlib.Path(folder_path).mkdir(parents=True, exist_ok=True)
        if sub_folder_structure is not None:
            create_folder_structure(folder_path, sub_folder_structure)


def iterate_over(folder, filetype, parse_json=False):
    """
    Iterate over the files in the given folder.
    """
    for file in os.listdir(folder):
        if file.endswith(filetype):
            # open the file and yield it
            with open(os.path.join(folder, file), 'r') as f:
                if parse_json and filetype == '.json':
                    # read json file
                    file_content = json.load(f)
                else:
                    # read any other file
                    file_content = f.read()
                f.close()
            filename_without_extension = file.replace(filetype, "")
            yield filename_without_extension, file_content


def read_json_file(file_path: str) -> Dict[str, Any]:
    """Read a json file."""
    with open(file_path, 'r') as f:
        data = json.load(f)
    return data


def read_data_in_parallel(
        base_folder: str,
        file_type_regex: str,
        read_function: Callable = None,
        n_processes: int = 4) -> List[Any]:
    """
    Read the data in parallel.

    Parameters
    ----------
    - base_folder: str
        The folder where the data is stored.
    - file_type_regex: str
        The regex to filter the files. It can be a regex to filter for a
        specific file type or a regex to filter for a specific file name.
        e.g. "\.json$" or ".*_data.json"
    - read_function: Callable
        The function to read the data. If None, the data is read as a string.
    - n_processes: int
        The number of processes to use.
    """
    # get the list of files to read
    # keep only the files that match the regex
    files = [
        os.path.join(base_folder, f) for f in os.listdir(base_folder)
        if re.search(file_type_regex, f)]
    if read_function is None:
        # read the data as a string
        read_function = lambda x: open(x, 'r').read()
    # read the data in parallel
    with Pool(n_processes) as p:
        data = p.map(read_function, files)
    return data