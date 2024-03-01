 from qiskit import QuantumCircuit, Aer
def init_circuit(theta):
    qc = QuantumCircuit(5, 1)
    qc.h(0)
    for i in range(4):
        qc.cx(i, i+1)
    qc.barrier()
    qc.rz(theta, range(5))
    qc.barrier()
    for i in reversed(range(4)):
        qc.cx(i, i+1)
    qc.h(0)
    qc.measure(0, 0)
    return qc

theta_range = [0.00, 0.25, 0.50, 0.75, 1.00]
for theta_val in theta_range:
    qc = init_circuit(theta_val)
    backend = Aer.get_backend('qasm_simulator')
    job = backend.run(qc)  # BUG: repeated backend run
    job.result().get_counts()
