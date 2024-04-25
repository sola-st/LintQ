from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
from qiskit import execute, Aer
qc = QuantumCircuit(2, 2)
qc.h(0)
qc.measure(0, 0)
qc.cx(0, 1)  # BUG
qc.measure(1, 1)
