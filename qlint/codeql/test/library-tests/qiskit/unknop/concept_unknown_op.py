import qiskit
from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister

# CASE: qc.h(qr[i]) with i being a cycle variable (unknown)

qreg = QuantumRegister(2)
qreg_2 = QuantumRegister(2)
creg = ClassicalRegister(2)

qc_w_reg_index = QuantumCircuit(qreg, qreg_2, creg)

input_string = "001"
for i in range(len(input_string)):
    qc_w_reg_index.x(qreg[i])

qc_w_reg_index.measure_all()


# CASE: qc.h(x) with x being an unknown variable

qc_w_unknown_var = QuantumCircuit(7, 5)
x = len(qc_w_unknown_var.qubits) - 1
qc_w_unknown_var.h(x)


# CASE: qc with complex arithmetic expression as argument

qc_w_complex_expr = QuantumCircuit(3, 4)
qc_w_complex_expr.add_register(qreg)

qc_w_complex_expr.h(4 + 2 * 3)


# CASE: known operation
qr = qiskit.QuantumRegister(2)
qc = QuantumCircuit(qr)
qc.h(qr[0])
qc.u1(qr[0], qr[1])

qc.measure([0, 1], [0, 1])