"""Processing function to transform and/or filter the data.


GUIDE TO IMPLEMENT A NEW FUNCTION:
-----------------
Each processing function must implement a run() which populates the following
attributes:
1. self.mapping (Dict[str, str]): a dictionary that maps the original filename
    (referred to as `unique_id` in the metadata) to the new filename used in
    this folder. The change of name is typical for steps which modify the
    file type (e.g., from .ipynb to .py).
2. self.extra_metadata (pd.DataFrame): a dataframe with extra metadata that
    will be added to the metadata file in the current step folder.
and:
3. stores the new files in the folder self.output_files_folder

AVAILABLE INFOS TO EACH STEP:
-----------------------------
Each step has access to the following information:
- self.metadata (pd.DataFrame) with all the metadata added in the previous steps.
    Note that this also include the metadata coming from the `df_summary.csv`
    which is referred to in the `csv_metadata.path` file in the current step.

IMPORTANT NOTES ON MAPPING:
--------------------------
Each step is allowed to change the name of the file (e.g., by
converting it to a new file type). However, the csv file named
"df_mapping_id_to_filename.csv" must be always created and contain the mapping
between the original filename (referred to as `unique_id` in the metadata) and
the filename of the file in the current step folder.
Note that although some steps can delete the files, they have to retain the
file mentioned in the "df_mapping_id_to_filename.csv" file with an associated
empty file (implemented assigning it to None in the step).
"""
import os
import pandas as pd
from typing import List, Dict, Any
import hashlib
import shutil
from tqdm import tqdm
from concurrent.futures import ProcessPoolExecutor
from shutil import copyfile
from pandarallel import pandarallel
import multiprocessing
import subprocess
import re
import glob
import ast
from qlint.datautils.loop_unroller import LoopUnroller


pandarallel.initialize(progress_bar=True)


class ProcessingFunction(object):
    """A class to represent a processing function.

    A processing function is a function that processes the files in a given
    folder and saves the processed files in another folder.
    To keep track of what has been processed and what is the new file name,
    this class also creates a csv file named df_id_to_filename.csv that contains
    the mapping between the id of the file (as per metadata file) and the new
    file name produced in this step.
    It might also produce extra metadata (in a csv named df_extra_metadata.csv).


    Attributes:
        name: The name of the processing function.
    """

    def __init__(
            self,
            name: str,
            prev_step_folder: str,
            current_step_folder: str):
        """Initialize the processing function.

        Read all the files in the previous step folder (and recursively all
        the previous folders) and load the:
        - metadata (pd.DataFrame) with all the metadata added n the
            previous steps. The column `filename` is added (or replaced) in the
            metadata with the filename of the file in the previous step folder.
        """
        self.name = name
        self.input_folder = prev_step_folder
        self.output_folder = current_step_folder
        self.output_files_folder = os.path.join(
            current_step_folder, 'files')
        prev_base_folder = os.path.dirname(prev_step_folder)

        # read csv_metadata to use in this folder step
        path_metadata = os.path.join(
            current_step_folder, 'csv_metadata.path')
        if os.path.exists(path_metadata):
            with open(path_metadata, 'r') as f:
                self.metadata_path = f.read()
        self.metadata = pd.read_csv(self.metadata_path)

        # get info on the filenames used in the previous folder
        # if present, read the df_mapping_id_to_filename.csv file
        if 'filename' in self.metadata.columns:
            self.metadata = self.metadata.drop(columns=['filename'])
        path_mapping = os.path.join(
            prev_base_folder, 'df_mapping_id_to_filename.csv')
        if os.path.exists(path_mapping):
            self.mapping = pd.read_csv(path_mapping)
            if 'unique_id' in self.mapping.columns:
                self.metadata = self.metadata.merge(
                    self.mapping, on='unique_id', how='left')
            # this will add the column filename to the metadata
        else:
            # add the filename column to the metadata as copy of the unique_id
            self.metadata['filename'] = self.metadata['unique_id']
        prev_extra_metadata = \
            self._read_prev_extra_metadata(prev_base_folder)
        if len(prev_extra_metadata) > 0:
            self.metadata = self.metadata.merge(
                prev_extra_metadata, on='unique_id', how='left')

        # drop all the rows that have a filename that is None
        self.metadata = self.metadata.dropna(subset=['filename'])
        print(f'Number of VALID files in the previous step: {len(self.metadata)}')

        # initialize the mapping
        self.mapping = {}
        self.extra_metadata = {}

    def run(self):
        """Run the processing function.

        This function should be implemented in the subclass.
        Each run function is responsible to save the mapping and the extra
        metadata together with the creation of the files in the output folder.
        """
        raise NotImplementedError

    def _read_prev_extra_metadata(self, folder: str) -> pd.DataFrame:
        """Load the metadata from the previous step folder recursively.

        Collect all the df_extra_metadata.csv files in the folders of the
        previous step and merge them into a single dataframe based on the
        unique_id column.
        """
        # remove the last folder in the folder string
        path_csv_extra_metadata = os.path.join(
            folder, 'df_extra_metadata.csv')
        if os.path.exists(path_csv_extra_metadata):
            try:
                df_extra_metadata = pd.read_csv(path_csv_extra_metadata)
            except pd.errors.EmptyDataError:
                df_extra_metadata = pd.DataFrame()
        else:
            df_extra_metadata = pd.DataFrame()
        # read the source_folder.path file to get the previous folder path
        path_source_folder = os.path.join(folder, 'source_folder.path')
        if os.path.exists(path_source_folder):
            with open(path_source_folder, 'r') as f:
                prev_folder = f.read()
            # recursively read the metadata from the previous folder
            df_extra_metadata_prev = \
                self._read_prev_extra_metadata(prev_folder)
        else:
            df_extra_metadata_prev = pd.DataFrame()
        # join the metadata to whether is found from the previous folders
        # recursively
        if len(df_extra_metadata) > 0 and len(df_extra_metadata_prev) > 0:
            df_result = df_extra_metadata.merge(
                df_extra_metadata_prev, on='unique_id', how='outer')
        elif len(df_extra_metadata_prev) > 0:
            df_result = df_extra_metadata_prev
        elif len(df_extra_metadata) > 0:
            df_result = df_extra_metadata
        else:
            df_result = pd.DataFrame()
        return df_result

    def save_mapping(self):
        """Save the mapping to a csv file."""
        df_mapping = pd.DataFrame(
            self.mapping.items(), columns=["unique_id", "filename"])
        path_mapping = os.path.join(
            self.output_folder, 'df_mapping_id_to_filename.csv')
        df_mapping.to_csv(path_mapping, index=False)

    def save_extra_metadata(self):
        """Save the extra metadata to a csv file.

        The extra metadata is a dictionary of dictionaries.
        Each key of the dictionary is the unique_id of the file.
        The value of the dictionary is another dictionary with the extra
        metadata for that file. They are saved in a csv file with the
        following columns:
        - unique_id: the unique_id of the file
        - metadata_A: the key of the metadata
        - metadata_B: the value of the metadata
        - etc..
        """
        new_records = []
        for unique_id, metadata in tqdm(self.extra_metadata.items()):
            new_records.append(
                {'unique_id': unique_id, **metadata})
        df_extra_metadata = pd.DataFrame.from_records(new_records)
        path_extra_metadata = os.path.join(
            self.output_folder, 'df_extra_metadata.csv')
        df_extra_metadata.to_csv(path_extra_metadata, index=False)


