#!/bin/bash

# This script generates all the qhelp markdown files for the CodeQL queries
# for each of the subfolders in the current one.

# The script expects to be run from the directory containing the subfolders.
script_folder=$(pwd)


cd ../qlint/codeql/src
# get current folder
current_folder=$(pwd)

# array to store all the paths of the newly generated md files
declare -a folders_with_md_files

# iterate over all subfolders
for d in */ ; do
    # create path to the subfolder
    subfolder_path="$current_folder/$d"
    # generate the qhelp markdown files
    echo "Generating qhelp markdown files for $subfolder_path"
    codeql generate query-help --format=markdown --output="$subfolder_path" "$subfolder_path"
    # add the newly generated md files to the array
    folders_with_md_files+=("$subfolder_path"**/*.md)
done

# print the list of md files
echo "The following md files were generated:"
echo "${folders_with_md_files[@]}"

# go back to the script folder
cd "$script_folder"

# concatenate the content of all the md files
echo "Concatenating the content of all the md files"
# loop over all the folders and get the content of the md files
for folder in "${folders_with_md_files[@]}"; do
    # get the list of files at that path
    files=$(ls "$folder")
    # loop over all the files
    for file in $files; do
        echo "Concatenating the content of $file"
        # get the content of the md file
        content=$(cat "$file")
        echo "$content"
        # append the content to the file
        echo "$content" >> "$script_folder"/concatenated_md_files.md
    done
done

