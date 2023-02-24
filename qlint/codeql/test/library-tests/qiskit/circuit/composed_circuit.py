from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister

# create the subcircuit
qreg = QuantumRegister(3)
creg = ClassicalRegister(3)
qc_subcircuit = QuantumCircuit(qreg, creg)

# create the main circuit
q = QuantumRegister(10)
c = ClassicalRegister(8)
qc_macro = QuantumCircuit()
qc_macro.add_register(q)
qc_macro.add_register(c)

# compose the two with the compose method
qc_macro.compose(qc_subcircuit, qubits=q, clbits=c)
