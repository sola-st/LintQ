from qiskit import *

qc = QuantumCircuit(2, 2)
qc.h(0)
qc.cx(0, 1)
qc.measure([0, 1], [0, 1])

backend = BasicAer.get_backend('statevector_simulator')
sim_result = execute(qc, backend).result()
print(sim_result.get_statevector(0))
