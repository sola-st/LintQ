from qiskit import QuantumRegister, ClassicalRegister, QuantumCircuit
from qiskit import execute, Aer, transpile

# plain reset - reset after measure

qc_plain = QuantumCircuit(2, 2)

qc_plain.x(0)
qc_plain.cx(0, 1)
qc_plain.measure(0, 0)
qc_plain.measure(1, 1)
qc_plain.reset(0)  # allowed
qc_plain.reset(1)  # allowed
qc_plain.h(0)  # allowed

# reset - at beginning of circuit

qc_begin = QuantumCircuit(2, 2)
qc_begin.reset(0)  # allowed
qc_begin.reset(1)  # allowed

qc_begin.x(0)
qc_begin.cx(0, 1)
qc_begin.measure(0, 0)
qc_begin.measure(1, 1)
qc_begin.h(0)  # BUG

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
