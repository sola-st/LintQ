#!/bin/sh

# This scripts runs all the queries in the qlint/codeql/src folder
# on a specific dataset in the data/dataset folder.
# the dataset is supposed to be created with the dataset_creation.py file
# and it expects a name exp_vXX, where XX is the version number.

# This script generates the output of the analysis in the data/analysis_output
# folder using the sarif format.

# move to the directory of this file
cd "$(dirname "$0")"

dir_all_datasets=../data/datasets
dir_analysis_output=../data/analysis_results/


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

# check that it has a codeql folder inside, otherwise abort
if [ ! -d "$dir_dataset/codeql" ]; then
    echo "The dataset does not have a codeql folder. Aborting."
    exit 1
fi

# create the output folder if it does not exist
dir_output=$dir_analysis_output/$dataset_name
mkdir -p $dir_output

CURRENT_DATE_TIME=`date "+%Y-%m-%d_%H-%M-%S"`
dir_output_specific_analysis=$dir_output/codeql_${CURRENT_DATE_TIME}
mkdir -p $dir_output_specific_analysis

echo "Analysis starting in 5 seconds..."
sleep 5
screen \
    -L -Logfile $dir_output_specific_analysis/log.txt \
    -S codeql_query_run \
    codeql database analyze \
        --format=sarifv2.1.0 \
        --threads=10 \
        --output=$dir_output_specific_analysis/data.sarif \
        --rerun \
        -- $dir_dataset/codeql \
        ../qlint/codeql/src


