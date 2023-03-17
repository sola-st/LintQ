"""Strategies to shortlist the best repos to send bug reports to.

The strategies are:
- prioritize repos with most recent bug commit date

To run, use the following command from the base folder of the repo:
python -m rdlib.prioritize_bug_report --config_path config/github_prioritize_repos_v08.yaml

"""

import os
import re
import pathlib
from typing import List, Dict, Tuple, Any
import yaml
import json
from rdlib.fsh import load_config_and_check

from pprint import pprint
from datetime import datetime
import requests
from git import Repo
import os
import click
import time
import pandas as pd
from tinydb import TinyDB, Query
from tqdm import tqdm
import sqlite3


def get_repo_from_metadata(
        metadata_path: str = "df_summary.csv",
        column_name: str = "repository_name") -> str:
    """Read all the metadata and keep their repository name."""
    df = pd.read_csv(metadata_path)
    unique_repos = df[column_name].tolist()
    return unique_repos


def get_latest_commit_data_via_API(
        repository_name: str,
        token: str,
        ) -> Tuple[str, str]:
    """Query github API and get the date of latest commit of the main/master."""
    auth = (token, 'x-oauth-basic')
    headers = {'Accept': 'application/vnd.github.v3+json'}
    url = f"https://api.github.com/repos/{repository_name}/commits/main"
    headers = {"Authorization": f"token {token}"}
    response = requests.get(url, headers=headers, auth=auth)
    # print(f"Querying {url} - response code: {response.status_code}")
    if not response.status_code == 200:
        # try on master
        url = f"https://api.github.com/repos/{repository_name}/commits/master"
        response = requests.get(url, headers=headers, auth=auth)
        # print(f"Querying {url} - response code: {response.status_code}")
    if not response.status_code == 200:
        print("Info not found...")
        return repository_name, None
    commit_date = response.json()["commit"]["author"]["date"]
    commit_date = datetime.strptime(commit_date, "%Y-%m-%dT%H:%M:%SZ")

    return repository_name, commit_date, response.json()


@click.command()
@click.option(
    "--config_path",
    default="../config.yaml",
    help="Path to the config file.",
)
def main(config_path: str):
    """Prioritize repos based on the latest commit date."""

    config = load_config_and_check(config_path)
    all_repos = get_repo_from_metadata(
        metadata_path=config["metadata_path"],
        column_name=config["column_name_for_repository"],
    )
    github_token = open(config['github_token_path']).read().strip()

    folder_path_to_db = config['path_to_database']
    pathlib.Path(folder_path_to_db).mkdir(parents=True, exist_ok=True)
    # path_to_db = os.path.join(folder_path_to_db, "latest_commit_date.json")
    # db = TinyDB(path_to_db)
    # create a new sqlite database
    conn = sqlite3.connect(
        os.path.join(folder_path_to_db, "latest_commit_date.db"))
    c = conn.cursor()
    # create a table with repo, date and timestamp as columns
    c.execute("CREATE TABLE commits (repo text, date_str text, timestamp real)")

    for repo_name in tqdm(all_repos):
        try:
            repo, date, response = get_latest_commit_data_via_API(
                repository_name=repo_name,
                token=github_token,
            )
            # db.insert(
            #     {
            #         "repo": repo,
            #         "date_str": str(date),
            #         "timestamp": date.timestamp(),
            #         "response": response,
            #     }
            # )
            c.execute(
                f"INSERT INTO commits VALUES ('{repo}', '{str(date)}', {date.timestamp()})"
            )
            conn.commit()
            time.sleep(0.65)
        except Exception as e:
            print(f"Error: {e}")
            continue

    # sort the database
    # db = TinyDB(path_to_db)
    # db.all().sort(key=lambda x: x['timestamp'], reverse=True)
    # db.close()


if __name__ == "__main__":
    main()
