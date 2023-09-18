from qiskit import QuantumRegister, ClassicalRegister, QuantumCircuit

# simple range
qr = QuantumRegister(2)
cr = ClassicalRegister(5)
qc = QuantumCircuit(qr, cr)

qc.h(range(2))
qc.measure(qr, cr[:2])

# range with a constant
n = 7
qr = QuantumRegister(n)
qc_range = QuantumCircuit(qr)
qc.h(range(2, n))

# range with two variables
qc = QuantumCircuit(7, 7)
qc.h(0)
qc.cx(0, range(2, 7))
qc.measure(range(7), range(7))

# range with a constant and a variable
i = 3
qc_last = QuantumCircuit(7, 7)
qc_last.rx(0, range(i, 7))
qc_last.measure(range(7), range(7))

# range with register
qr = QuantumRegister(7)
first_shift_qr = QuantumRegister(10)
cr = ClassicalRegister(7)
qc = QuantumCircuit(first_shift_qr, qr, cr)
qc.h(qr[2:5])
qc.measure(qr[2:5], cr[2:5])
