from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
qreg = QuantumRegister(3)
c = ClassicalRegister(1)
circuit = QuantumCircuit(qreg, c)
circuit.s(0)
circuit.cx(0, 1)
circuit.h(0).c_if(c, 1)
circuit.measure(0, 0)

