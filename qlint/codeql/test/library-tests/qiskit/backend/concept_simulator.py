from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
from qiskit import Aer, execute, transpile

# SIMULATOR that extracts unitary matrix

qc = QuantumCircuit(2, 5)
qc.cx(0, 1)
qc.h(0)
qc.h(1)

simulator = Aer.get_backend('unitary_simulator')
transp_qc = transpile(qc)
unitary = simulator.run(transp_qc).result().get_unitary()

# SIMULATOR that extracts statevector

qreg = QuantumRegister(7)
my_qc = QuantumCircuit(qreg)
my_qc.initialize(0, 0)
my_qc.initialize(0, 0)
my_qc.p(0, 0)
my_qc.tdg(1)
my_qc.ccx(0, 1, qreg[2])

backend = Aer.get_backend('statevector_simulator')
sim_result = execute(my_qc, backend).result()
sim_result.get_statevector(my_qc)
