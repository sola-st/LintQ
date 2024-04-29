#!/bin/sh

# This scripts runs all the queries in the qlint/codeql/src folder
# on a sample of files in the target data folder.

# The target data folder can be picked among one of the dataset in this folder  :
# - data/datasets/
# The files will be taken from the corresponding file_selected folder:
# - data/datasets/<exp_vXX>/files_selected
# If the folder does not exist, the files will be taken from the raw_files folder:
# - data/datasets/<exp_vXX>/raw_files
# Each file is analyzed separately and a CodeQL dataset is created for it.

# This script generates the output of the analysis in the data/analysis_output
# folder using the sarif format.

# move to the directory of this file
cd "$(dirname "$0")"

dir_all_datasets=../data/datasets
dir_analysis_output=../data/analysis_results/

SAMPLE_SIZE=100
echo "Using a sample size of $SAMPLE_SIZE files."

# query for the dataset name to use among the ones in the dataset folder.
# consider only the folders
dataset_names=$(ls -d $dir_all_datasets/* | xargs -n 1 basename)
# query the user with a numeric list of the available datasets
echo "Available datasets:"
i=1
for dataset_name in $dataset_names; do
    echo "$i) $dataset_name"
    i=$((i+1))
done


echo "Choose the dataset to use:"
read dataset_index
# get the dataset name from the index
dataset_name=$(echo $dataset_names | cut -d " " -f $((dataset_index)))
dir_dataset=$dir_all_datasets/$dataset_name
echo "Using dataset $dir_dataset."


echo "Creating a sample of $SAMPLE_SIZE files from the dataset."
dir_file_selected=$dir_dataset/files_selected
# if the folder does not exist, use the /raw_files folder
if [ ! -d "$dir_file_selected" ]; then
    dir_file_selected=$dir_dataset/raw_files
fi
# sample
files_selected=$(ls $dir_file_selected | shuf -n $SAMPLE_SIZE)
# create a subfolder to store the files
dir_files_sample=$dir_dataset/sample
mkdir -p $dir_files_sample
# copy the files in the subfolder
for file in $files_selected; do
    cp $dir_file_selected/$file $dir_files_sample
done


# create a sample_codeql folder and store single DBs in it
dir_codeql_sample=$dir_dataset/sample_codeql
mkdir -p $dir_codeql_sample

counter=0

for file in $files_selected; do
    # remove file extension
    filename=$(echo $file | cut -d "." -f 1)
    # create a folder for the file
    dir_file_in_codeql=$dir_codeql_sample/$filename
    mkdir -p $dir_file_in_codeql

    # create a folder and store the file in it in the sample folder
    dir_file_in_original=$dir_files_sample/$filename
    mkdir -p $dir_file_in_original
    # move the file in the folder
    mv $dir_files_sample/$file $dir_file_in_original


    # increment counter and print
    counter=$((counter+1))
    echo "Processing file $counter/$SAMPLE_SIZE: $file"

    # if dir_file_in_codeql empty create the DB
    if [ ! "$(ls -A $dir_file_in_codeql)" ]; then
        # create a DB for the file and time it
        echo "1. DB Creation for $file starting in 3 seconds..."
        sleep 3
        start_time=$(date +%s)
        codeql database create $dir_file_in_codeql/codeql_db --language=python --source-root=$dir_file_in_original
        end_time=$(date +%s)
        # store the time in a file
        echo $((end_time-start_time)) > $dir_file_in_codeql/time_db_creation.txt
    else
        echo "1. DB for $file already exists."
    fi

    # run the queries
    echo "2. Analysis of $file starting in 3 seconds..."
    sleep 3
    start_time=$(date +%s)
    screen \
    -L -Logfile $dir_file_in_codeql/log_analysis.txt \
    -S codeql_query_run \
        codeql database analyze \
            --format=sarifv2.1.0 \
            --threads=10 \
            --output=$dir_file_in_codeql/warnings.sarif \
            --rerun \
            -- $dir_file_in_codeql/codeql_db \
            ../qlint/codeql/src
    end_time=$(date +%s)
    # store the time in a file
    echo $((end_time-start_time)) > $dir_file_in_codeql/time_analysis.txt
done
