"""This script generates a test database for the CodeQL analysis.

This scripts collects all the python files in the qlint/codeql folder
and moves them in the data/datasets/tmp_test_db/raw_files folder.

Then it creates a test database in the data/datasets/tmp_test_db/codeql_db
folder.
"""
import os
import pathlib
import shutil
from time import sleep

DOCKER_IMAGE = "cloud.canister.io:5000/mattepalte/codeql"
N_THREADS = 20
PATH_CODEQL_PACKS_LOCAL_MACHINE = "~/.codeql/packages"

# move to the directory of this file
os.chdir(os.path.dirname(os.path.abspath(__file__)))

dataset_path = os.path.join("..", "data", "datasets", "tmp_test_db")
dataset_raw_files_path = os.path.join(dataset_path, "raw_files")

# create the raw_files folder if it does not exist
pathlib.Path(dataset_raw_files_path).mkdir(parents=True, exist_ok=True)

# move to the qlint/codeql folder
folder_to_mine = os.path.join("..", "qlint", "codeql")

# scan all the python files in the folder,
# but not containing testproj in the path
for root, dirs, files in os.walk(folder_to_mine):
    for f in files:
        if f.endswith(".py") and "testproj" not in root:
            # copy the file in the raw_files folder
            print(f"Copying {f} to {dataset_raw_files_path}")
            shutil.copy(os.path.join(root, f), dataset_raw_files_path)

# TODO : fix docker is not called becasue of the first command ending with ; (codeql pack install ;)
# def query_if_user_wants_docker():
#     """Ask the user whether they want to use docker or the local CodeQL CLI.

#     Returns:
#         str: either 'local' or 'docker'
#     """
#     answer = input(
#         "Do you want to run the tests with the local CodeQL CLI or with the docker "
#         "image? [local/docker] "
#     )
#     cmd_prefix = ""
#     cmd_suffix = ""
#     if answer == "local":
#         cmd_suffix = f"--additional-packs={PATH_CODEQL_PACKS_LOCAL_MACHINE}"
#     elif answer == "docker":
#         cmd_prefix = f'docker run --rm -v "$(pwd)":/opt/ {DOCKER_IMAGE} ' + \
#             f'codeql pack install ; '
#     else:
#         raise ValueError("Please enter either 'local' or 'docker'.")
#     return cmd_prefix, cmd_suffix


# cmd_prefix, cmd_suffix = query_if_user_wants_docker()
cmd_prefix = ""
cmd_suffix = ""


# create the test database with CodeQL (multiline command)
print("Creating the test database")
cmd_to_run = \
    f"codeql database create {dataset_path}/codeql" + \
    f" --language=python --overwrite --source-root={dataset_raw_files_path}"

print("Running the following command in 5 sec:")
full_command = f"{cmd_prefix} {cmd_to_run} {cmd_suffix}"
print(full_command)
sleep(5)


# run it on screen
os.system(
    # "screen -mS codeql_db_creation " +
    full_command
)