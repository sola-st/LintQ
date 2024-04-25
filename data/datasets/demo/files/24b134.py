# https://github.com/Z-928/Bugs4Q-Framework/blob/master/qiskit/10/buggy_10.py
from qiskit import *
qc = QuantumCircuit(1)
qc.u1(0.24,0)
print(qc.decompose())
