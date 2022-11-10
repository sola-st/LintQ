# research_project_template


# Run the Test CodeQL Queries

Follow this steps:
1. Clone this repository
2. Install the CodeQL CLI from [here](https://codeql.github.com/docs/codeql-cli/getting-started-with-the-codeql-cli/)
3. Move to the source directory `qlint/codeql/src` containing the `qlpack.yml` and install the external packs (e.g. the python-all dependencies) with the following command:
    ```bash
    codeql pack install
    ```
4. Move to the `qlint/codeql` directory and run the following command:
    ```bash
    codeql test run test/query-tests/Measurement/ --search-path=src
    ```
    Take note of the path where the dependencies are stored (e.g. `/home/<username>/.codeql/packages`).

5. From the `qlint/codeql` directory, run the following command including this path:
    ```bash
    codeql test run test/query-tests/Measurement --additional-packs /home/<username>/.codeql/packages
    ```
    This will run the tests of the specific folder `query-tests/Measurement` and will use the dependencies installed in the previous step.
