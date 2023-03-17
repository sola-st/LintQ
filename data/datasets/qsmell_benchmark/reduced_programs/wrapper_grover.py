# ------------------------------------------------------------------------------
# Based on: https://github.com/Qiskit/qiskit-terra/blob/0.21.0/test/python/algorithms/test_grover.py#L32

import numpy as np

from qiskit import BasicAer, QuantumCircuit
from qiskit.utils import QuantumInstance
from qiskit.algorithms import Grover, AmplificationProblem
from qiskit.circuit.library import GroverOperator, PhaseOracle
from qiskit.quantum_info import Operator

# Based on: https://github.com/Qiskit/qiskit-terra/blob/0.21.0/test/python/algorithms/test_grover.py#L218

oracle = QuantumCircuit(2)
oracle.cz(0, 1)
problem = AmplificationProblem(oracle, is_good_state=["11"])
grover = Grover()
constructed = grover.construct_circuit(problem, 2, measurement=True)

grover_op = GroverOperator(oracle)
expected = QuantumCircuit(2)
expected.h([0, 1])
expected.compose(grover_op.power(2), inplace=True)

# ------------------------------------------------------------------------------

qc = expected
