from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister

# multiple registers in a circuit, but all used
# Target FP: 06_72ca3d_591
cq = QuantumRegister(2, 'control')
tq = QuantumRegister(2, 'target')
c = ClassicalRegister(4, 'classical')
qc = QuantumCircuit(cq, tq, c)  # LEGIT: all qubits are used
qc.x(cq[0])
qc.x(cq[1])
qc.mct(cq, tq[1], tq[0])
qc.measure(tq[1], c[1])
qc.measure(tq[0], c[0])

# multiple registers in a circuit, but one not used
# Target FP: 06_72ca3d_591
q1 = QuantumRegister(2, 'control')
q2 = QuantumRegister(2, 'target')
c_small = ClassicalRegister(4, 'classical')
qc = QuantumCircuit(q1, q2, c_small)  # BUG: q2[1] is not used
qc.x(q1[0])
qc.x(q1[1])
qc.x(q2[0])
qc.measure(q2[0], c_small[0])
qc.measure(q2[1], c_small[1])


# an extra register is added implicitly with measure_all()
# TARGET FP: ddsim_b86c86
circ = QuantumCircuit(3)  # LEGIT: because of measure_all()
circ.h(0)
circ.cx(0, 1)
circ.cx(0, 2)
circ.measure_all()