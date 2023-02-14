# read the subject.csv file
# download all the files in the column path

import os
import pathlib
import pandas as pd
import requests

df = pd.read_csv('subjects.csv')
all_urls = df['path'].tolist()
for url in all_urls:
    r = requests.get(url, allow_redirects=True)
    filename = url.split('/')[-1]
    open(os.path.join('programs', filename), 'wb').write(r.content)