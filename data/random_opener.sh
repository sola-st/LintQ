#!/bin/bash

# if the first argument is available use it as the target directory
if [ -n "$1" ]; then
    targetDir="$1"
else
    targetDir="/home/paltenmo/projects/qlint/data/02_programs/exp_v01"
fi
#targetDir="/home/paltenmo/projects/qlint/data/02_programs/exp_v01"
#targetDir="/home/paltenmo/projects/qlint/data/04_program_under_study/exp_v01"
## Save the files in the array $files
files=( "$targetDir"/* )
## Cat a random file
code "${files[RANDOM % ${#files[@]}]}"