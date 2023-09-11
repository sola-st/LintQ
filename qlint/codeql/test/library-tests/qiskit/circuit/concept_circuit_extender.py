from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister


qr = QuantumRegister(2, "qr")
cr = ClassicalRegister(2, "cr")
qc = QuantumCircuit(qr, cr)

qc.h(qr[0])

# extend it with a function call, circuit passed as arugment


def extend(a_qc, a_qr, a_cr):
    a_qc.h(a_qr[1])


extend(qc, qr, cr)  # CIRCUIT EXTENDER via ARG


# extend it with a global circuit call

qc_global = QuantumCircuit(10, 7)


def create_my_circuit(n):
    qc_global.cx(n-1, 0)
    qc_global.measure(n//2, 0)


create_my_circuit(3)  # CIRCUIT EXTENDER via GLOBAL
