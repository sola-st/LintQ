#!/usr/bin/env python
"""
Detect approximate duplicates across a set of files.

Usage:
    deduplicationcli [options] DATA_PATH OUT_JSON

Options:
    -h --help                   Show this message on screen.
    --azure-info=<path>         Azure authentication information file (JSON). Used to load data from Azure storage.
    --debug                     Enable debug routines. [default: False]
    --language=<name>           The programming language of the input data. [default: python]
    --entry-id-field=<name>     The name of the field in each JSON entry that uniquely identifies it. [default: filename]
    --tokens-field-name=<name>  The name of the field in each JSON entry that contains the code tokens. [default: tokens]
"""
from docopt import docopt
from dpu_utils.utils import run_and_debug, RichPath
from tqdm import tqdm

from dpu_utils.codeutils.deduplication import DuplicateDetector


def run(arguments):
    azure_info_path = arguments.get('--azure-info', None)
    data_dir = RichPath.create(arguments['DATA_PATH'], azure_info_path)
    assert data_dir.is_dir(), "%s is not a folder" % data_dir

    detector = DuplicateDetector()  # type: DuplicateDetector[str]

    for file in tqdm(data_dir.get_filtered_files_in_dir('*.jsonl.gz'), desc='Loading files'):
        for idx, element in enumerate(file.read_as_jsonl()):
            detector.add_file(id=element[arguments['--entry-id-field']],
                              tokens=element[arguments['--tokens-field-name']],
                              language=arguments['--language'])

    print('Added files. Computing duplicates...')
    duplicates = detector.compute_duplicates()
    detector.print_clone_set_stats(duplicates)
    out_path = RichPath.create(arguments['OUT_JSON'], azure_info_path)
    out_path.save_as_compressed_file([list(l) for l in duplicates])
    print('Done.')


if __name__ == '__main__':
    args = docopt(__doc__)
    run_and_debug(lambda: run(args), args.get('--debug', False))
