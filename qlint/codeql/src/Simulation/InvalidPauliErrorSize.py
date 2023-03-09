import numpy as np
from qiskit import execute, QuantumCircuit, QuantumRegister, ClassicalRegister
from qiskit.providers.aer.noise import NoiseModel
from qiskit.providers.aer.noise.errors import pauli_error
n_qubits = 2
circ = QuantumCircuit(n_qubits, n_qubits)
circ.h(0)
circ.rx(np.pi/4, 1)
circ.cz(0, 1)
circ.rz(np.pi, 0)
circ.measure(range(n_qubits), range(n_qubits))

basis_gates = ['id', 'h', 'rx', 'rz', 'cz']
noise_bit_flip = NoiseModel(basis_gates)

p = 0.05
error_gate1 = pauli_error([('XY', p), ('I', 1 - p)])   # BUG: different lengths
error_gate2 = error_gate1.tensor(error_gate1)
noise_bit_flip.add_all_qubit_quantum_error(error_gate1, ["h", "rx", "rz"])