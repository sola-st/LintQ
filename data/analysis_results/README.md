## How to inspect Warnings locally

To read the sarif file:

1. Download the sarif file
2. Download the files with warnings (typically a zip or a folder)

TIP: for convenience we suggest to create a folder called `inspection`, store the `data.sarif` file and a subfolder `files` with the files in it.

3. Open the `inspection` fodler with VSCode
4. Install the extension `sarif viewer` form the store

5. Open the file `data.sarif` the result pane should open automatically, otehrwise press `ctrl+shift+p` and type `SARIF: show panel` and select it with enter.
6. Now you can inspect the warning.

TIP: we recommend to inspect them by rule, use the menu on top to filter by rule.

7. Now by click on a rule, then onto a file. VScode should then ask you to locate the file on disk, this has to be done for the first, then the