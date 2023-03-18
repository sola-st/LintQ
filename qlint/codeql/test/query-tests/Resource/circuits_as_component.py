from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
from qiskit import execute, Aer


# circuit used as a component, returned by a function
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


# circuit used as a component, returned by a function, we cannot know if they
# will be attached later to another part which fully uses the qubits, thus we
# do not raise a warning


def produce_circuit():
    unk_qc = QuantumCircuit(3)  # LEGIT: DISABLE WARNING OversizedCircuit
    unk_qc.h(0)
    unk_qc.cx(0, 1)
    return unk_qc


# the circuit has only qubits because it is a sub-circuit
circ = QuantumCircuit(3)  # LEGIT CIRCUIT WITH NO BITS
circ.h(0)
circ.cx(0, 1)
circ.cx(0, 2)
meas = QuantumCircuit(3, 3)
meas.barrier(range(3))
meas.measure(range(3), range(3))
qc = meas.compose(circ, range(3), front=True)

# the circuit has an unknown subcircuit, thus we cannot know if the qubits are
# used or not in that subcircuit, thus we do not raise a warning
# same for circuits with unknown size.


def get_unknown_number():
    return 42


circ2 = QuantumCircuit(3)  # DISABLED WARNING OversizedCircuit
circ2.h(0)
unknown_n = get_unknown_number()
unknown_qc = QuantumCircuit(unknown_n)  # LEGIT: DISABLE WARNING OversizedCircuit
circ2 = circ2.compose(unknown_qc, front=True)

# circuit with a register of unknown size


def get_size():
    return 3


n = get_size()
unk_reg = QuantumRegister(n)
normal_reg = QuantumRegister(3)
circ3 = QuantumCircuit(normal_reg, unk_reg)  # DISABLED OversizedCircuit
circ3.h(unk_reg[0])


# circuit used for plotting >> Disable Unmeasureable Qubit warning
qc_plot = QuantumCircuit(3)  # LEGIT: DISABLE WARNING
qc_plot.h(0)
qc_plot.cx(0, 1)
qc_plot.draw(output='mpl')


# circuit used for simulation >> Disable Unmeasureable Qubit warning
backend = Aer.get_backend('unitary_simulator')
qc = QuantumCircuit(2)
qc.cx(1, 0)
qc.ry(np.pi/2, 1)
qc.rxx(np.pi/2, 1, 0)
qc.ry(-np.pi/2, 1)
qc.rx(-np.pi/2, 0)
qc.p(-np.pi/2, 1)
job = execute(qc, backend)
result = job.result()
print(result.get_unitary(qc, decimals=3))