import os
import click
import subprocess
import yaml


def merge_sarif_files(sarif_files, output_file):
    """Merge SARIF files into a single file.

    It relies on the command line tool: sarif-tools
    You can install it with: pip install sarif-tools
    """
    command = f"sarif copy --output {output_file} {' '.join(sarif_files)}"
    # print(f"Running command: {command}")
    try:
        subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as e:
        print(f"Error occurred while merging SARIF files: {e.output.decode()}")
    else:
        print(f"Merged SARIF files saved to {output_file}")



@click.command()
@click.argument('config_file', type=click.Path(exists=True))
def merge_sarif(config_file):
    """Merge SARIF files into a single file.

    It relies on the command line tool: sarif-tools
    You can install it with: pip install sarif-tools

    Args:
        folder (str): Folder containing SARIF files.
        output_file (str): Name of the output SARIF file.
    """
    config = yaml.safe_load(open(config_file))
    folder = config['output_folder']
    try:
        path_merged_output_sarif = config['sarif_file_all_rules']
    except KeyError:
        print(
            "No output file specified in the config file." +
            "Add the field 'sarif_file_all_rules' to the config file.")
    output_filename = os.path.basename(path_merged_output_sarif)

    print("Looking for SARIF files in:", folder)
    sarif_files = [
        file for file in os.listdir(folder)
        if file.endswith('.sarif') and file != output_filename]
    sarif_files = [os.path.join(folder, file) for file in sarif_files]
    print("SARIF files to merge:", sarif_files)
    merge_sarif_files(sarif_files, path_merged_output_sarif)


if __name__ == '__main__':
    merge_sarif()