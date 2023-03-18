from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister

q = QuantumRegister(3)
c = ClassicalRegister(2)
qreg = QuantumRegister(3)
qc = QuantumCircuit(q, c, qreg)  # LEGIT
qc.h(qreg[0])
qc.h(qreg[1])
qc.h(qreg[2])
qc.x(q[0])
qc.x(q[1])
qc.x(q[2])
qc.measure(q[1], c[0])
qc.measure(q[2], c[1])

# usage of qubit for measurement only
q2 = QuantumRegister(3)
c2 = ClassicalRegister(2)
qreg2 = QuantumRegister(3)
qc2 = QuantumCircuit(q2, c2, qreg2)  # BUG: qreg2 is not used
qc2.h(qreg2[0])
qc2.h(qreg2[1])
qc2.h(qreg2[2])
qc2.x(q2[2])
qc2.measure(q2[1], c2[0])
qc2.measure(q2[2], c2[1])

# unused qubit warning
q3 = QuantumRegister(3)
c3 = ClassicalRegister(2)
qreg3 = QuantumRegister(3)
qc3 = QuantumCircuit(q3, c3, qreg3)  # BUG
qc3.h(qreg3[0])
qc3.h(qreg3[2])
qc3.x(q3[0])
qc3.x(q3[1])
qc3.x(q3[2])
qc3.measure(q3[1], c3[0])
qc3.measure(q3[2], c3[1])
