"""Simulator size overflow.

Check if the circuit is larger than the supported simulator (e.g.  Aer.get_backend(’qasm_simulator’) supports max 30 qubits,  BasicAer.get_backend(’qasm_simulator’) supports max 24 qubits)
"""

from qiskit import QuantumCircuit, Aer, execute
from qiskit import QuantumRegister, ClassicalRegister


qc = QuantumCircuit(50, 50)
qc.h(0)
qc.h(1)
qc.cx(0, 2)
qc.h(2)
for i in range(3, 50):
    qc.cx(0, i)

qc.measure([i for i in range(50)], [i for i in range(50)])

backend = Aer.get_backend('statevector_simulator')
job = backend.run(qc)

counts = job.result().get_counts()
print(counts)
