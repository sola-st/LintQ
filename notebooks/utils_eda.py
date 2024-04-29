"""Utilities for data exploration of the dataset."""

import os
import sys
from multiprocessing import Pool
from functools import partial
from typing import List
from tqdm import tqdm
import ast
import pandas as pd


MAGIC_STRING = 'MAGIC_STRING_LINTQ_123456'


# gate mapping list

map_to_lower_gate_name = {
    'C3XGate': 'mcx',
    'C3SXGate': 'mcx',
    'C4XGate': 'mcx',
    'CCXGate': 'ccx',
    'DCXGate': 'dcx',
    'CHGate': 'ch',
    'CPhaseGate': 'cp',
    'CRXGate': 'crx',
    'CRYGate': 'cry',
    'CRZGate': 'crz',
    'CCZGate': 'ccz',
    'CSwapGate': 'cswap',
    'CSXGate': 'csx',
    'CUGate': 'cu',
    'CU1Gate': 'cu1',
    'CU3Gate': 'cu3',
    'CXGate': 'cx',
    'CYGate': 'cy',
    'CZGate': 'cz',
    'HGate': 'h',
    'IGate': 'id',
    'PhaseGate': 'p',
    'RGate': 'r',
    'RCCXGate': 'rccx',
    'RC3XGate': 'rcccx',
    'RXGate': 'rx',
    'RXXGate': 'rxx',
    'RYGate': 'ry',
    'RYYGate': 'ryy',
    'RZGate': 'rz',
    'RZZGate': 'rzz',
    'RZXGate': 'rzx',
    'ECRGate': 'ecr',
    'SGate': 's',
    'SdgGate': 'sdg',
    'SwapGate': 'swap',
    'iSwapGate': 'iswap',
    'SXGate': 'sx',
    'SXdgGate': 'sxdg',
    'TGate': 't',
    'TdgGate': 'tdg',
    'UGate': 'u',
    'U1Gate': 'u1',
    'U2Gate': 'u2',
    'U3Gate': 'u3',
    'XGate': 'x',
    'YGate': 'y',
    'ZGate': 'z',
    'CSdgGate': 'csdg',
    'CSGate': 'cs',
    'MSGate': 'ms',
    'Barrier': 'barrier',
    'Measure': 'measure',
    'Reset': 'reset',
    'measure_all': 'measure_all'
}


def extract_imported_classes(code: str) -> List[str]:
    """Extract all the imported classes from the python code.

    e.g.:
    code = '''
    import numpy as np
    import pandas as pd
    from sklearn import linear_model
    from sklearn.linear_model import LogisticRegression
    '''
    extract_imported_classes(code)
    >>> ['numpy', 'pandas', 'sklearn.linear_model', 'sklearn.linear_model.LogisticRegression']
    """
    # Parse the code
    tree = ast.parse(code)

    # Extract the imported classes
    imported_classes = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            imported_classes += [n.name for n in node.names]
        elif isinstance(node, ast.ImportFrom):
            imported_classes.append(node.module + '.' + node.names[0].name)

    return imported_classes


def extract_api_calls(code: str) -> List[str]:
    """Extract all the API calls from the python code.

    e.g.:
    code = '''
    import numpy as np
    import pandas as pd

    X = np.array([[1, 2], [3, 4]])
    df = pd.DataFrame(X)
    '''
    extract_api_calls(code)
    >>> ['np.array', 'pd.DataFrame']
    """
    # Parse the code
    tree = ast.parse(code)

    # Extract the API calls
    api_calls = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Call):
            api_calls.append(node.func.attr if hasattr(node.func, 'attr') else node.func.id)

    return api_calls


