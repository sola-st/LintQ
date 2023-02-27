from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
qc = QuantumCircuit(2, 2)
# operations first
qc.h(0)
qc.cx(0, 1)  # entanglement creation between qubit 0 and 1
qc.rx(0.1, 1)
# measurements last
qc.measure(0, 0)
qc.measure(1, 1)
