from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
from qiskit import execute, Aer
qc = QuantumCircuit(2, 2)
qc.h(0)
qc.cx(0, 1)
qc.measure_all()  # BUG
job = execute(qc, Aer.get_backend('qasm_simulator'), shots=1000)
result = job.result()
counts = result.get_counts(qc)
print(counts)
# outputs: {'00 00': 487, '11 00': 513}
