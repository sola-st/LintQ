from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
from qiskit import execute, Aer
n = 4
x = 2
qreg = QuantumRegister(x)
creg = ClassicalRegister(n)