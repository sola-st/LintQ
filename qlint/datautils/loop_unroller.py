"""Utilities for unrolling loops in a python program.

Features:
- it can unroll simple loops with one integer or two integers as arguments
- it can unroll nested loops
- it can limit the number of iterations (default is 10)

Limitations:
- it does not handle break statements in the loop
- it cannot set a limit on the supported nesting
"""

import libcst as cst
from typing import Tuple, List, Any, Optional


class LoopUnroller(cst.CSTTransformer):
    """Class for unrolling loops in a python program."""

    def __init__(
            self,
            max_iterations: int = 10,
            max_depth: int = 4
            ) -> None:
        self.max_iterations = max_iterations
        self.max_depth = max_depth

    def unroll_program(self, program: str) -> str:
        """Unroll loops in a python program."""
        module = cst.parse_module(program)
        unrolled = self.unroll(module)
        return unrolled.code

    def unroll(self, node: cst.CSTNode) -> cst.CSTNode:
        """Unroll for loops in a python program with range.

        Note that this works for the loops which are in the form of:
        for i in range(3):
            ...
        The variable i is replaced by the actual number.
        """
        return node.visit(self)

    def is_range_loop(self, node: cst.For) -> bool:
        """Check if a for loop is a range loop."""
        return (isinstance(node.iter, cst.Call) and
                isinstance(node.iter.func, cst.Name) and
                node.iter.func.value == "range")

    def get_closer_assignment(
            self,
            node: cst.CSTNode,
            variable_name: str) -> int:
        """Get the closer assignment to a node."""
        if isinstance(node, cst.Assign):
            return node
        elif node.parent is not None:
            return self.get_closer_assignment(node.parent)
        else:
            return None

    def get_range(self, range_node: cst.CSTNode) -> Tuple[int, int]:
        """Get the range of a for loop.

        If we have two arguments and they are both integers, we assume they are
        the start and the end of the range. If we have only one argument, we
        assume it is the end of the range and the start is 0.
        """
        args = range_node.args
        if len(args) == 1:
            if isinstance(args[0].value, cst.Integer):
                return 0, int(args[0].value.value)
        elif len(args) == 2:
            if (isinstance(args[0].value, cst.Integer) and
                    isinstance(args[1].value, cst.Integer)):
                return int(args[0].value.value), int(args[1].value.value)
        raise ValueError("Invalid range node.")

    def leave_For(self, node: cst.For, updated_node: cst.For) -> cst.CSTNode:
        """Unroll a for loop."""
        # TODO : case where the iteration depends on a variable

        if not self.is_range_loop(node):
            return node

        # case where the iteration is fixed with integer values
        try:
            start, end = self.get_range(range_node=node.iter)
            if end - start > self.max_iterations:
                raise ValueError("Too many iterations.")
            print(f"Unrolling loop with range from {start} to {end}.")
        except ValueError:
            return node

        # get the iteration variable
        iteration_variable = node.target.value
        print(f"Iteration variable: {iteration_variable}")

        # get the for loop body
        for_loop_statements = node.body.body

        # replace the iteration variable with the actual number
        new_statements = []
        for i in range(start, end):
            replacer = ReplaceVariable(iteration_variable, i)
            for old_statement in for_loop_statements:
                new_statement = old_statement.visit(replacer)
                unrolled_new_statement = self.unroll(new_statement)
                new_statements.append(unrolled_new_statement)

        new_code = cst.Module(body=new_statements)
        print("New code:")
        print(new_code.code)
        return new_code


class ReplaceVariable(cst.CSTTransformer):
    """Class for replacing a variable in a python program."""

    def __init__(self, variable_name: str, value: Any) -> None:
        self.variable_name = variable_name
        self.value = value

    def visit_Name(self, node: cst.Name) -> Optional[bool]:
        """Check if a variable is the one we want to replace."""
        return True

    def leave_Name(self, node: cst.Name, updated_node: cst.Name) -> cst.CSTNode:
        """Replace a variable with a value."""
        if node.value == self.variable_name:
            return cst.Integer(str(self.value))
        else:
            return updated_node





