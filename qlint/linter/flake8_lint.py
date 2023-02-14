"""Scaffold for the linter Flake8 plugin for quantum programs in Qiskit."""

import ast
from typing import NamedTuple, Iterator, List, Tuple


class Flake8ASTErrorInfo(NamedTuple):
    line_number: int
    offset: int
    msg: str
    cls: type


class MeasureAllWithClassicalRegisters:

    msg = 'QL100: measure_all() when an existing classical is available'

    @classmethod
    def check(cls, node: ast.Call, errors: List[Flake8ASTErrorInfo]) -> None:
        sub_node = node.func
        flag_possible_bug = False
        is_bug = False
        if isinstance(sub_node, ast.Attribute):
            print('Call (method)', sub_node.attr)
            # chack the there is not measure_all(add_bits=False)
            if sub_node.attr == 'measure_all' and node.args:
                if isinstance(node.args[0], ast.keyword):
                    if node.args[0].arg == 'add_bits':
                        if isinstance(node.args[0].value, ast.NameConstant):
                            if node.args[0].value.value is False:
                                return
                flag_possible_bug = True
                # get the parent node
                circuit_name = sub_node.value.id
            if flag_possible_bug:
                # check if the circuit has classical register
                for child in node.parent.parent.body:
                    if isinstance(child, ast.Assign):
                        if isinstance(child.targets[0], ast.Name):
                            if child.targets[0].id == circuit_name:
                                if isinstance(child.value, ast.Call):
                                    if isinstance(child.value.func, ast.Attribute):
                                        if child.value.func.attr == 'QuantumCircuit':
                                            if len(child.value.args) == 2:
                                                is_bug = True

        if is_bug:
            errors.append(
                Flake8ASTErrorInfo(
                    line_number=node.lineno,
                    offset=node.col_offset,
                    msg=cls.msg,
                    cls=cls
                )
            )


class QuantumBugVisitor(ast.NodeVisitor):

    def __init__(self):
        self.errors: List[Flake8ASTErrorInfo] = []

    def visit_Call(self, node: ast.Call) -> None:
        MeasureAllWithClassicalRegisters.check(node, self.errors)
        self.generic_visit(node)


class QuantumLinterPlugin:
    name = 'quantum_qiskit_linter_plugin'
    version = '0.0.1'

    def __init__(self, tree: ast.AST):
        self.tree = tree

    def run(self) -> Iterator[Flake8ASTErrorInfo]:
        print('Running the linter plugin')
        visitor = QuantumBugVisitor()
        visitor.visit(self.tree)
        return iter(visitor.errors)
