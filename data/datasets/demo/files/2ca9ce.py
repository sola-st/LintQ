# https://github.com/Z-928/Bugs4Q-Framework/blob/master/qiskit/1/buggy_1.py
from qiskit import QuantumCircuit

qc = QuantumCircuit(3)
qc.cx(0, 1, label='Label', ctrl_state=0)
qc.ccx(0, 1, 2, label='Label', ctrl_state=1)
