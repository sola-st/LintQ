"""Undefined Backend.

Check if the backend variable is used but never defined
"""


from qiskit import QuantumCircuit, Aer, execute

qc = QuantumCircuit(5, 1)
qc.h(0)
for i in range(4):
    qc.cx(i, i+1)
qc.barrier()
theta = 0.5
qc.rz(theta, range(5))

qc.measure(0, 0)

# MISSING DEFINITION
# backend = Aer.get_backend('qasm_simulator')
job = backend.run(qc)  # BUG: MISSING DEFINITION OF backend
counts = job.result().get_counts()

print(counts)