from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
qc = QuantumCircuit(2, 2)
qc.h(0)
qc.cx(0, 1)  # entanglement creation between qubit 0 and 1
qc.measure(0, 0)  # state collapse in qubit 0, influencing qubit 1
qc.rx(0.1, 1)  # qubit one operated upon: BUG
qc.measure(1, 1)
