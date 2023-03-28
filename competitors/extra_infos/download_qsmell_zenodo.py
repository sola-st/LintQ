import requests
import os

ACCESS_TOKEN = open('../secrets/zenodo_access_token.txt').read().strip()
record_id = "7625865"

r = requests.get(
    f"https://zenodo.org/api/records/{record_id}",
    params={'access_token': ACCESS_TOKEN})
download_urls = [f['links']['self'] for f in r.json()['files']]
filenames = [f['key'] for f in r.json()['files']]

print(r.status_code)
print(download_urls)

# download the files in this folder
out_folder = f"../data/zenodo/{record_id}"
os.makedirs(out_folder, exist_ok=True)

for url, filename in zip(download_urls, filenames):
    r = requests.get(url, allow_redirects=True)
    open(os.path.join(out_folder, filename), 'wb').write(r.content)
