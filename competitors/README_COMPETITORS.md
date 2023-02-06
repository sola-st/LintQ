

# A. QSmell
To run qsmell on a new set of programs (e.g., those in ``). Follow this steps:

1. install Qsmell library in the current virtual environment. To do so, run the following command:
    ```bash
    # activate the environment
    source venv38/bin/activate
    # install the library
    python3 setup.py install
    ```

1. Add this lines at the end of your files (e.g., `vqe.py`):
    ```python
    # ORIGINAL CODE ...

    ## WRAPPER - DO NOT EDIT
    from qsmell.utils.quantum_circuit_to_matrix import Justify, qc2matrix
    import os
    qc = your_quantum_circuit  # THIS IS THE QUANTUM CIRCUIT YOU WANT TO ANALYZE
    this_file_name = os.path.basename(__file__)
    destination_folder = '/home/paltenmo/projects/qlint/data/analysis_results/demo/qsmell/matrix_format'
    target_file = os.path.join(destination_folder, this_file_name.replace('.py', '.csv'))
    qc2matrix(qc, Justify.none, target_file)
    ```

1. Edit the variable `your_quantum_circuit` with the name of the variable name used for the quantum circuit in your file (e.g., `vqe_circuit`).
Note that the output will be saved in the `destination_folder` defined in the previous wrapper. The name of the file will be the same as the original file, but with the extension `.csv`, it will contain the matrix representation of the quantum circuit as per dynamic analysis.

1. Run the program (e.g., `python vqe.py`). Remember to run it when the virtual environment is activated.


1. To detect the actual smell, we have two options depending on how many file you want to run Qsmell:
    - **Single run**: Run the following command to run the analysis (from the root):
        ```bash
        python -m competitors.qsmell.qsmell --smell-metric IdQ --input-file data/analysis_results/demo/qsmell/matrix_format/vqe.csv --output-file data/analysis_results/demo/qsmell/metrics/IdQ/vqe.csv
        ```
        read the output file (e.g., `results.csv`). It will contain only one line with the relevant metric.
    - **Batch run**: Run the following command to run the analysis on all the files in a folder:
        ```bash
        source /home/paltenmo/projects/qlint/venv38/bin/activate
        cd data/analysis_results/demo/qsmell
        ./generate_IdQ_from_matrix.sh
        ```