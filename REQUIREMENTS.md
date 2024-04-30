# Requirements

Table of Contents:
- [Hardware Requirements](#hardware-requirements)
- [Software Environment](#software-environment)


## Hardware Requirements

LintQ should work on any machine as long as docker can be installed on it.
LintQ rely on CodeQL which has different computing requirements depending on the size of the dataset of programs under analysis.

### Recommended Hardware for Demo
- **RAM**: 16+ GB

We tested it with:
- **OS**: Ubuntu 22.04.4 LTS
- **CPU**: Intel(R) Xeon(R) Gold 6230 CPU @ 2.10GHz
- **Cores**: 16
- **RAM**: 32 GB

### Recommended Hardware for Large Dataset
- **RAM**: 64+ GB

We tested it with:
- **OS**: Ubuntu 20.04.6 LTS
- **CPU**: Intel(R) Xeon(R) Silver 4214 CPU @ 2.20GHz
- **Cores**: 48
- **RAM**: 252 GB

Note: This recommendations have been derived from the [official CodeQL documentation from GitHub](https://docs.github.com/en/code-security/code-scanning/creating-an-advanced-setup-for-code-scanning/recommended-hardware-resources-for-running-codeql) given that our largest dataset of 7k programs and 884k lines of code (computed with [sloccount](https://dwheeler.com/sloccount/)).


## Software Environment

We distinguish between two setups:

### Recommended for First/Occasional Use (e.g. research)
This is recommended for anyone interested in the first try of LintQ, it requires minimal installation and setup.

- **Docker** (tested with versions: `24.0.2, build cb74dfc` and `20.10.23, build7155243`). Run `docker --version` to check the version. If not present,install [here](https://docs.docker.com/get-docker/).
- **Conda** (tested with versions: `24.3.0` and `22.9.0`). Run `conda --version` to check the version. If not present, install [here](https://docs.conda.io/en/latest/miniconda.html).


### Recommended for Regular Use (e.g. quantum developer)
This is recommended for anyone interested in using LintQ on his/her own quantum programs when developing. These tooling will allow you to run the LintQ queries from your IDE and see the results direcly there.

- **VSCode** (tested with versions: `1.88.1`). Run `code --version` to check the version. If not present, install [here](https://code.visualstudio.com/).
- **SARIF Viewer Extension for VSCode** (tested with versions: `3.4.4`). Available [here](https://marketplace.visualstudio.com/items?itemName=MS-SarifVSCode.sarif-viewer).
- [IMPORTANT PRECISE VERSION] **Codeql CLI Version**: 2.11.2 (PRECISELY THIS). Run `codeql version` to check the version. If not present, install [here](https://github.com/github/codeql-cli-binaries/releases/tag/v2.11.2).
- [IMPORTANT PRECISE VERSION] **CodeQL for Visual Studio Code extension**: 1.7.4 (PRECISELY THIS). Available [here](https://github.com/github/vscode-codeql/blob/main/extensions/ql-vscode/CHANGELOG.md#174---29-october-2022).
