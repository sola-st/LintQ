from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister


def u_dag(phi):
    circuit = QuantumCircuit(1, name="U-dag")  # LEGIT CIRCUIT WITH NO BITS
    circuit.sx(0)
    circuit.rz(np.pi / 2, 0)
    circuit.sx(0)
    circuit.rz(-phi, 0)
    circuit.sx(0)
    circuit.rz(np.pi / 2, 0)
    circuit.sx(0)
    return circuit.to_instruction()


# the circuit has only qubits because it is a sub-circuit
circ = QuantumCircuit(3)  # LEGIT CIRCUIT WITH NO BITS
circ.h(0)
circ.cx(0, 1)
circ.cx(0, 2)
meas = QuantumCircuit(3, 3)
meas.barrier(range(3))
meas.measure(range(3), range(3))
qc = meas.compose(circ, range(3), front=True)
