from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister

qreg = QuantumRegister(3)
creg = ClassicalRegister(2)
qc = QuantumCircuit(qreg, creg)
qc.h(0)
qc.cx(0, 1)
qc.cx(1, 2)
qc.measure([0, 1], [0, 1])