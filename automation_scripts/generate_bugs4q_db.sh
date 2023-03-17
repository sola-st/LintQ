#!/bin/sh

# This scripts collects all the python files in the bugs4q folder in the data
# folder (e.g. data/datasets/Bugs4Q_15_03_2023/Bugs4Q_raw) and moves them in
# a folder (e.g. data/datasets/Bugs4Q_15_03_2023/raw_files).

# Then it creates a test database in the folder:
# data/datasets/Bugs4Q_15_03_2023/codeql_db

# move to the directory of this file
cd "$(dirname "$0")"

dataset_path=../data/datasets/Bugs4Q_15_03_2023
dataset_raw_files_path=$dataset_path/raw_files

# create the raw_files folder if it does not exist
mkdir -p $dataset_raw_files_path

# move to the qlint/codeql folder
folder_to_mine=../data/datasets/Bugs4Q_15_03_2023/Bugs4Q_raw

# scan all the python files in the folder which are named either:
# - buggy.py
# - bug_version.py
for file in $(find $folder_to_mine -name "buggy.py" -o -name "bug_version.py") ; do
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


