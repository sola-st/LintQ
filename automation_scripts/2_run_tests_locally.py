"""Run the tests locally.
"""
import os
import pathlib

# move to the directory of the current file
os.chdir(os.path.dirname(os.path.realpath(__file__)))

FOLDER_WITH_LINTQ = "../qlint/"  # relative to the current file position
# move to the folder
os.chdir(FOLDER_WITH_LINTQ)

TEST_FOLDERS = [
    "codeql/test/library-tests/qiskit/bituse",
    "codeql/test/library-tests/qiskit/circuit",
    "codeql/test/library-tests/qiskit/gate",
]

DOCKER_IMAGE = "cloud.canister.io:5000/mattepalte/codeql"
N_THREADS = 20

# local path to the CodeQL packs (in case you want to run the tests locally)
PATH_CODEQL_PACKS = "~/.codeql/packages"


# ask whether they want to run the tests with the local CodeQL CLI or with the
# docker image
answer = input(
    "Do you want to run the tests with the local CodeQL CLI or with the docker "
    "image? [local/docker] "
)

cmd_prefix = ""
cmd_suffix = ""

if answer == "local":
    cmd_suffix = f"--additional-packs={PATH_CODEQL_PACKS}"
elif answer == "docker":
    cmd_prefix = f'docker run --rm -v "$(pwd)":/opt/ {DOCKER_IMAGE} ' + \
        f'codeql pack install ; '
else:
    raise ValueError("Please enter either 'local' or 'docker'.")

# run the tests

for folder in TEST_FOLDERS:
    print(f"Running the tests in {folder}...")
    cmd_to_run = cmd_prefix + \
        f'codeql test run {folder} --threads={N_THREADS} ' + \
        cmd_suffix
    os.system(cmd_to_run)

print("Done.")