from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
from qiskit import execute, Aer

q = QuantumRegister(2)
c = ClassicalRegister(2)
qc = QuantumCircuit(q, c)

qc.h(q[0])
qc.cx(q[0], q[1])
qc.measure_all()  # BUG

job = execute(qc, Aer.get_backend('qasm_simulator'), shots=1000)
result = job.result()
counts = result.get_counts(qc)
print(counts)

# outputs: {'00 00': 487, '11 00': 513}
# It generates a new classical register of two bits and measures the result
# in it.