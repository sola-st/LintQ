import os
import pandas as pd
from typing import List, Dict
import hashlib
import json
import shutil
import ast
import multiprocessing
import functools
import re
import numpy as np


from rdlib.datalake import extract_url_hash_filename


def copy_from_files_to(
        all_filenames: List[str],
        input_folder: str,
        output_folder: str) -> pd.DataFrame:
    """Copy the files from the input folder to the output folder.

    Does that in parallel using shutil."""
    with multiprocessing.Pool() as pool:
        func = functools.partial(shutil.copy, dst=output_folder)
        pool.map(func, [
            os.path.join(input_folder, filename)
            for filename in all_filenames])


def is_parsable_safe(code: str):
    """Parse the code using ast, return false if ."""
    try:
        c = ast.parse(code)
        return c is not None
    except:
        return False


def read_file(filename: str, folder: str) -> str:
    """Read the file in the given folder."""
    path = os.path.join(folder, filename)
    with open(path, 'r') as f:
        return f.read()


def remove_unparsable_python(
        df: pd.DataFrame,
        input_folder: str,
        output_folder: str) -> pd.DataFrame:
    """Remove the files that are not parsable by ast.

    Read all the files in the input folder names as the unique_id of the df
    dataframe. For each of them try to parse the code using ast. If the code is
    parsable then keep the file in the output folder.
    Does that in parallel.
    """
    # keep only py files
    df = df[df['unique_id'].str.endswith('.py')]
    all_filenames = df['unique_id'].tolist()
    # read the files in parallel
    with multiprocessing.Pool() as pool:
        func = functools.partial(read_file, folder=input_folder)
        all_contents = pool.map(func, all_filenames)
    # check if the code is parsable (in parallel)
    with multiprocessing.Pool() as pool:
        all_parsability = pool.map(is_parsable_safe, all_contents)
    # keep only the parsable files
    parsability_mask = np.array(all_parsability)
    df = df[parsability_mask]
    # copy the files to the output folder
    copy_from_files_to(
        all_filenames=df['unique_id'].tolist(),
        input_folder=input_folder,
        output_folder=output_folder)
    return df


def clean_lines_starting_with(
        lines: List[str],
        forbidden_starts: List[str] = []) -> List[str]:
    """Remove lines starting with forbidden_starts"""
    return [
        line for line in lines
        if not any([line.lstrip().startswith(start) for start in forbidden_starts])]


def keep_only_py_content_and_save(
        filename: str,
        input_folder: str,
        output_folder: str):
    """Convert the ipynb file and keep only the code.

    The output is saved as a python file in the output folder."""
    file_path = os.path.join(input_folder, filename)
    # read as json file
    with open(file_path, 'r') as f:
        try:
            data = json.load(f)
        except json.decoder.JSONDecodeError:
            print(f'Error reading {filename}')
            return None
    if 'cells' not in data:
        print(f'No cells found in {filename}')
        return None
    # extract the code cells
    code_cells = [
        "".join(cell['source'])
        for cell in data['cells']
        if cell['cell_type'] == 'code']
    # concatenate the code cells
    code = '\n'.join(code_cells)
    new_lines = clean_lines_starting_with(
        code.splitlines(),
        forbidden_starts=['pip', '%', '!'])
    clean_code = '\n'.join(new_lines)
    # save the code in the output folder
    filename = filename.replace('.ipynb', '.py')
    output_path = os.path.join(output_folder, filename)
    with open(output_path, 'w') as f:
        f.write(clean_code)
    return clean_code


def convert_ipynb_to_content_only(
        df: pd.DataFrame,
        input_folder: str,
        output_folder: str):
    """Convert a notebook to a content only version.

    The content only version corresponds to the content of the code cells only.
    Do this in parallel.
    """
    # keep only ipynb files
    is_ipynb_mask = df['unique_id'].str.endswith('.ipynb')
    df_untouched = df[~is_ipynb_mask]
    df_to_convert = df[is_ipynb_mask]
    # all the filenames to convert
    all_filenames = df_to_convert['unique_id'].tolist()
    # convert the notebooks in parallel
    with multiprocessing.Pool() as pool:
        func = functools.partial(
            keep_only_py_content_and_save,
            input_folder=input_folder,
            output_folder=output_folder)
        all_contents = pool.map(func, all_filenames)
    # keep only the filenames that have content not None
    mask = [content is not None for content in all_contents]
    df_to_convert = df_to_convert[mask]
    # replace their name with the new name
    df_to_convert['unique_id'] = df_to_convert['unique_id'].str.replace(
        '.ipynb', '.py', regex=False)
    # move the untouched files to the output folder
    copy_from_files_to(
        all_filenames=df_untouched['unique_id'].tolist(),
        input_folder=input_folder,
        output_folder=output_folder)
    # concatenate the untouched files with the converted ones
    df = pd.concat([df_untouched, df_to_convert])
    return df


def keep_based_on_attribute(
        df: pd.DataFrame,
        input_folder: str,
        output_folder: str,
        attribute: str, values: List[str]) -> pd.DataFrame:
    """Keep the files with the given attribute and value."""
    df = df[df[attribute].isin(values)]
    copy_from_files_to(
        all_filenames=df['unique_id'].tolist(),
        input_folder=input_folder,
        output_folder=output_folder)
    return df


