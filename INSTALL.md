## Installation of LintQ

Table of Contents:
- Step-by-step instructions for installing LintQ
- Installation Check

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
    python automation_scripts/create_docker_image_locally.py
    ```
    At the end check that the docker image has been build correctly by running: `docker images`, you should see an image named `lintq`.


### Installation Check

1. To check that you set up LintQ correctly run this command:
    ```bash
    docker run -v "$(pwd)/data:/home/codeql/project/data" -it --rm lintq codeql pack ls /usr/local/codeql-home/
    ```
    That should show you the following:
    ```bash
    Running on packs: mattepalte/qlint-tests, mattepalte/qiskit, mattepalte/qlint.
    Found mattepalte/qiskit@0.0.1
    Found mattepalte/qlint@0.0.1
    Found mattepalte/qlint-tests@0.0.0
    ```




