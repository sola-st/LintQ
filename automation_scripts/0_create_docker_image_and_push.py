"""Create the CodeQL docker image, push it on canister.io

Canister.io is a free service that allows you to host your docker images for free in private repositories.
This script will create a docker image with the latest version of CodeQL and push it on canister.io.
This way, you can use the image in your CI/CD pipelines.
"""
import os
import pathlib

# move to the directory of the current file
os.chdir(os.path.dirname(os.path.realpath(__file__)))

FOLDER = "tmp_docker/"
# check if the folder exists, if not create it
pathlib.Path(FOLDER).mkdir(parents=True, exist_ok=True)

# check if the files username.canister.io and password.canister.io
# are present, if not ask the user and create them
credentials = {
    "username": None,
    "password": None,
    "tag_name": None,
}
for key in credentials.keys():
    if not pathlib.Path(f"{key}.canister.io").is_file():
        credentials[key] = input(f"Please enter your canister.io {key}: ")
        with open(f"{key}.canister.io", "w") as f:
            f.write(credentials[key])
    else:
        with open(f"{key}.canister.io", "r") as f:
            credentials[key] = f.read().strip()

# download the official repo
# https://github.com/microsoft/codeql-container
# in the folder
os.chdir(FOLDER)
if not pathlib.Path("codeql-container").is_dir():
    print("Cloning the official repo...")
    os.system("git clone https://github.com/microsoft/codeql-container.git")
    # add this if you want to fix the commit version:
    # 99ffb3ced1a31822235272c0b6fe5ee12ea4105e
    os.system("git checkout 99ffb3ced1a31822235272c0b6fe5ee12ea4105e")

# move to the folder
os.chdir("codeql-container")

print("Modifying the Dockerfile...")
# modify the Dockerfile by replacing the last part,
to_replace = "USER ${USERNAME}"
replace_with = """
USER ${USERNAME}
WORKDIR /opt
CMD ["/bin/bash"]
"""
with open("Dockerfile", "r") as f:
    content = f.read()
    # replace everything after the to_replace string (included)
    content = content[:content.find(to_replace)] + replace_with
with open("Dockerfile", "w") as f:
    f.write(content)

print("Building the image...")
os.system(f"docker build . -f Dockerfile -t {credentials['tag_name']}")

print("Logging in to canister.io...")
os.system(f"docker login -u {credentials['username']} -p {credentials['password']} cloud.canister.io:5000")

print("Pushing the image...")
os.system(f"docker push {credentials['tag_name']}")