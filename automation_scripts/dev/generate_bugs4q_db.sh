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
    # create a hash of the path of length 6 chars
    hash_suffix=$(echo $file | md5sum | cut -c 1-6)
    new_file=$dataset_raw_files_path/$hash_suffix.py
    cp $file $new_file
    # read the file and append the $file path on the first line of the file
    content=$(cat $new_file)
    last_two_folders=$(echo $file | rev | cut -d '/' -f 1-3 | rev)
    github_link=https://github.com/Z-928/Bugs4Q/blob/master/$last_two_folders
    echo "# $github_link" > $new_file
    echo "$content" >> $new_file
done

# create the test database with CodeQL (multiline command)
echo "Creating the test database"
codeql database create $dataset_path/codeql_db \
    --language=python \
    --overwrite \
    --source-root=$dataset_raw_files_path


