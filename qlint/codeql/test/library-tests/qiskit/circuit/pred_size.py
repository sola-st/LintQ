
from qiskit import QuantumRegister, ClassicalRegister, QuantumCircuit
import numpy as np

# circuit defined size
qr_defined_size = QuantumRegister(5)
cr_defined_size = ClassicalRegister(5)

qc = QuantumCircuit(qr_defined_size, cr_defined_size)  # size: qubits=5, clbits=5


# size can be derived from function definition
def my_circuit():
    qr = QuantumRegister(5)
    cr = ClassicalRegister(5)
    qc = QuantumCircuit(qr, cr)  # size: qubits=5, clbits=5
    return qc

my_instance_of_circuit = my_circuit()  # size: qubits=5, clbits=5
my_instance_of_circuit.h(0)


# completely unknown size
magic_number = (42 / 96 * np.pi) // 6
qr_obscure_size = QuantumRegister(magic_number)
cr_obscure_size = ClassicalRegister(magic_number)

qc = QuantumCircuit(qr_obscure_size, cr_obscure_size)  # size: qubits=?, clbits=?


# unknown size with lower bound
N = len("unknown_size")

qr_unknown_size = QuantumRegister(N)
qr_known_size = QuantumRegister(1)

cr_known_size = ClassicalRegister(1)

qc = QuantumCircuit(qr_unknown_size, qr_known_size, cr_known_size)  # size: qubits=1+, clbits=1

