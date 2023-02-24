#!/bin/sh

# This script generates all the qhelp markdown files for the CodeQL queries
# for each of the subfolders in the current one.

# The script expects to be run from the directory containing the subfolders.

cd ../qlint/codeql/src
# get current folder
current_folder=$(pwd)
# iterate over all subfolders
for d in */ ; do
    # create path to the subfolder
    subfolder_path="$current_folder/$d"
    # generate the qhelp markdown files
    echo "Generating qhelp markdown files for $subfolder_path"
    codeql generate query-help --format=markdown --output="$subfolder_path" "$subfolder_path"
done

