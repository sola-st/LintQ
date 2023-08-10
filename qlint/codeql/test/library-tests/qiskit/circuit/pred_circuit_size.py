from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister

qreg = QuantumRegister(3)
creg = ClassicalRegister(3)
qc_only_reg = QuantumCircuit(qreg, creg)

qc_only_integers = QuantumCircuit(2, 1)

q = QuantumRegister(10)
c = ClassicalRegister(8)
qc_add_register = QuantumCircuit()
qc_add_register.add_register(q)
qc_add_register.add_register(c)

qc_multi_registers = QuantumCircuit(q, c, qreg, creg)
