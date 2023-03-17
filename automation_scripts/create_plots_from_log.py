import seaborn as sns
import os
import pandas as pd
import click
import json
import matplotlib.pyplot as plt
import numpy as np
from datetime import datetime
from pandarallel import pandarallel

# max workers for parallelization
pandarallel.initialize(progress_bar=True, nb_workers=8)


def create_plot_most_expensive_step(
        data: pd.DataFrame,
        output_dir: str,
        top_k: int = 10):
    """Plot the most expensive step."""
    fig, ax = plt.subplots(figsize=(20, 5))
    # drop nan values
    data = data.dropna()
    sns.barplot(
        x='duration',
        y='predicateName',
        data=data.sort_values('duration', ascending=False).head(top_k),
        ax=ax)
    ax.set_title('Most expensive steps')
    ax.set_xlabel('Duration (s)')
    ax.set_ylabel('Predicate name')
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'most_expensive_steps.png'))


@click.command()
@click.option('--log_file', default='log.txt', help='Log file to read')
@click.option('--output_dir', default='.', help='Output directory')
@click.option('--top_k', default=10, help='Top k most expensive steps')
def main(log_file, output_dir, top_k):
    """Create the plot starting from the log file."""
    # read the content of the file
    with open(log_file, 'r') as f:
        content = f.read()
    # replace each empty line with a comma
    # add a [ at the beginning and a ] at the end
    # this is needed to make the json.loads work
    content = '[' + content.replace('\n\n', ',') + ']'
    # load the json
    data = json.loads(content)
    # keep only data with completion time
    # { "completionTime" : "2023-03-17T12:10:55.386Z", .. }
    # as key
    data = [
        {
            'completionTime': datetime.strptime(
                d['completionTime']
                    if '.' in d['completionTime']
                    else d['completionTime'].replace('Z', '.000Z'),
                '%Y-%m-%dT%H:%M:%S.%fZ'),
            'predicateName': d['predicateName'],
        }
        for d in data
        if 'completionTime' in d.keys() and 'predicateName' in d.keys()]
    # keep only these columns and create a pandas df
    df = pd.DataFrame.from_records(data)
    # convert the date in timestamp and create the diff with the previous row
    df['completionTime'] = pd.to_datetime(df['completionTime'])
    # create the diff-1 with the previous row
    df['duration'] = df['completionTime'].diff(periods=1).dt.total_seconds()
    # parse the data into a timestamp with
    print(df.head())
    create_plot_most_expensive_step(
        data=df,
        output_dir=output_dir,
        top_k=top_k
    )


if __name__ == '__main__':
    main()
