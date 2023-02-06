for RELATIVE_FILEPATH in matrix_format/*
do
    FILE_NAME=$(basename $RELATIVE_FILEPATH)
    python -m qsmell --smell-metric IdQ --input-file $RELATIVE_FILEPATH --output-file metrics/IdQ/$FILE_NAME
done