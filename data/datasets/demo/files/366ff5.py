# https://github.com/Z-928/Bugs4Q-Framework/blob/master/qiskit/28/buggy_28.py
from qiskit import *

circuit = QuantumCircuit(1)
circuit.iden(0)
print(circuit)
