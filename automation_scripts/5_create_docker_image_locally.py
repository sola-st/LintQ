"""Create the CodeQL docker image."""
import os
import pathlib

# move to the directory of the current file
os.chdir(os.path.dirname(os.path.realpath(__file__)))

# move to the repo directory
os.chdir("../")

# move to the dockerimage directory
os.chdir("config/dockerimage_for_codeql")

# print current file content
with open("DockerfileTemplate", "r") as f:
    content_of_dockerfile = f.read()

# replace the placeholders in
# RUN useradd -u {your-UID}
# with the values of your UID

# get the UID
uid = os.getuid()

# replace the placeholders
content_of_dockerfile = content_of_dockerfile.replace("{your-UID}", str(uid))
# write the content to the Dockerfile
with open("Dockerfile", "w") as f:
    f.write(content_of_dockerfile)

print("Dockerfile created successfully.")

print("Content:")
print(content_of_dockerfile)

print("Building the image...")
os.system("docker build . -f Dockerfile -t codeql-for-lintq")
