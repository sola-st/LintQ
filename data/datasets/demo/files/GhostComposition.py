from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
qc_subcircuit = QuantumCircuit(3, 3)
qc_subcircuit.h(0)  # first added gate
qc_macro = QuantumCircuit(4, 4)
qc_macro.z(2)  # second added gate
qc_macro.compose(qc_subcircuit)  # ghost addition
n_gates = len(qc_macro.data)
print(n_gates)  # returns 1 instead of 2