def get_register_sizes(code: str) -> List[str]:
    """Extract all the register sizes from the python code.

    e.g.:
    code = '''
    from qiskit import QuantumRegister, ClassicalRegister, QuantumCircuit

    qr = QuantumRegister(2)
    cr = ClassicalRegister(2)
    qc = QuantumCircuit(qr, cr)
    qc2 = QuantumCircuit(10)
    '''
    get_register_sizes(code)
    >>> ['2', '2', '10']
    """
    # Parse the code
    tree = ast.parse(code)

    # Extract the register sizes
    register_sizes = []
    for node in ast.walk(tree):
        # check if the QuantumRegister has integer argument
        if isinstance(node, ast.Call) and hasattr(node.func, 'id') and node.func.id == 'QuantumRegister':
            if len(node.args) == 1 and isinstance(node.args[0], ast.Num):
                n_qubits = node.args[0].n
                register_sizes.append([n_qubits, "q"])

        # check if the ClassicalRegister has integer argument
        if isinstance(node, ast.Call) and hasattr(node.func, 'id') and node.func.id == 'ClassicalRegister':
            if len(node.args) == 1 and isinstance(node.args[0], ast.Num):
                n_bits = node.args[0].n
                register_sizes.append([n_bits, "c"])

        # check if the QuantumCircuit argument is a number
        if isinstance(node, ast.Call) and hasattr(node.func, 'id') and node.func.id == 'QuantumCircuit':
            if len(node.args) == 1 and isinstance(node.args[0], ast.Num):
                n_qubits = node.args[0].n
                register_sizes.append([n_qubits, "q"])
            if len(node.args) == 2 and isinstance(node.args[0], ast.Num) and isinstance(node.args[1], ast.Num):
                n_qubits = node.args[0].n
                n_bits = node.args[1].n
                register_sizes.append([n_qubits, "q"])
                register_sizes.append([n_bits, "c"])

    return register_sizes


def read_file(file_name: str, path_dir: str) -> pd.DataFrame:
    """Reads the content of a file.

    It returns a dataframe with columns: 'file_name', 'content'
    """
    # Read the file
    with open(os.path.join(path_dir, file_name), 'r') as file:
        content = file.read()
    global MAGIC_STRING
    try:
        classes = extract_imported_classes(content)
    except Exception as e:
        # print('Error: {}'.format(e))
        classes = [MAGIC_STRING + str(e)]

    try:
        api_calls = extract_api_calls(content)
    except Exception as e:
        # print('Error: {}'.format(e))
        api_calls = [MAGIC_STRING + str(e)]

    try:
        register_sizes = get_register_sizes(content)
    except Exception as e:
        # print('Error: {}'.format(e))
        register_sizes = [MAGIC_STRING + str(e)]

    # Create a dataframe
    df = pd.DataFrame({
        'file_name': [file_name],
        'content': [content],
        'classes': [classes],
        'api_calls': [api_calls],
        'register_sizes': [register_sizes]
    })

    return df


def read_files_in_parallel(list_files: List[str], folder: str) -> pd.DataFrame:
    """Reads the content of the files in parallel.

    It returns a dataframe with columns: 'file_name', 'content'
    """
    # Create a partial function with the fixed arguments
    read_file_partial = partial(read_file, path_dir=folder)

    # Create a pool of workers
    pool = Pool()

    # Read the files in parallel
    list_df = list(tqdm(pool.imap(
        read_file_partial, list_files), total=len(list_files)))

    # Close the pool
    pool.close()

    # Concatenate the dataframes
    df = pd.concat(list_df, ignore_index=True)

    return df


def get_dataset_level_list(df: pd.DataFrame, attribute: str) -> pd.DataFrame:
    """Explode the given attribute and return a list of all the values.

    Note that this will drop the element with empty lists on that attribute.
    """
    # Keep only the columns of interest
    df = df[['file_name', attribute]]
    # Explode the attribute
    df = df.explode(attribute)
    # Drop NaN values
    df = df.dropna(subset=[attribute])
    # rename the attribute by removing the 's' at the end
    if attribute[-1] == 's':
        df = df.rename(columns={attribute: attribute[:-1]})
    return df
