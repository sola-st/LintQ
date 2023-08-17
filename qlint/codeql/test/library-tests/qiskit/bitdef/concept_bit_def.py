from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
from qiskit.circuit import Qubit, Clbit


qreg = QuantumRegister(8)
creg = ClassicalRegister(8)
qc = QuantumCircuit(qreg, creg)

single_qubit = Qubit(qreg, 0)
anonymous_qubit = Qubit(None, None)

single_bit = Clbit(creg, 2)
anonymous_bit = Clbit()
