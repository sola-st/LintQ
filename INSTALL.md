## Installation of LintQ

Table of Contents:
- Step-by-step instructions for installing LintQ
- Basic usage example or method to test the installation

### Step-by-step instructions for installing LintQ

1. Clone the repository:
    ```bash
    git clone <this-repo-github-url>
    ```
1. Open the [`REQUIREMENTS.md`](REQUIREMENTS.md) file and check that the hardware and software requirements are met. If not follow the installation guide there to obtain the correct software dependencies.
1. install the Python dependencies via Conda virtual environment from our configuration file [here](virtualenv/conda/environment.yml):
    ```bash
    conda env create -f virtualenv/conda/environment.yml
    ```
1. activate the virtual environment:
    ```bash
    conda activate LintQEnv
    ```
1. Build the docker image to run LintQ, run this command from the root of the repo:
    ```bash
    python automation_scripts/5_create_docker_image_locally.py
    ```
    At the end check that the docker image has been build correctly by running: `docker images`, you should see an image named `codeql-for-lintq`.


### Basic usage example

1. Make sure to be in the be in the root of the repository
1. Run the following command to check that you can successfully execute the CodeQL in the Docker image.
    ```bash
    docker run -v $(pwd):/home/codeql/project -it --rm codeql-for-lintq codeql version
    ```
1. To prepare your files at [`data/demo_dataset/programs`](data/demo_dataset/programs) for analysis with LintQ run the following command:
    ```
    docker run -v $(pwd):/home/codeql/project -it --rm codeql-for-lintq codeql database create /home/codeql/project/data/demo_dataset/codeql_database --language=python --source-root /home/codeql/project/data/demo_dataset/programs
    ```

### Run LintQ on Dataset

1. enter in the docker container by running:
    ```bash
    docker run -v $(pwd):/home/codeql/project -it --rm codeql-for-lintq
    ```
1. Move to the folder with the LintQ package to install:
    ```bash
    cd /home/codeql/project/qlint/codeql/src
    ```
1. Install the LintQ package:
    ```bash
    codeql pack install
    ```
    Take note of the path where the dependencies are stored (e.g. `/home/<username>/.codeql/packages`).
1. Go back to the main path of the repo (while staying inside the docker container):
    ```bash
    cd /home/codeql/project/
    ```
1. Run the queries on the demo dataset and produce a sarif file:
    ```bash
    codeql database analyze \
        --format=sarifv2.1.0 \
        --threads=10 \
        --output=/home/codeql/project/data/demo_dataset/demo_results.sarif \
        --rerun \
        -- /home/codeql/project/data/demo_dataset/codeql_database \
        /home/codeql/project/qlint/codeql/src
    ```