def copy_in_parallel(
        source_folder: str, destination_folder: str,
        file_list: List[str], n_jobs: int = 10):
    """Copy a list of files in parallel."""
    print(f'Copying {len(file_list)} files in parallel...')
    src_list = [os.path.join(source_folder, f) for f in file_list]
    dst_list = [os.path.join(destination_folder, f) for f in file_list]
    with ProcessPoolExecutor(max_workers=n_jobs) as executor:
        executor.map(copyfile, src_list, dst_list)


class RemoveLongNames(ProcessingFunction):

    def run(self, max_length: int = 50):
        """Copy to the output folder all the files in the input folder
        with a length under the given number of characters."""
        for index, row in tqdm(self.metadata.iterrows()):
            filename = row['filename']
            if len(filename) > max_length:
                self.mapping[row['unique_id']] = None
                continue
            self.mapping[row['unique_id']] = filename
        # get the list of all the filenames with a length under the given
        # number of characters
        filenames = list(self.metadata[
            self.metadata['filename'].str.len() <= max_length]['filename'])
        percentage_files_left = len(filenames) / len(self.metadata)
        print(f'{percentage_files_left:.2%} of the files left')
        print(f'Copying {len(filenames)} files to the output folder')
        copy_in_parallel(
            self.input_folder, self.output_files_folder, filenames)
        print('Done')


class AddHashAsExtraMetadata(ProcessingFunction):

    def run(self):
        """Add the hash of the file as extra metadata."""
        for index, row in tqdm(self.metadata.iterrows()):
            filename = row['filename']
            try:
                with open(os.path.join(self.input_folder, filename), 'rb') as f:
                    hash_value = hashlib.md5(f.read()).hexdigest()
                # add the filename to the mapping
                self.mapping[row['unique_id']] = filename
            except FileNotFoundError:
                hash_value = None
            self.extra_metadata[row['unique_id']] = {
                'hash_content': hash_value}
        # get all filenames in mapping which are not None
        filenames = [
            filename for filename in self.mapping.values()
            if filename is not None]
        copy_in_parallel(
            self.input_folder, self.output_files_folder, filenames)


