from qiskit import QuantumCircuit
from qiskit import QuantumRegister, ClassicalRegister

circ = QuantumCircuit(6)

for i in range(6):
    circ.h(i)

qreg = QuantumRegister(6, 'q')
creg = ClassicalRegister(6, 'c')
circ_a = QuantumCircuit(qreg, creg)
for a in range(6):
    circ_a.h(qreg[a])


n = 3
circ_x = QuantumCircuit(3)
for x in range(n):
    circ_x.h(x)

