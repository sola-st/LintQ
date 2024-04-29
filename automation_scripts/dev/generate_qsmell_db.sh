#!/bin/sh

# This scripts collects the python files in the subject folder of Qsemll
# folder (e.g. data/datasets/qsmell_benchmark/original_programs) and moves them in
# a folder (e.g. data/datasets/qsmell_benchmark/raw_files).

# Then it creates a test database in the folder:
# data/datasets/Bugs4Q_15_03_2023/codeql_db

# move to the directory of this file
cd "$(dirname "$0")"

dataset_path=../data/datasets/qsmell_benchmark
dataset_raw_files_path=$dataset_path/raw_files

# create the raw_files folder if it does not exist
mkdir -p $dataset_raw_files_path

# move to the qlint/codeql folder
folder_to_mine=../data/datasets/qsmell_benchmark/original_programs

# scan all the python files
for file in $(find $folder_to_mine -name "*.py") ; do
    # copy the file in the raw_files folder
    echo "Copying $file to $dataset_raw_files_path"
    cp $file $dataset_raw_files_path
done

# create the test database with CodeQL (multiline command)
echo "Creating the test database"
codeql database create $dataset_path/codeql_db \
    --language=python \
    --overwrite \
    --source-root=$dataset_raw_files_path