class RemoveDuplicates(ProcessingFunction):

    def run(self, attributes: List[str] = None):
        """Copy to the output folder all the files in the input folder
        but removing the duplicates."""
        metadata_no_duplicates = self.metadata.drop_duplicates(
            subset=attributes)
        for index, row in metadata_no_duplicates.iterrows():
            filename = row['filename']
            self.mapping[row['unique_id']] = filename
            shutil.copy(
                os.path.join(self.input_folder, filename),
                os.path.join(self.output_files_folder, filename))
        # set the mapping to None for the duplicates
        for index, row in self.metadata.iterrows():
            if row['unique_id'] not in self.mapping:
                self.mapping[row['unique_id']] = None


class KeepBasedOnAttributeValue(ProcessingFunction):

    def run(self, attribute: str, values: List[str]):
        """Copy to the output folder all the files in the input folder
        which have the given value for the given attribute."""
        for index, row in tqdm(self.metadata.iterrows()):
            filename = row['filename']
            if row[attribute] in values:
                self.mapping[row['unique_id']] = filename
            else:
                self.mapping[row['unique_id']] = None
        # get all filenames in mapping which are not None
        filenames = [
            filename for filename in self.mapping.values()
            if filename is not None]
        copy_in_parallel(
            self.input_folder, self.output_files_folder, filenames)


class RemoveBasedOnAttributeValue(ProcessingFunction):

    def run(self, attribute: str, values: List[str]):
        """Copy to the output folder all the files in the input folder
        which do not have the given value for the given attribute."""
        for index, row in tqdm(self.metadata.iterrows()):
            filename = row['filename']
            if row[attribute] not in values:
                self.mapping[row['unique_id']] = filename
            else:
                self.mapping[row['unique_id']] = None
        # get all filenames in mapping which are not None
        filenames = [
            filename for filename in self.mapping.values()
            if filename is not None]
        copy_in_parallel(
            self.input_folder, self.output_files_folder, filenames)


class ConvertNotebooksToScripts(ProcessingFunction):

    def run(self, max_workers: int = 10):
        """Convert the python notebooks to python files.

        Remember to rename the filename of the current files in the mapping.
        """
        n_ipynb = len(
            self.metadata[self.metadata['filename'].str.endswith('.ipynb')])
        print(f'Converting {n_ipynb} notebooks to scripts')
        # for index, row in tqdm(self.metadata.iterrows()):
        #     filename = row['filename']
        #     if filename.endswith('.ipynb'):
        #         self.mapping[row['unique_id']] = filename[:-6] + '.py'
        #         if not self._try_nbconversion(os.path.join(self.input_folder, filename)):
        #             self.mapping[row['unique_id']] = None
        #     else:
        #         self.mapping[row['unique_id']] = filename
        # parallel
        all_ipynb_filenames = [
            filename for filename in self.metadata['filename']
            if filename.endswith('.ipynb')]
        all_ipynb_paths = [
            os.path.join(self.input_folder, filename)
            for filename in all_ipynb_filenames]
        all_ipynb_paths_dest = [
            self.output_files_folder for _ in all_ipynb_paths]
        with ProcessPoolExecutor(max_workers=max_workers) as executor:
            is_successful_execution = executor.map(
                self._try_nbconversion, all_ipynb_paths, all_ipynb_paths_dest)
        # check how many 429 errors occurred
        import glob
        import re
        files = glob.glob(self.output_files_folder + '/*.py')
        n_429_errors = 0
        # iterate over all files
        for file in tqdm(files):
            # open file
            with open(file, 'r') as f:
                # read file
                content = f.read()
                # check if string is in file
                if re.search('429: Too Many Requests', content):
                    n_429_errors += 1
        print(f'Number of 429 errors: {n_429_errors}')
        # update the mapping of all successful executions
        for unique_id, filename, is_successful in zip(
                self.metadata['unique_id'],
                self.metadata['filename'],
                is_successful_execution):
            if is_successful:
                self.mapping[unique_id] = filename[:-6] + '.py'
            else:
                self.mapping[unique_id] = None
        # add the original filenames (not ipynb) to the mapping
        metadata_not_ipynb = self.metadata[
            ~self.metadata['filename'].str.endswith('.ipynb')]
        original_filenames = []
        for unique_id, filename in zip(
                metadata_not_ipynb['unique_id'],
                metadata_not_ipynb['filename']):
            self.mapping[unique_id] = filename
            original_filenames.append(filename)
        copy_in_parallel(
            self.input_folder, self.output_files_folder, original_filenames)

    def _try_nbconversion(self, filepath: str, output_files_folder: str):
        """Try to convert to convert to script with nbconvert.

        Return False if an error occurred, True otherwise.
        """
        # check if the output .py file already exists
        base_name = os.path.basename(filepath)
        if os.path.exists(
                os.path.join(output_files_folder, base_name[:-6] + '.py')):
            return True
        try:
            # run and collect the output
            output = subprocess.check_output(
                ['jupyter', 'nbconvert', '--to', 'script', filepath, '--output-dir', output_files_folder],
                stderr=subprocess.STDOUT)
            return True
        except subprocess.CalledProcessError as e:
            output_error = e.output.decode('utf-8')
            print(f'ipynb: Error converting {filepath}. Output: {output_error}')
            return False


