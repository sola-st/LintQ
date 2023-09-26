"""Run LintQ and all the other competitor on a given program.

Usage:
    python -m automation_scripts.4_run_on_program --program ../notebooks/program.py --output results --timeout 60 --max-iterations 10
"""

import click
import os
import shutil
import pathlib
from qlint.datautils.loop_unroller import LoopUnroller
import competitors.pylint.run_pylint_folder as pylint
import competitors.qchecker_parallel.run_qchecker_folder as qchecker
from typing import Any, Optional, List, Tuple


@click.command()
@click.option("--program", default="programs/program.py", help="Path to program.")
@click.option("--output", default="results", help="Path to output folder.")
@click.option("--timeout", default=60, help="Timeout in seconds.")
@click.option("--max-iterations", default=10, help="Max iterations for unrolling.")
def analyze(program: str, output: str, timeout: int, max_iterations: int) -> None:
    """Run LintQ and all the other competitor on a given program."""
    # change to folder of current file
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    # Create output folder if it does not exist
    pathlib.Path(output).mkdir(parents=True, exist_ok=True)

    # copy the program in the output folder
    shutil.copy(program, output)

    # apply the loop unrolling
    unroller = LoopUnroller(max_iterations=max_iterations)

    # unroll program
    with open(program, "r") as f:
        program_text = f.read()
    unrolled_program_text = unroller.unroll_program(program_text)
    with open(os.path.join(output, "unrolled_program.py"), "w") as f:
        f.write(unrolled_program_text)

    # Run LintQ

    # crate codeql DB
    print(f"Creating codeql database in {output}/codeql")
    os.system(f"codeql database create {output}/codeql --language=python")

    print("Running LintQ...")
    # run LintQ
    os.system(f"screen codeql database analyze {output}/codeql --format=sarifv2.1.0 --output={output}/data.sarif --threads=20 ../qlint/codeql/src")

    # run the other tools
    print("Running pylint...")
    pathlib.Path(f"{output}/pylint").mkdir(parents=True, exist_ok=True)
    pathlib.Path(f"{output}/pylint_error").mkdir(parents=True, exist_ok=True)
    pylint.analyze_file(
        filepath=f"{output}/unrolled_program.py",
        metric_name="pylint",
        metric_output_folder=f"{output}/pylint",
        error_output_folder=f"{output}/pylint_error"
    )

    metrics_to_compute = [
        "IIS",
        "PE",
        "CE",
        "CM",
        "IM",
        "QE",
        "IG",
        "DO",
        "MI"
    ]

    print("Running QChecker...")
    for metric_name in metrics_to_compute:
        print(f"Running {metric_name}...")
        pathlib.Path(f"{output}/{metric_name}").mkdir(parents=True, exist_ok=True)
        pathlib.Path(f"{output}/{metric_name}_error").mkdir(parents=True, exist_ok=True)
        qchecker.analyze_file(
            filepath=f"{output}/unrolled_program.py",
            metric_name=metric_name,
            metric_output_folder=f"{output}/{metric_name}",
            error_output_folder=f"{output}/{metric_name}_error")





if __name__ == "__main__":
    analyze()