from qiskit import QuantumRegister, ClassicalRegister, QuantumCircuit

qr = QuantumRegister(2)
cr = ClassicalRegister(5)
qc = QuantumCircuit(qr, cr)

# measure on single bit with register
qc.measure(qr[0], cr[0])

# measure on single bit with integer
qc.measure(qr[0], 0)
qc.measure(0, cr[0])

# measure qubit to different target
qc.h(0)
qc.measure(0, 1)

# measure in a register
qc.h(qr[0])
qc.cx(qr[0], 1)
qc.measure(qr, cr)
