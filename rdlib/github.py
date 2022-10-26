"""This CLI script harvest data from Github.

Example usage to download files from github search (from the root of the repo):
python -m rdlib.github downloadfiles --config config/github_download_files.yaml

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


# HELPER FUNCTION


def get_github_token():
    """Get the github token from the environment variables."""
    token = os.environ.get("GITHUB_TOKEN")
    assert token is not None, "Missing GITHUB_TOKEN"
    return token


def parse_projects(response: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Parse the projects from the response."""
    projects = []
    from pprint import pprint
    for project in response:
        projects.append({
            "name": project["name"],
            "description": project["description"],
            "url": project["html_url"],
            "stars": project["stargazers_count"],
            "forks": project["forks_count"],
            "language": project["language"],
            "created_at": project["created_at"],
            "updated_at": project["updated_at"],
            "pushed_at": project["pushed_at"],
            "owner": project["owner"]["login"],
            "owner_url": project["owner"]["html_url"],
            "owner_avatar": project["owner"]["avatar_url"]
        })
    return projects


def parse_file_result(response: Dict[str, Any]) -> Dict[str, Any]:
    """Parse the file result."""
    files = []
    for file in response:
        html_url = file["html_url"]
        download_url = html_url.replace("https://github.com/", "raw.githubusercontent.com/")
        download_url = "https://" + "/".join([
            c for i, c in enumerate(download_url.split("/"))
            if not (i == 3 and c == "blob")])
        files.append({
            "name": file["name"],
            "path": file["path"],
            "html_url": file["html_url"],
            "download_url": download_url,
            "score": file["score"],
            "repository_description": file["repository"]["description"],
            "repository_fork": file["repository"]["fork"],
            "repository_url": file["repository"]["html_url"],
            "repository_name": file["repository"]["full_name"],
            "repository_owner_url": file["repository"]["html_url"],
        })
    return files


