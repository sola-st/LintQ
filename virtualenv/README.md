# Virtual Environment

To keep your research reproducible use virtual environments.

You can find some example conda environments in the `conda_env_templates` folder.
They have been created via `conda env export > environment_file_name.yml` and you can set up the one you like via `conda env create -f environment_file_name.yml`.

## Virtualenv

To create a virtual environment with `virtualenv` run the following command in the terminal:

1. install virtualenv (if not already present): `pip install virtualenv`
2. create a virtual environment: `virtualenv -p python3.8 venv38`
3. activate the virtual environment: `source venv38/bin/activate`
4. install the required packages: `pip install -r virtualenv/virtualenv_templates/base_requirements.txt`

The `requirements.txt` file contains all the packages you need for your project. You can create it via `pip freeze > requirements.txt`.

