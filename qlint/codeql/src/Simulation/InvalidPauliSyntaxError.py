from qiskit.quantum_info import Pauli

P_valid = Pauli('-iXYZ')
P_invalid = Pauli('--iXYZ')  # BUG: invalid Pauli string