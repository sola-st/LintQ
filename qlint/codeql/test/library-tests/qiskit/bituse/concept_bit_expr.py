from qiskit import QuantumRegister, ClassicalRegister, QuantumCircuit


# range with a constant
n = 7
qr = QuantumRegister(n)
cr = ClassicalRegister(5)
qc_range = QuantumCircuit(qr, cr)
qc_range.h(3-2)  # subtract
qc_range.measure(1+3, cr[0])  # sum


# sum with constant and variable
i = 3
qc_last = QuantumCircuit(7, 7)
qc_last.rx(0, 1+i)
qc_last.measure(range(7), range(7))


# sum with a register
my_reg = QuantumRegister(9)
my_qc = QuantumCircuit(my_reg)
a = 3
my_qc.cx(my_reg[2], my_reg[2+1])
my_qc.cx(my_reg[3], my_reg[a+3])
my_qc.measure_all()