"""Sample a part of the warnings for inspections.

This will create a subfolder "sampled_warnings" in the output folder.
"""

import os
import yaml
import json
import pathlib
import random
import shutil
from typing import List, Dict, Any

import click
import matplotlib.colors as mcolors
import pandas as pd
from sarif import loader
from tqdm import tqdm



# SAMPLING - Change settings here
SAMPLE_AGAIN = False
FIXED_SAMPLE_SIZE = 10
CONFIDENCE_LEVEL = .90
MARGIN_ERROR = .10
RND_SEED = 42


# %%
def get_results_from_sarif_path(sarif_path: str) -> Dict[str, Any]:
    """Extract the results from the sarif file as json."""
    with open(sarif_path, "r") as f:
        sarif_data = json.load(f)
    all_results = []
    n_runs = len(sarif_data['runs'])
    for i in range(n_runs):
        sarif_results = sarif_data["runs"][i]["results"]
        all_results.extend(sarif_results)
    return all_results


def get_df_from_sarif(sarif_results: List[Dict[str, Any]]):
    """Create a dataset from sarif results."""
    def process(record: Dict[str, Any]):
        """Parse some key info from the record."""
        region = record["locations"][0]["physicalLocation"].get("region", None)
        line, col = None, None
        if region:
            line = region.get("startLine", None)
            col = region.get("startColumn", None)
        return {
            "rule_id": record["ruleId"],
            "message": record["message"]["text"],
            "file": record["locations"][0]["physicalLocation"]["artifactLocation"]["uri"],
            "line": line,
            "col": col,
        }

    processed_results = [
        process(result)
        for result in sarif_results
    ]

    df_results = pd.DataFrame.from_records(processed_results)
    return df_results


def compute_representative_sample_size(
        population_size, margin_error=.05,confidence_level=.95,sigma=1/2):
    """Calculate sample size for a representative sample of the population.

    Credits: https://github.com/shawnohare/samplesize/blob/master/samplesize.py
    """

    alpha = 1 - (confidence_level)
    zdict = {
        .90: 1.645,
        .91: 1.695,
        .99: 2.576,
        .97: 2.17,
        .94: 1.881,
        .93: 1.812,
        .95: 1.96,
        .98: 2.326,
        .96: 2.054,
        .92: 1.751
    }
    if confidence_level in zdict:
        z = zdict[confidence_level]
    else:
        from scipy.stats import norm
        z = norm.ppf(1 - (alpha/2))
    N = population_size
    M = margin_error
    numerator = z**2 * sigma**2 * (N / (N-1))
    denom = M**2 + ((z**2 * sigma**2)/(N-1))
    return int(numerator/denom + 0.5)

# quick test
res = compute_representative_sample_size(
    10000, margin_error=0.05, confidence_level=0.95, sigma=1/2)
assert res == 370




def get_file_extension_dictionary(dir: str) -> dict:
    """Get a dictionary {filename: its extension, etc.} form a directory."""
    file_extensions = {}
    for file in os.listdir(dir):
        base_name = os.path.splitext(file)[0]
        extension = os.path.splitext(file)[1]
        file_extensions[base_name] = extension
    return file_extensions


def count_files(folder: str, allowed_formats: List[str] = [".py", "ipynb"]):
    """Count how many files with the given extension are in the target folder."""
    files_extension = get_file_extension_dictionary(folder)
    return sum([
        1
        for file, extension in files_extension.items()
        if extension in allowed_formats
    ])


