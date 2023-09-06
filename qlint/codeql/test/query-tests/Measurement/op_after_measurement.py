from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
from qiskit import execute, Aer, transpile

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

# legit op after measurement with reset in between
# reset in for loop
qr = QuantumRegister(3)
cr = ClassicalRegister(3)
qc = QuantumCircuit(qr, cr)

for i in range(2):
    qc.x(qr[2])
    qc.cx(qr[1], qr[2])
    qc.measure(qr[0], cr[0])
    qc.measure(qr[1], cr[1])
    qc.reset(qr)


# reset in for loop - with transpilation in between

qreg = QuantumRegister(3)
creg = ClassicalRegister(3)
qc_loop = QuantumCircuit(qreg, creg)

for i in range(2):
    qc_loop.x(qreg[2])
    qc_loop.cx(qreg[1], qreg[2])
    qc_loop.measure(qreg[0], creg[0])
    qc_loop.measure(qreg[1], creg[1])
    qc_transpiled = transpile(qc_loop, backend=Aer.get_backend('qasm_simulator'))
    qc_loop.reset(qreg)

