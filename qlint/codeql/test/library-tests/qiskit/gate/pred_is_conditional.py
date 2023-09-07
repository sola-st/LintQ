from qiskit import QuantumRegister, ClassicalRegister, QuantumCircuit

# measurement and c_if on same register
qr = QuantumRegister(5)
cr = ClassicalRegister(5)
qc_correct = QuantumCircuit(qr, cr)
qc_correct.h(0)
qc_correct.measure(qr, cr)
qc_correct.x(0).c_if(cr, 1)
qc_correct.measure(qr, cr)

# measurement and c_if on two different registers
qr_big = QuantumRegister(5)
cr_a = ClassicalRegister(5)
cr_b = ClassicalRegister(5)
qc_buggy = QuantumCircuit(qr_big, cr_a, cr_b)
qc_buggy.h(0)
qc_buggy.measure(qr_big, cr_a)
qc_buggy.x(0).c_if(cr_b, 1)  # BUG: c_if on different register
qc_buggy.measure(qr_big, cr_a)


# c_if without measurement
qr_base = QuantumRegister(5)
cr_base = ClassicalRegister(5)
qc_strange = QuantumCircuit(qr_base, cr_base)
qc_strange.h(0)
qc_strange.x(0).c_if(cr_base, 1)  # BUG: c_if without measurement