def compute_warnings_table(
        df_results: pd.DataFrame,
        rule_name_mapping: Dict[str, str],
        total_files_in_dataset: int,
        rule_term: str):
    """Compute the table in latex with number and percentage of warnings."""
    # compute: total sum of warnings
    df_abs = df_results.copy()
    df_abs = df_abs[["rule_id", "file"]]
    df_abs = df_abs.groupby("rule_id").count()
    df_abs = df_abs.reset_index(drop=False)
    df_abs = df_abs.rename(columns={"file": "tot_warnings"})

    # compute: files affected
    df = df_results.copy()
    df = df[["rule_id", "file"]]
    df = df.drop_duplicates()  # << difference
    df = df.groupby("rule_id").count()
    df = df.reset_index(drop=False)
    df = df.rename(columns={"file": "n_files_affected"})

    df = df.merge(df_abs, on="rule_id", how="left")
    if rule_name_mapping is not None:
        # add all the rules that are not in the dataframe with 0 warnings
        for rule in list(rule_name_mapping.keys()):
            if rule not in df['rule_id'].unique():
                print(f"WARN: no warnings for rule {rule}. Adding a 0 value.")
                df = pd.concat([df, pd.DataFrame([{
                    'rule_id': rule,
                    'tot_warnings': 0,
                    'n_files_affected': 0}])], ignore_index=True)
        # keep only rules that are in the mapping
        rules_not_in_mapping = \
            set(df['rule_id'].unique()) - set(rule_name_mapping.keys())
        if len(rules_not_in_mapping) > 0:
            print("WARN: some rules are not in the mapping. Discarding them.")
            print(rules_not_in_mapping)
            df = df[df['rule_id'].isin(rule_name_mapping.keys())]
        # rename column rules with mapping
        df['rule_id'] = df['rule_id'].apply(
            lambda e: rule_name_mapping[e]
            if e in rule_name_mapping.keys() else e)

    # rename column
    df['perc_of_affected_files'] = df['n_files_affected'].apply(
        lambda e: (int(e) / total_files_in_dataset) * 100)


    # compute average and median of the perc_of_affected_files
    avg = df['perc_of_affected_files'].mean()
    median = df['perc_of_affected_files'].median()
    print("\\newcommand{\\avgWarningsPerc}{" + f"{avg:.2f}" + "\\%}")
    print("\\newcommand{\\medianWarningsPerc}{" + f"{median:.2f}" + "\\%}")

    # format as a percentage
    df['perc_of_affected_files'] = df['perc_of_affected_files'].apply(
        lambda e: "{:.2f}%".format(e))
    if rule_name_mapping is not None:
        # sort by canonical order
        categories = [cat for cat in rule_name_mapping.values()]
        df['rule_id'] = pd.Categorical(
            df['rule_id'], categories=categories)
        df = df.sort_values('rule_id')

    # cosmetic renaming
    mapping_column_to_name = {
        "rule_id": f"{rule_term} Name",
        "tot_warnings": "Tot. warnings",
        "perc_of_affected_files": "Files with warning",
    }
    # drop col not in the mapping
    df = df[mapping_column_to_name.keys()]
    df = df.rename(columns=mapping_column_to_name)


    table = df.to_latex(index=False, column_format="lrr")
    # replace % escaping
    table = table.replace("%", "\\%")
    print(table)
    return df


def sample(
        sarif_results: List[Dict[str, Any]],
        relevant_rules: List[str],
        fixed_sample_size=10,
        confidence_level=0.90,
        margin_error=0.10,
        random_seed=42,
        representative_sample_superset=False,):
    """Sample warnings from each rule."""
    sampled_results = []
    for rule in relevant_rules:
        # SET SEED FOR EACH RULE
        random.seed(random_seed)
        warnings_of_i_rule = [
            result
            for result in sarif_results
            if result["ruleId"] == rule
        ]
        # sort them by filename
        warnings_of_i_rule = sorted(
            warnings_of_i_rule,
            key=lambda x: x["locations"][0]["physicalLocation"]["artifactLocation"]["uri"]
        )
        representative_sample_size = compute_representative_sample_size(
            population_size=len(warnings_of_i_rule),
            margin_error=margin_error,
            confidence_level=confidence_level
        )
        # consider all
        sample_i_rule = warnings_of_i_rule
        # get the largest representative sample first
        if representative_sample_size > fixed_sample_size:
            if len(sample_i_rule) > representative_sample_size:
                sample_i_rule = random.sample(sample_i_rule, representative_sample_size)

        # condition to trigger the fixed sample size
        if not representative_sample_superset:
            if len(sample_i_rule) > fixed_sample_size:
                sample_i_rule = random.sample(sample_i_rule, fixed_sample_size)

        print(f"{len(warnings_of_i_rule)} >> {len(sample_i_rule)}\t ({rule})")
        sampled_results.extend(sample_i_rule)
    return sampled_results


def show_stats(dir_with_original_files, rule_name_mapping, df_results):
    """Print statistics about the dataset and the warnings."""
    TOTAL_FILES_IN_DATASET = count_files(
        folder=dir_with_original_files,
        allowed_formats=[".py", "ipynb"]
    )
    print(f"Total files in the dataset: {TOTAL_FILES_IN_DATASET}")
    compute_warnings_table(
        df_results=df_results,
        rule_name_mapping=rule_name_mapping,
        total_files_in_dataset=TOTAL_FILES_IN_DATASET,
        rule_term="Rule"
    )


