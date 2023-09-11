from qiskit import execute, QuantumCircuit, QuantumRegister, ClassicalRegister
from qiskit import assemble, Aer

qc = QuantumCircuit(2)
qc.initialize(0, 0)
qc.h(0)
qc.cx(0, 1)

backend = Aer.get_backend('unitary_simulator')
unitary = backend.run(qc).result().get_unitary()  # BUG - NO TRANSPILATION