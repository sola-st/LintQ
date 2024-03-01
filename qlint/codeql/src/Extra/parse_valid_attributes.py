target_file = "valid_attributes_for_qc_0.41.0.txt"

# read the file
with open(target_file, "r") as file:
    data = file.readlines()
    # drop the newline character
    data = [line.strip() for line in data]

# print the list with double quotes
data_str = ', '.join([f'"{line}"' for line in data])
print(data_str)