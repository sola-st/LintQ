from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister

# gate in between measurements
qc = QuantumCircuit(2, 2)
qc.h(0)
qc.measure(0, 0)
qc.cx(0, 1)  # BUG
qc.measure(1, 1)

# new circuit in the loop
# Target FP: 06_93508a_22
for i in range(2):
    qc_new_in_loop = QuantumCircuit(2, 2)
    qc_new_in_loop.h(0)  # LEGIT
    qc_new_in_loop.measure(0, 0)

# loop addition outside the loop
qc_new_outside_loop = QuantumCircuit(2, 2)
for i in range(2):
    qc_new_outside_loop.h(0)
    qc_new_outside_loop.crx(0.1, 0, 1)  # BUG
    qc_new_outside_loop.measure(1, 1)

# op after measurement with registers
qr = QuantumRegister(2)
qr_extra = QuantumRegister(4)
cr = ClassicalRegister(2)
qc_registers = QuantumCircuit(qr, qr_extra, cr)
qc_registers.h(qr[0])
qc_registers.measure(qr[0], cr[0])
qc_registers.cx(qr[0], qr[1])  # BUG
qc_registers.measure(qr[1], cr[1])

# op after measurement with registers
qr = QuantumRegister(2)
qr_extra = QuantumRegister(4)
cr = ClassicalRegister(2)
qc_registers = QuantumCircuit(qr, qr_extra, cr)
qc_registers.h(qr[0])
qc_registers.measure(qr[0], cr[0])
qc_registers.cx(qr_extra[0], qr_extra[1])  # LEGIT
qc_registers.measure(qr[1], cr[1])
