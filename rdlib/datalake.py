"""This file deals with the download of code data from various sources."""

import sqlite3
from time import sleep
from typing import List, Dict, Tuple, Any
import requests
import os
from pathlib import Path
from multiprocessing import Pool
import hashlib
from tqdm import tqdm
from slugify import slugify


def dump_string_to_sql(
        table_name: str, simple_strings: List[str],
        provenance: List[str], db_path: str = 'data.db'):
    """Dumps a list of string as simple records of an sql table."""
    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.execute(f'CREATE TABLE IF NOT EXISTS {table_name} (id INTEGER PRIMARY KEY, simple_string TEXT, provenance TEXT, Timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)')
    for string, provenance in zip(simple_strings, provenance):
        c.execute(f"INSERT INTO {table_name} VALUES (null, ?, ?, datetime('now','localtime'))", (string, provenance))
    conn.commit()
    conn.close()



def download_file_unsafe(url: str, out_folder: str, out_name: str):
    """Download a single file."""
    try:
        r = requests.get(url, allow_redirects=True)
        open(os.path.join(out_folder, out_name), 'wb').write(r.content)
    except:
        print(f"Error downloading {url}")


def download_file_safe(url: str, out_folder: str, out_name: str):
    """Download a single file.

    Note this creates a folder if it doesn't existis yet.
    """
    # create the output folder if it does not exist
    Path(out_folder).mkdir(parents=True, exist_ok=True)
    # download the file
    download_file_unsafe(url, out_folder, out_name)


def download_files_seq(
        urls: list, out_folder: str, func_url_to_filename: callable = None):
    """Download a list of files sequentially."""
    # create the output folder if it does not exist
    Path(out_folder).mkdir(parents=True, exist_ok=True)
    if func_url_to_filename is None:
        func_url_to_filename = lambda x: x.split('/')[-1]
    for url in urls:
        out_name = func_url_to_filename(url)
        download_file_unsafe(url, out_folder, out_name)


def extract_url_hash_filename(url: str):
    """Clean the url to get the repo format."""
    # compute the url hash
    url_hash = hashlib.sha256(url.encode('utf-8')).hexdigest()[:6]
    filename = url.split('/')[-1]
    if '.' not in filename:
        extension = 'no_ext'
    else:
        extension = filename.split('.')[-1]
    filename = filename.replace('.' + extension, '')
    filename = slugify(str(filename), separator='_')
    return filename + "_" + url_hash + "." + extension


def extract_user_project_filename(url: str):
    """Clean the url to get the repo format."""
    return "_".join(url.replace('https://raw.githubusercontent.com/', '').split('/')[:2]) + "_" + url.split('/')[-1]


def download_files_par(
        urls: list, out_folder: str, func_url_to_filename: callable = None,
        n_workers: int = 4, ):
    """Download a list of files in parallel (multiprocessing)."""
    # create the output folder if it does not exist
    Path(out_folder).mkdir(parents=True, exist_ok=True)
    # download the files in parallel
    if func_url_to_filename is None:
        func_url_to_filename = lambda x: x.split('/')[-1]
    with Pool(n_workers) as p:
        list(tqdm(p.starmap(
            download_file_unsafe,
            [
                (url, out_folder, func_url_to_filename(url))
                for url in urls
            ]), total=len(urls)))


def download_files(
        urls: list, out_folder: str,
        func_url_to_filename: callable = None,
        mode: str = 'par', n_workers: int = 10):
    """Download a list of files.

    Args:
        urls: list of urls to download
        out_folder: folder to save the files to
        mode: 'seq' for sequential, 'par' for parallel
        n_workers: number of workers for parallel mode
    """
    if mode == 'seq':
        download_files_seq(urls, out_folder, func_url_to_filename)
    elif mode == 'par':
        download_files_par(urls, out_folder, func_url_to_filename, n_workers)
    else:
        raise ValueError("mode must be 'seq' or 'par'")
