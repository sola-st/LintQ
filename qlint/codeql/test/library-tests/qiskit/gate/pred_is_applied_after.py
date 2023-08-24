from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
from qiskit import execute, Aer
from qiskit.circuit.library import HGate

# last piece of the circuit
q = QuantumRegister(4)
c = ClassicalRegister(4)
qc = QuantumCircuit(q, c)
qc.h(q[0])
qc.cx(q[0], q[1])
qc.rx(0.1, q[3])

# first piece of the circuit
qc_front = QuantumCircuit(4, 4)
qc_front.s(0)
qc_front.cx(0, 1)
qc_front.cx(1, 2)
qc_front.cx(2, 3)
qc_front.t(3)
qc_front.barrier()

# combine the two circuits
qc_complete = qc_front.compose(
    qc,
    qubits=[0, 1, 2, 3],
    clbits=[0, 1, 2, 3],
)
qc_complete.draw()


# same register but different way to refer to it
qregA = QuantumRegister(3)
creg = ClassicalRegister(1)
qregB = QuantumRegister(2)
qc = QuantumCircuit(qregA, qregB, creg)
qc.append(HGate(), 1)
qc.y(qregA[1])

# mixed ref with register and integer,
# on circuit with single register
my_reg = QuantumRegister(3)
my_qc = QuantumCircuit(my_reg)
my_qc.measure(2)
my_qc.h(my_reg[2])