def perform_sampling(
        sarif_results, df_results, rule_name_mapping, output_folder, sarif_scaffold, dir_with_original_files):
    """Perform the sampling and export the results in a new folder.

    The sampling is performed with two strategies:
    - fixed sample size: it will sample a fixed number of warnings for each rule
    - representative sample: it will sample a number of warnings that is representative of the population

    The sampling is performed such that the fixed sample size is a subset of the representative sample, and the delta is also exported.
    """
    sampled_results = []

    # create folder
    pathlib.Path(output_folder).mkdir(parents=True, exist_ok=True)

    # for each rule, sort them alphabetically by filename,
    # then sample 10
    all_rules = df_results["rule_id"].unique()
    relevant_rules = [
        rule for rule in all_rules if rule in rule_name_mapping.keys()]

    sarif_sample_fixed = sample(
        sarif_results=sarif_results,
        relevant_rules=relevant_rules,
        fixed_sample_size=FIXED_SAMPLE_SIZE
    )
    df_results_sample_fixed = get_df_from_sarif(sarif_sample_fixed)
    print(f"FIXED: total sample size: {len(df_results_sample_fixed)}")
    print('-' * 80)

    sarif_sample_representative = sample(
        sarif_results=sarif_results,
        relevant_rules=relevant_rules,
        fixed_sample_size=FIXED_SAMPLE_SIZE,
        representative_sample_superset=True,
    )
    df_results_sample_representative = get_df_from_sarif(
        sarif_sample_representative)
    print(f"REPRESENTATIVE: total sample size: {len(df_results_sample_representative)}")
    print('-' * 80)

    # check that all the fixed size records are in the representative one
    df_intersection = df_results_sample_fixed.merge(
        df_results_sample_representative,
        how="inner",
        on=["rule_id", "message", "file", "line", "col"],
        suffixes=("_fixed", "_representative")
    )
    assert len(df_intersection) == len(df_results_sample_fixed)
    # export - FIXED,
    to_export = [
        # FIXED SIZE
        {
            'sarif_results': sarif_sample_fixed,
            'prefix': f"data_sample_fixed_{FIXED_SAMPLE_SIZE}"
        },
        # REPRESENTATIVE
        {
            'sarif_results': sarif_sample_representative,
            'prefix': f"data_sample_representative_{FIXED_SAMPLE_SIZE}"
        },
        # DELTA
        {
            'sarif_results': [
                result for result in sarif_sample_representative
                if result not in sarif_sample_fixed],
            'prefix': f"data_sample_delta_{FIXED_SAMPLE_SIZE}"
        }
    ]

    for i_to_export in to_export:
        print("-" * 80)
        new_sarif_i = sarif_scaffold.copy()
        i_results = i_to_export["sarif_results"]
        i_prefix = i_to_export["prefix"]
        # remove the ruleIndex key from each result
        for result in i_results:
            result.pop("ruleIndex", None)
        new_sarif_i["runs"][0]["results"] = i_results
        with open(os.path.join(output_folder, f"{i_prefix}.sarif"), "w") as f:
            json.dump(new_sarif_i, f)
        # copy all the files in a dedicated folder
        # create folder in the sarif one with pathlib
        i_subfolder_path = os.path.join(output_folder, i_prefix)
        pathlib.Path(i_subfolder_path).mkdir(parents=True, exist_ok=True)
        # add a gitignore in the subfolder
        with open(os.path.join(i_subfolder_path, ".gitignore"), "w") as f:
            f.write("*")
        i_all_filenames = [
            result["locations"][0]["physicalLocation"]["artifactLocation"]["uri"]
            for result in i_results
        ]
        i_ORIGINAL_filepaths = [
            os.path.join(dir_with_original_files, filename) for filename in i_all_filenames]
        # remove the prefix: file:///
        i_ORIGINAL_filepaths = [
            filepath.replace("file:///", "") for filepath in i_ORIGINAL_filepaths]
        print(i_ORIGINAL_filepaths[:5])
        # copy from original to the i_subfolder
        for filepath in tqdm(i_ORIGINAL_filepaths):
            shutil.copy(filepath, i_subfolder_path)
        # create dataframe
        i_df = get_df_from_sarif(i_results)
        i_df.to_csv(
            os.path.join(output_folder, f"{i_prefix}.csv"), index=False)
        print(
            f"Exported {len(i_results)} results to " +
            f"{i_prefix}.sarif and {i_prefix}.csv")
        print(f"Exported {len(i_ORIGINAL_filepaths)} files to {os.path.basename(i_subfolder_path)}")

        print("-" * 80)
        print("Done. See the folder:", output_folder)


@click.command()
@click.argument('config_file', type=click.Path(exists=True))
def main(config_file):
    """Sample a part of the warnings for inspections.

    It will create a subfolder "sampled_warnings" in the output folder."""
    # Load config file
    with open(config_file, 'r') as f:
        config = yaml.safe_load(f)

    rule_name_mapping = config['rule_name_mapping']
    sarif_scaffold = config['sarif_scaffold']

    # get the folder with all the files
    dir_with_original_files = config['input_folder']

    # get the path to the file
    path_to_file_with_all_warnings = config['sarif_file_all_rules']

    # output folder: sampled_warnings_date
    # e.g sampled_warnings_2023-09-18_17-17-54
    main_output_folder = config['output_folder']
    output_folder = os.path.join(
        main_output_folder,
        "sampled_warnings_" + pd.Timestamp.now().strftime("%Y-%m-%d_%H-%M-%S"))


    # load files
    sarif_results = get_results_from_sarif_path(path_to_file_with_all_warnings)
    df_results = get_df_from_sarif(sarif_results)

    print("=== STATS about WARNINGS ===")
    # show stats and print warning table
    show_stats(
        dir_with_original_files=dir_with_original_files,
        rule_name_mapping=rule_name_mapping,
        df_results=df_results
    )

    print("=== SAMPLING ===")
    # sample
    perform_sampling(
        sarif_results=sarif_results,
        df_results=df_results,
        rule_name_mapping=rule_name_mapping,
        output_folder=output_folder,
        sarif_scaffold=sarif_scaffold,
        dir_with_original_files=dir_with_original_files
    )


if __name__ == '__main__':
    main()
