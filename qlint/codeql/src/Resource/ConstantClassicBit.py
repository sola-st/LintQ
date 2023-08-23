from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister

qreg = QuantumRegister(3)
creg = ClassicalRegister(3)
qc = QuantumCircuit(qreg, creg)
qc.h(0)
qc.cx(0, 2)
qc.measure(0, 0)
qc.measure(1, 1)
qc.measure(2, 2)