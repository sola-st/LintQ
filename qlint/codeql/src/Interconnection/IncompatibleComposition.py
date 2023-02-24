from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
qc_subcircuit = QuantumCircuit(5, 5)
qc_subcircuit.h(0)
qc_macro = QuantumCircuit(4, 4)
qc_macro.z(2)
qc_macro.compose(qc_subcircuit, inplace=True)