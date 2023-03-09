"""Test class of LoopUnroller.

Run with pytest. If you want to see the print statements, run with
pytest -s.

"""

import pytest

from qlint.datautils.loop_unroller import LoopUnroller


def test_simple_loop():
    """Test unrolling of simple loop."""
    loop_unroller = LoopUnroller(max_iterations=10)
    simple_loop = """
qc = QuantumCircuit(3,2)
for i in range(3):
    qc.h(i)
    qc.measure(i, i)
"""

    simple_loop_unrolled = """
qc = QuantumCircuit(3,2)
qc.h(0)
qc.measure(0, 0)
qc.h(1)
qc.measure(1, 1)
qc.h(2)
qc.measure(2, 2)
"""
    unrolled = loop_unroller.unroll_program(simple_loop)
    assert unrolled == simple_loop_unrolled


def test_nested_loop():
    """Test unrolling of nested loop."""
    loop_unroller = LoopUnroller(max_iterations=10)
    nested_loop = """
qc = QuantumCircuit(3,2)
for i in range(3):
    for j in range(2):
        qc.h(i)
        qc.measure(i, j)
"""

    nested_loop_unrolled = """
qc = QuantumCircuit(3,2)
qc.h(0)
qc.measure(0, 0)
qc.h(0)
qc.measure(0, 1)
qc.h(1)
qc.measure(1, 0)
qc.h(1)
qc.measure(1, 1)
qc.h(2)
qc.measure(2, 0)
qc.h(2)
qc.measure(2, 1)
"""
    unrolled = loop_unroller.unroll_program(nested_loop)
    print(unrolled)
    assert unrolled == nested_loop_unrolled


if __name__ == "__main__":
    test_simple_loop()