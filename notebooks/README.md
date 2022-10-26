# Jupyter Notebooks

This folder contains the Jupyter Notebooks which come from the research projects, such as for prototypes or for data analysis.

To use python files in the main folders of the repo (e.g. rdlib), you to import the `project_path.py` file at the beginning of your notebook.

The first cell of the notebook should be:

```python

# Import standard libraries
import os
import pathlib
import json
import yaml
from typing import List, Dict, Tuple, Any

# Import custom libraries
import numpy as np
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

# Import project specific libraries
import project_path
from rdlib.fsh import load_config_and_check

```