def remove_selected_duplicates(
        df: pd.DataFrame,
        input_folder: str,
        output_folder: str,
        attribute: str, values: List[str]) -> pd.DataFrame:
    """Remove the duplicates of the selected values in the given column."""
    df_untouched = df[~df[attribute].isin(values)]
    df_to_filter = df[df[attribute].isin(values)]
    # sort by the given attribute to reduce non deterministic behaviour
    df_to_filter = df_to_filter.sort_values(by=attribute)
    # drop duplicates for the selected values
    df_to_filter = df_to_filter.drop_duplicates(subset=[attribute])
    # concatenate the two dataframes
    df = pd.concat([df_untouched, df_to_filter])
    copy_from_files_to(
        all_filenames=df['unique_id'].tolist(),
        input_folder=input_folder,
        output_folder=output_folder)
    return df


def filter_out(
        df: pd.DataFrame,
        input_folder: str,
        output_folder: str,
        attribute: str, values: List[str]) -> pd.DataFrame:
    """Filter out the rows with values in the given column."""
    df = df[~df[attribute].isin(values)]
    copy_from_files_to(
        all_filenames=df['unique_id'].tolist(),
        input_folder=input_folder,
        output_folder=output_folder)
    return df


def create_repo_statistic_dataframe(df_summary: pd.DataFrame) -> pd.DataFrame:
    """Create a dataframe with statistics per repository.

    For each repository we count how many files we have and report the
    repository name and description.
    """
    # sorted by frequency of occurence, most frequent first
    df_stats = df_summary.groupby([
        'repository_url', 'repository_description']).count().sort_values(
            by='download_url', ascending=False).reset_index()
    # keep only the columns we need
    df_stats = df_stats[
        ['repository_url', 'repository_description', 'download_url']]
    # rename the columns
    df_stats.columns = ['repository_url', 'repository_description', 'count']
    return df_stats


def create_summary_dataframe(files: List[Dict[str, str]]) -> pd.DataFrame:
    """Compact the list of files to download and metadata into a single csv."""
    df_dataset = pd.DataFrame.from_records(files)
    # drop duplicates
    df_dataset.drop_duplicates(subset=['download_url'], inplace=True)
    # drop forks
    df_dataset = df_dataset[df_dataset['repository_fork'] == False]
    # extract filename from the downalod_url
    df_dataset['filename'] = df_dataset['download_url'].apply(
        lambda x: x.split('/')[-1])

    def get_extension(filename):
        if '.' in filename:
            return filename.split('.')[-1]
        return 'no_ext'

    # extension
    df_dataset['extension'] = df_dataset['filename'].apply(
        lambda x: get_extension(x))
    # filestem
    df_dataset['filestem'] = df_dataset['filename'].apply(
        lambda x: '.'.join(x.split('.')[:-1]))
    # add hash of the download_url as a unique identifier
    df_dataset['hash'] = df_dataset['download_url'].apply(
        lambda x: hashlib.sha256(x.encode('utf-8')).hexdigest()[:6])
    # unique_id = filestem + hash + extension
    df_dataset['unique_id'] = df_dataset['download_url'].apply(
        lambda x: extract_url_hash_filename(x))
    return df_dataset


def remove_too_long_filenames(
        df: pd.DataFrame,
        input_folder: str,
        output_folder: str,
        max_length: int = 100) -> pd.DataFrame:
    """Remove the files with too long filenames."""
    df = df[df['unique_id'].apply(lambda x: len(x) <= max_length)]
    copy_from_files_to(
        all_filenames=df['unique_id'].tolist(),
        input_folder=input_folder,
        output_folder=output_folder)
    return df


def content_regex_filter(
        df: pd.DataFrame,
        input_folder: str,
        output_folder: str,
        regex: str,
        keep_if_match: bool = None,
        remove_if_match: bool = None) -> pd.DataFrame:
    """Keep the files whose content matches the given regex."""
    relevant_files = []
    for filename in df['unique_id'].tolist():
        file_path = os.path.join(input_folder, filename)
        with open(file_path, 'r') as f:
            content = f.read()
        if keep_if_match and re.search(regex, content):
            relevant_files.append(filename)
        elif remove_if_match and not re.search(regex, content):
            relevant_files.append(filename)
    df = df[df['unique_id'].isin(relevant_files)]
    copy_from_files_to(
        all_filenames=df['unique_id'].tolist(),
        input_folder=input_folder,
        output_folder=output_folder)
    return df


def compute_content_hash(filename: str, input_folder: str) -> str:
    """Compute the hash of the content of the file."""
    file_path = os.path.join(input_folder, filename)
    with open(file_path, 'r') as f:
        content = f.read()
    return hashlib.sha256(content.encode('utf-8')).hexdigest()


def add_hash_of_the_content(
        df: pd.DataFrame,
        input_folder: str,
        output_folder: str) -> pd.DataFrame:
    """Add a column with the hash of the content of the file."""
    all_files = df['unique_id'].tolist()
    # do that in parallel
    with multiprocessing.Pool() as pool:
        hashes = pool.map(
            functools.partial(compute_content_hash, input_folder=input_folder),
            all_files)
    df['content_hash'] = hashes
    copy_from_files_to(
        all_filenames=df['unique_id'].tolist(),
        input_folder=input_folder,
        output_folder=output_folder)
    return df


def remove_duplicates(
        df: pd.DataFrame,
        input_folder: str,
        output_folder: str,
        attributes: List[str]) -> pd.DataFrame:
    """Remove the duplicates from the dataframe."""
    df = df.drop_duplicates(subset=attributes)
    copy_from_files_to(
        all_filenames=df['unique_id'].tolist(),
        input_folder=input_folder,
        output_folder=output_folder)
    return df