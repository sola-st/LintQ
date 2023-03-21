""" No-alignment between the logical and physical qubits (LPQ) """

import sys
import ast
import pandas as pd
from competitors.qsmell_static.ISmell import ISmell


class LPQ(ISmell):

    def __init__(self):
        super().__init__("LPQ")

    def __is_initial_layout_used(self, keywords) -> bool:
        for keyword in keywords:
            if keyword.arg == 'initial_layout':
                return (True)
        return (False)

    def compute_metric(self, tree: ast.Module, output_file_path: str) -> float:
        num_transpiles_without_initial_layout = 0

        for node in ast.walk(tree):
            # print(ast.dump(node)) # debug

            if isinstance(node, ast.Call):
                # Call(func=Name(id='transpile', ctx=Load()), args=[Name(id='qc', ctx=Load()), Name(id='backend', ctx=Load())], keywords=[])
                # Call(func=Attribute(value=Attribute(value=Name(id='self', ctx=Load()), attr='_quantum_instance', ctx=Load()), attr='transpile', ctx=Load()), args=[Name(id='circuit', ctx=Load())], keywords=[])
                func = node.func
                args = node.args
                keyws = node.keywords

                if isinstance(func, ast.Name):
                    id = func.id
                    if id == 'transpile' and len(args) >= 2:
                        if self.__is_initial_layout_used(keyws) == False:
                            # print(ast.dump(node)) # debug
                            # print('  Found a function call to transpile at line %d' %(node.lineno))
                            num_transpiles_without_initial_layout += 1
                elif isinstance(func, ast.Attribute):
                    # Attribute(value=Attribute(value=Name(id='self', ctx=Load()), attr='_quantum_instance', ctx=Load()), attr='transpile', ctx=Load())
                    attr = func.attr
                    if attr == 'transpile' and len(args) >= 1:
                        if self.__is_initial_layout_used(keyws) == False:
                            # print('  Found a method call call to transpile at line %d' %(node.lineno))
                            num_transpiles_without_initial_layout += 1

            elif isinstance(node, ast.Expr):
                # Expr(value=Call(func=Attribute(value=Name(id='backend', ctx=Load()), attr='transpile', ctx=Load()), args=[Name(id='qc', ctx=Load())], keywords=[]))
                value = node.value

                if isinstance(value, ast.Call):
                    func = value.func
                    args = value.args
                    keyws = value.keywords

                    if isinstance(func, ast.Attribute):
                        attr = func.attr
                        if attr == 'transpile' and len(args) >= 1:
                            if self.__is_initial_layout_used(keyws) == False:
                                # print('  Found a expression call to transpile at line %d' %(node.lineno))
                                num_transpiles_without_initial_layout += 1

        metrics = {
            'metric': self._name,
            'value': num_transpiles_without_initial_layout
        }

        out_df = pd.DataFrame.from_dict([metrics])
        sys.stdout.write(str(out_df) + '\n')
        out_df.to_csv(output_file_path, header=True, index=False, mode='w')
        return num_transpiles_without_initial_layout
