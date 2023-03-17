# ------------------------------------------------------------------------------
# Based on: https://github.com/Qiskit/qiskit-terra/blob/0.21.0/test/python/algorithms/test_linear_solvers.py

import numpy as np
from qiskit import BasicAer, QuantumCircuit
from qiskit.algorithms.linear_solvers.hhl import HHL
from qiskit.algorithms.linear_solvers.matrices.tridiagonal_toeplitz import TridiagonalToeplitz
from qiskit.algorithms.linear_solvers.matrices.numpy_matrix import NumPyMatrix
from qiskit.algorithms.linear_solvers.observables.absolute_average import AbsoluteAverage
from qiskit.algorithms.linear_solvers.observables.matrix_functional import MatrixFunctional
from qiskit.circuit.library.arithmetic.exact_reciprocal import ExactReciprocal
from qiskit.quantum_info import Operator, partial_trace
from qiskit.opflow import I, Z, StateFn
from qiskit.utils import QuantumInstance
from qiskit import quantum_info

# Based on https://github.com/Qiskit/qiskit-terra/blob/0.21.0/test/python/algorithms/test_linear_solvers.py#L275

matrix = TridiagonalToeplitz(2, 1, 1 / 3, trotter_steps=2)
right_hand_side = [1.0, -2.1, 3.2, -4.3]
observable = MatrixFunctional(1, 1 / 2)
decimal = 1

if isinstance(matrix, QuantumCircuit):
    num_qubits = matrix.num_state_qubits
elif isinstance(matrix, (np.ndarray)):
    num_qubits = int(np.log2(matrix.shape[0]))
elif isinstance(matrix, list):
    num_qubits = int(np.log2(len(matrix)))

rhs = right_hand_side / np.linalg.norm(right_hand_side)

# Initial state circuit
qc = QuantumCircuit(num_qubits)
qc.isometry(rhs, list(range(num_qubits)), None)

hhl = HHL()
solution = hhl.solve(matrix, qc, observable)
approx_result = solution.observable

# Calculate analytical value
if isinstance(matrix, QuantumCircuit):
    exact_x = np.dot(np.linalg.inv(matrix.matrix), rhs)
elif isinstance(matrix, (list, np.ndarray)):
    if isinstance(matrix, list):
        matrix = np.array(matrix)
    exact_x = np.dot(np.linalg.inv(matrix), rhs)
exact_result = observable.evaluate_classically(exact_x)

# ------------------------------------------------------------------------------
