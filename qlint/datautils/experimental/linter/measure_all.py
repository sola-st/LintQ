import ast

class QuantumLinterPlugin:
    name = 'Quantummeasure-all'

    def __init__(self, linter):
        self.linter = linter

    def visit_FunctionDef(self, node):
        self.linter.add_message('measure-all', node=node)