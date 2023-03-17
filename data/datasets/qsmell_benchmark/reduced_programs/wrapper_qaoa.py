# ------------------------------------------------------------------------------
# Based on: https://github.com/Qiskit/qiskit-terra/blob/0.21.0/test/python/algorithms/test_qaoa.py#L61

from qiskit.algorithms import QAOA
from qiskit.opflow import I, X, Z, PauliSumOp

# Based on https://github.com/Qiskit/qiskit-terra/blob/0.21.0/test/python/algorithms/test_qaoa.py#L303

qaoa = QAOA()
ref = qaoa.construct_circuit([0, 0], I ^ Z)[0]

# ------------------------------------------------------------------------------

qc = ref
