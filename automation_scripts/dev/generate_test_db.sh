#!/bin/sh

# This scripts collects all the python files in the qlint/codeql folder
# and moves them in the data/datasets/tmp_test_db/raw_files folder.

# Then it creates a test database in the data/datasets/tmp_test_db/codeql_db
# folder.

# move to the directory of this file
cd "$(dirname "$0")"

dataset_path=../data/datasets/tmp_test_db
dataset_raw_files_path=$dataset_path/raw_files

# create the raw_files folder if it does not exist
mkdir -p $dataset_raw_files_path

# move to the qlint/codeql folder
folder_to_mine=../qlint/codeql

# scan all the python files in the folder,
# but not containing testproj in the path
for file in $(find $folder_to_mine -name "*.py" -not -path "*testproj*"); do
    # copy the file in the raw_files folder
    echo "Copying $file to $dataset_raw_files_path"
    cp $file $dataset_raw_files_path
done

# create the test database with CodeQL (multiline command)
echo "Creating the test database"
codeql database create $dataset_path/codeql \
    --language=python \
    --overwrite \
    --source-root=$dataset_raw_files_path