def get_list_of_projects_async(
        start_ts: int,
        end_ts: int,
        token: str,
        max_projects: int = None,
        language: str = None,):
    """Download projects from github.

    Parameters:
    -----------
    - start_ts: int
        The start timestamp of the projects to download. (in seconds)
    - end_ts: int
        The end timestamp of the projects to download. (in seconds)
    - token: str
        The github token.
    - max_projects: int
        The maximum number of projects to download. Default: no limit.
    """
    query = f"created:{start_ts}..{end_ts}"
    print(f"Query: {query}")

    auth = (token, 'x-oauth-basic')
    headers = {'Accept': 'application/vnd.github.v3+json'}

    # everything is measured in seconds
    hours_unit = 3600
    day_unit = hours_unit * 24
    week_unit = day_unit * 7
    month_unit = week_unit * 4
    working_unit = week_unit  # in seconds

    # convert datetimes to timestamps

    c_date = str(datetime.utcfromtimestamp(start_ts).strftime('%Y-%m-%d'))+'..'+str(datetime.utcfromtimestamp(start_ts+working_unit).strftime('%Y-%m-%d'))
    concerned_projects = []
    reached = 0
    target_n_repos = max_projects
    if target_n_repos is None:
        target_n_repos = 1000000000

    while (len(concerned_projects) < target_n_repos) and (start_ts < end_ts):
        request = f'https://api.github.com/search/repositories?q=created:{c_date}language:{language}&sort=stars&order=desc&per_page=100'
        response =requests.get(request, headers=headers, auth=auth)
        total_count = response.json()['total_count']
        print(c_date, total_count)
        if total_count > 3000:
            working_unit = day_unit
            c_date = str(datetime.utcfromtimestamp(start_ts).strftime('%Y-%m-%d'))+'..'+str(datetime.utcfromtimestamp(start_ts+working_unit).strftime('%Y-%m-%d'))
            request = f'https://api.github.com/search/repositories?q=created:{c_date}language:{language}&sort=stars&order=desc&per_page=100'
            response = requests.get(request, headers=headers, auth=auth)

            #get 1000 projects
            total_count = response.json()['total_count']
            n_pages = min(int(total_count/100)+1, 10)
            for page in range(n_pages):
                request = f'https://api.github.com/search/repositories?q=created:{c_date}language:{language}&sort=stars&order=desc&per_page=100&page={page}'
                response = requests.get(request, headers=headers, auth=auth)

                concerned_projects += parse_projects(response.json()['items'])


            working_unit = week_unit
            start_ts = start_ts + day_unit
            c_date = str(datetime.utcfromtimestamp(start_ts).strftime('%Y-%m-%d'))+'..'+str(datetime.utcfromtimestamp(start_ts+working_unit).strftime('%Y-%m-%d'))

        elif total_count < 200:
            working_unit = month_unit
            c_date = str(datetime.utcfromtimestamp(start_ts).strftime('%Y-%m-%d'))+'..'+str(datetime.utcfromtimestamp(start_ts+working_unit).strftime('%Y-%m-%d'))
            request = f'https://api.github.com/search/repositories?q=created:{c_date}language:{language}&sort=stars&order=desc&per_page=100'
            response =requests.get(request, headers=headers, auth=auth)

            #get 1000 projects
            total_count = response.json()['total_count']
            n_pages = min(int(total_count/100)+1, 10)
            for page in range(n_pages):
                request = f'https://api.github.com/search/repositories?q=created:{c_date}language:{language}&sort=stars&order=desc&per_page=100&page={page}'
                response =requests.get(request, headers=headers, auth=auth)
                concerned_projects += parse_projects(response.json()['items'])

            working_unit = week_unit
            start_ts = start_ts + month_unit
            c_date = str(datetime.utcfromtimestamp(start_ts).strftime('%Y-%m-%d'))+'..'+str(datetime.utcfromtimestamp(start_ts+working_unit).strftime('%Y-%m-%d'))

        else:
            c_date = str(datetime.utcfromtimestamp(start_ts).strftime('%Y-%m-%d'))+'..'+str(datetime.utcfromtimestamp(start_ts+working_unit).strftime('%Y-%m-%d'))
            request = f'https://api.github.com/search/repositories?q=created:{c_date}language:{language}&sort=stars&order=desc&per_page=100'
            response =requests.get(request, headers=headers, auth=auth)

            #get 1000 projects
            total_count = response.json()['total_count']
            n_pages = min(int(total_count/100)+1, 10)
            for page in range(n_pages):
                request = f'https://api.github.com/search/repositories?q=created:{c_date}language:{language}&sort=stars&order=desc&per_page=100&page={page}'
                response =requests.get(request, headers=headers, auth=auth)
                concerned_projects += parse_projects(response.json()['items'])

            working_unit = week_unit
            start_ts = start_ts + week_unit
            c_date = str(datetime.utcfromtimestamp(start_ts).strftime('%Y-%m-%d'))+'..'+str(datetime.utcfromtimestamp(start_ts+working_unit).strftime('%Y-%m-%d'))
    # remember to yield the results
    return concerned_projects


