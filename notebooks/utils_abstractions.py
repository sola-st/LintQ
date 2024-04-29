"""Utilities for parsing infor from CodeQL abstractions."""

import re
from typing import List, Dict
import pandas as pd
import glob


def read_files(folder: str, extension: str = ".ql") -> Dict[str, str]:
    """Read all files with the given extension in the folder and subfolders."""
    ql_files = {}
    for file in glob.glob(folder + f'/**/*{extension}', recursive=True):
        with open(file, 'r') as f:
            content = f.read()
            ql_files[file.replace(folder, "")] = content
    return ql_files


def get_abstractions_used(content: str) -> List[str]:
    """Get the abstractions used in the given content."""
    abstractions = []
    for line in content.splitlines():
        if line.startswith('import'):
            abstraction = line.split(' ')[1]
            abstractions.append(abstraction)
    return abstractions


def get_abstractions_from_qll(content: str) -> List[str]:
    """Get the abstractions used in the given content.

    It uses regex."""
    # get: class TestClass()
    classes = re.findall(r'^class (\w+)', content, re.MULTILINE)
    return classes


def get_predicates_from_qql(content: str) -> List[str]:
    """Get the predicates used in the given content.

    It uses regex."""
    # get also: predicate testPredicate(
    predicates = re.findall(r'^predicate (\w+)', content, re.MULTILINE)
    return predicates


def check_abstractions_used(abstraction: List[str], content: str) -> bool:
    """Check if the given abstraction is used in the content.

    Via regex.
    """
    abstractions_used = []
    for a in abstraction:
        if re.search(rf'\b{a}\b', content):
            abstractions_used.append(a)
    return abstractions_used


def get_color_for_abstr_family(
        df: pd.DataFrame,
        col_name: str,
        format_str: str = 'hex',):
    """Get a color dict mapping each abstraction to a color.

    Nota that this mapping is based on the abstraction name.
    If not specified it is grey.
    """
    # create thematic groups for source
    if format_str == 'hex':
        color_themes = {
            "pauli": "#dc267f",
            # purple
            "compos": "#785ef0",
            "transp": "#785ef0",
            "iden": "#785ef0",
            "run": "#785ef0",
            # resources
            "insuf": "#fe6100",
            "oversize": "#fe6100",
            # yellow
            "[^u]?meas": "#ffb001",
            "[^u]?const": "#ffb001",
        }
    elif format_str == 'rgb':
        color_themes = {
            "pauli": "rgb(220, 38, 127)",
            "compos": "rgb(120, 94, 240)",
            "insuf": "rgb(254, 97, 0)",
            "oversize": "rgb(254, 97, 0)",
            "[^u]?meas": "rgb(255, 176, 1)",
        }
    per_family_color = {}
    for row in df.iterrows():
        query_name = row[1][col_name]
        # default
        per_family_color[query_name] = "grey"
        for k in color_themes.keys():
            if re.search(k, query_name.lower()):
                per_family_color[query_name] = color_themes[k]
                break
    return per_family_color