from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister

# gate in between measurements
qc = QuantumCircuit(2, 2)
qc.h(0)
qc.measure(0, 0)
qc.cx(0, 1)  # BUG
qc.measure(1, 1)

# new circuit in the loop
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