def get_list_of_files_async(
        min_file_size: int,
        max_file_size: int,
        token: str,
        language: str,
        keywords: List[str],
        chunk_size: int = 1000,
        n_chunks: int = None,
        max_files: int = None,):
    """Return the list of files with the keywords.

    Parameters
    ----------
    min_file_size : int
        Minimum file size in bytes.
    max_file_size : int
        Maximum file size in bytes.
    token : str
        Github token.
    language : str
        programming language of the files.
    """

    # https://docs.github.com/en/search-github/searching-on-github/searching-code
    print(f"Overall scan: filesize (bytes): {min_file_size}..{max_file_size}")

    # create authorization with tthe github token

    headers = {
        'Accept': 'application/vnd.github.v3+json',
        'Authorization': 'token ' + token}

    files_found = []
    target_n_files = max_files
    if target_n_files is None:
        target_n_files = 1000000000
    time_between_queries = 10

    c_low_limit = min_file_size
    if n_chunks:
        chunk_size = (max_file_size - min_file_size) // n_chunks
    c_high_limit = c_low_limit + chunk_size
    # replace multiple spaces with a single '+' using regex
    keywords = [re.sub(r'\s+', '+', keyword) for keyword in keywords]
    kwds = "+".join(keywords)
    query_just_done = False
    while ((len(files_found) < target_n_files) and (c_high_limit < max_file_size)) or (not query_just_done):
        query = f'https://api.github.com/search/code?q={kwds}+size:{c_low_limit}..{c_high_limit}&language:{language}&order=desc&per_page=100'
        response = requests.get(query, headers=headers)
        print(f"Query: filesize (bytes): {c_low_limit}..{c_high_limit}")
        print("Response status code:", response.status_code)
        if response.status_code == 403:
            print("Rate limit exceeded. Waiting 1 minute.")
            time.sleep(60)
            continue
        time.sleep(time_between_queries)
        # pprint(response.json()['items'][:3])
        total_count = response.json()['total_count']
        print(query, "-->", total_count)

        if total_count > 1000:
            chunk_size //= 2
            print(f"Chunk size reduced to {chunk_size}")
            query_just_done = False
        else:
            n_pages = min(int(total_count/100) + 1, 10)
            time.sleep(time_between_queries)
            i_page = 0
            while i_page < n_pages:
                page_query = f'{query}&page={i_page}'
                response = requests.get(page_query, headers=headers)
                print("Response status code:", response.status_code)
                if response.status_code == 403:
                    print("Rate limit exceeded. Waiting 1 minute.")
                    time.sleep(60)
                    continue
                print(f"Page {i_page} of {n_pages}")
                print(page_query, "-->", len(response.json()['items']))
                i_page += 1
                time.sleep(time_between_queries)
                page_total_count = response.json()['total_count']
                if page_total_count == 0:
                    break
                new_files_found = parse_file_result(response.json()['items'])
                files_found += new_files_found
                print(f"Found {len(files_found)} files so far. Saving {len(new_files_found)} new files.")
                print("#" * 80)
                yield new_files_found
            c_low_limit = c_high_limit
            query_just_done = True
            if total_count < 200:
                chunk_size *= 2
                print(f"Chunk size increased to {chunk_size}")
        c_high_limit = c_low_limit + chunk_size
    yield files_found


def from_str_to_timestamp(date: str) -> int:
    """Return the timestamp from a string."""
    if date == 'NOW':
        return int(time.time())
    return int(datetime.strptime(date, '%Y-%m-%d %H:%M:%S').timestamp())


# DOWNLOAD UTILITIES


# create a click group with download_projects and download_files
@click.group()
def cli():
    """Download the projects from github."""
    pass


@cli.command()
@click.option('--config', default='config.json', help='Path to the config file.')
@click.option('--output', default='projects.json', help='Output file name')
def downloadprojects(config, output):
    """Download the projects from github."""
    config = load_config_and_check(config)
    # read the github_token_path file content
    github_token = open(config['github_token_path']).read().strip()
    projects = get_list_of_projects_async(
        start_ts=from_str_to_timestamp(config['start_date']),
        end_ts=from_str_to_timestamp(config['end_date']),
        token=github_token,
        language=config['language'])
    with open(output, 'w') as f:
        json.dump(projects, f)
    # save the projects
    with open(output, 'w') as f:
        json.dump(projects, f, indent=4, sort_keys=True)


@cli.command()
@click.option('--config', default='config.json', help='Path to the config file.')
def downloadfiles(config):
    """Download the files from github."""
    config = load_config_and_check(config)
    # read the github_token_path file content
    github_token = open(config['github_token_path']).read().strip()
    output_folder = config['file_mining']['output_folder']
    for file_list in get_list_of_files_async(
            min_file_size=config['file_mining']['min_file_size'],
            max_file_size=config['file_mining']['max_file_size'],
            chunk_size=config['file_mining']['chunk_size'],
            token=github_token,
            username=config['github_username'],
            language=config['file_mining']['language'],
            keywords=config['keywords']):
        # current timestamp
        ts = int(time.time())
        # save the files
        with open(os.path.join(output_folder, f"files_{ts}.json"), 'w') as f:
            json.dump(file_list, f, indent=4, sort_keys=True)


if __name__ == '__main__':
    cli()
