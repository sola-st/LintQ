# FAQ on LintQ


## 1. Why does the current analysis report only 6 rules, whereas the paper describes 10 rules?

As mentioned in the paper (see `Answer to RQ3` box), we implement 10 rules; however, we consider only the 6 rules (with higher precision) as the default LintQ configuration.

If you wish to use all the rules, you can use the different CodeQL query suite file `LintQ-all.qls` instead of `LintQ.qls` in the analysis command.

```bash
docker run \
    -v "$(pwd)/data:/home/codeql/project/data" \
    -v "$(pwd)/LintQ-all.qls:/home/codeql/project/LintQ-all.qls" \
    -it --rm lintq \
codeql database analyze \
    --format=sarifv2.1.0 \
    --threads=10 \
    --output=/home/codeql/project/data/datasets/demo/my_results.sarif \
    --rerun \
    -- /home/codeql/project/data/datasets/demo/codeql_db \
    /home/codeql/project/LintQ-all.qls
```

## 2. Which Qiskit version is supported by LintQ?

The original version of LintQ at publication time is designed for Qiskit v0.45.2. However, you can try to use a different version of Qiskit by changing the version in the `pip install qiskit==0.45.2` command in the [REQUIREMENTS](REQUIREMENTS.md). Note that you are not guaranteed to have all the rules working as expected, as the rules are based on the model of the Qiskit library (inferred by the actual Qiskit files in the `site-packages` folder). If you wish to adapt it to better fit a new Qiskit version (e.g., after the major upgrade to v1.0), you are welcome to submit a PR. (Note: To use a different version in the Docker setup, you need to change the file [requirements.txt](config/dockerimage_for_codeql/container/requirements.txt) and rebuild the Docker image.)


## 3. Why are the results of the analysis different from what is reported?

Some common explanations for the differences are:
1. **Different CodeQL version**: Make sure to use the same version mentioned in the [REQUIREMENTS](REQUIREMENTS.md). Using a different version might change the way the base Python language is modeled and lead to inconsistencies.
2. **Different Python environment**: Ensure you use the command `codeql database create ...` within a Python environment that uses the Qiskit version specified in the [REQUIREMENTS](REQUIREMENTS.md). Issues can arise when using a conda or venv Python environment that does not have Qiskit or has a different version. LintQ uses the model of the Qiskit library (inferred by the actual Qiskit files in the `site-packages` folder) to understand the quantum programs. If the model is different, the results will be different. You can check whether your database is created using those files by ensuring that the output of the database creation contains something like the `...packages/qiskit/...` substring, e.g.:
    ```bash
    ...
    [INFO] [19] Extracted file /usr/lib/python3/dist-packages/qiskit/quantum_info/synthesis/xx_decompose/weyl.py in 211ms
    ...
    ```

## Further Help

If, after multiple checks and reading all the `.md` files in the project, you are sure that your issue is not covered, feel free to either reach the first author via email (see the paper) or open an issue on the GitHub repository.