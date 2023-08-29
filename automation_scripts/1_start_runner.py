"""Start the local runner to run CodeQL tests when pushing to GitHub.
"""
import os
import pathlib

RUNNER_FOLDER = "/home/paltenmo/actions-runner/"

# move to the runner folder
os.chdir(RUNNER_FOLDER)

# start the runner with screen
os.system("screen -dmS runner ./run.sh")