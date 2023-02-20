from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
from qiskit import execute, Aer
qreg = QuantumRegister(3)
creg = ClassicalRegister(2)  # BUG
circuit = QuantumCircuit(qreg, creg)
circuit.h(0)
circuit.cx(0, 1)
circuit.cx(1, 2)
circuit.measure([0, 1, 2], [0, 1, 2])  # BUG