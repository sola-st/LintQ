""" Smell interface. """

import pandas as pd


class ISmell:

    def __init__(self, name: str):
        self._name = name

    @property
    def name(self) -> str:
        return self._name

    def __drop_barriers__(self, df: pd.DataFrame) -> pd.DataFrame:
        for column_id in df.columns:
            column_content = [op for op in df[column_id].tolist() if op != '' and not op.lower().startswith('barrier')]
            if len(column_content) == 0:
                print('[DEBUG] removing column %s' %(column_id))
                df.drop(column_id, axis=1, inplace=True)
        return (df)

    def __drop_classical_bits__(self, df: pd.DataFrame) -> pd.DataFrame:
        clbits = [bit for bit in df.index if bit.startswith('c-')]
        for clbit in clbits:
            df.drop(clbit, axis=0, inplace=True)
        return (df)

    # def compute_metric(self, df: pd.DataFrame, output_file_path: str) -> None:
    #     raise Exception('Not implemented')

    def compute_metric(self, py_file_path: str, output_file_path: str) -> float:
        raise Exception('Not implemented')

    def __str__(self) -> str:
        return self.name