class ContentRegexFilter(ProcessingFunction):

    def run(self, regex: str, keep_if_match: bool = True):
        """Filter the files based on the content of the file.

        keep_if_match = True
            copy to the output folder all the files in the input folder
            which contains the given regex.
        keep_if_match = False
            copy everything except the files which contain the regex.
        """
        regex = regex.replace('\\\\', '\\')
        print(f'Filtering based on regex: {regex}')
        for index, row in tqdm(self.metadata.iterrows()):
            filename = row['filename']
            with open(os.path.join(self.input_folder, filename), 'r') as f:
                content = f.read()
            if keep_if_match:
                if re.findall(regex, content, re.MULTILINE):
                    self.mapping[row['unique_id']] = filename
                else:
                    self.mapping[row['unique_id']] = None
            elif not keep_if_match:
                if re.findall(regex, content, re.MULTILINE):
                    self.mapping[row['unique_id']] = None
                else:
                    self.mapping[row['unique_id']] = filename
        # get all filenames in mapping which are not None
        filenames = [
            filename for filename in self.mapping.values()
            if filename is not None]
        copy_in_parallel(
            self.input_folder, self.output_files_folder, filenames)


class RemoveUnparsable(ProcessingFunction):

    def run(self, max_workers: int = 10):
        """Remove all files which are not parsable by ast.parse."""
        print('Removing all files which are not parsable by ast.parse')
        # for index, row in tqdm(self.metadata.iterrows()):
        #     filename = row['filename']
        #     if self._try_to_parse(os.path.join(self.input_folder, filename)):
        #         self.mapping[row['unique_id']] = filename
        #     else:
        #         self.mapping[row['unique_id']] = None
        # get all filenames in mapping which are not None
        metadata_py = self.metadata[
            self.metadata['filename'].str.endswith('.py')]
        all_py_filenames = metadata_py['filename'].values
        all_unique_ids = metadata_py['unique_id'].values
        all_py_paths = [
            os.path.join(self.input_folder, filename)
            for filename in all_py_filenames]
        with ProcessPoolExecutor(max_workers=max_workers) as executor:
            is_successful_parsing = executor.map(
                self._try_to_parse, all_py_paths)
        # update the mapping of all successful executions
        for unique_id, filename, is_successful in zip(
                all_unique_ids, all_py_filenames, is_successful_parsing):
            if is_successful:
                self.mapping[unique_id] = filename
            else:
                self.mapping[unique_id] = None
        # get all filenames in mapping which are not None
        filenames_to_keep = [
            filename for filename in self.mapping.values()
            if filename is not None]
        copy_in_parallel(
            self.input_folder, self.output_files_folder, filenames_to_keep)

    def _try_to_parse(self, filepath: str):
        """Try to parse the file with ast.parse.

        Return False if an error occurred, True otherwise.
        """
        try:
            # run and collect the output
            with open(filepath, 'r') as f:
                content = f.read()
            ast.parse(content)
            return True
        except Exception as e:
            print(f'Error parsing {filepath}. Output: {e}')
            return False


class UnrollLoops(ProcessingFunction):

    def run(self, max_iterations: int = 20):
        """Unroll all loops in the files."""
        self.max_iterations = max_iterations
        all_filenames = self.metadata['filename'].values
        all_unique_ids = self.metadata['unique_id'].values
        all_paths = [
            os.path.join(self.input_folder, filename)
            for filename in all_filenames]
        with ProcessPoolExecutor(max_workers=10) as executor:
            unrolled_files = executor.map(
                self._convert_to_unrolled_file, all_paths)
        # the mapping is the same as the original one
        self.mapping = {
            unique_id: filename
            for unique_id, filename in zip(all_unique_ids, all_filenames)}
        # write the unrolled files
        for filename, unrolled in tqdm(zip(all_filenames, unrolled_files)):
            with open(os.path.join(self.output_files_folder, filename), 'w') as f:
                f.write(unrolled)

    def _convert_to_unrolled_file(self, filepath: str):
        """Convert the file to an unrolled version."""
        with open(filepath, 'r') as f:
            content = f.read()
        loop_unroller = LoopUnroller(max_iterations=self.max_iterations)
        unrolled = loop_unroller.unroll_program(content)
        return unrolled


