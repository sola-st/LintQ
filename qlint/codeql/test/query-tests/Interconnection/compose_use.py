from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
from qiskit import execute, Aer

# ghost addition
qc_subcircuit = QuantumCircuit(3, 3)
qc_subcircuit.h(0)  # first added gate
qc_macro = QuantumCircuit(4, 4)
qc_macro.z(2)  # second added gate
qc_macro.compose(qc_subcircuit)  # ghost addition

# correct addition: store returned object
qc_macro_correct = QuantumCircuit(4, 4)
qc_macro_correct.z(2)
qc_macro_correct = qc_macro_correct.compose(qc_subcircuit)

# correct addition: inplace
qc_macro_correct_inplace = QuantumCircuit(4, 4)
qc_macro_correct_inplace.z(2)
qc_macro_correct_inplace.compose(qc_subcircuit, inplace=True)

# correct addition: for transient use inside execute
qc_macro_correct_transient = QuantumCircuit(4, 4)
qc_macro_correct_transient.z(2)
res = execute(
    qc_macro_correct_transient.compose(qc_subcircuit),
    Aer.get_backend('qasm_simulator')).result()

# incompatible composition
qc_subcircuit_too_large = QuantumCircuit(5, 5)
qc_subcircuit_too_large.h(0)
qc_macro_fail = QuantumCircuit(4, 4)
qc_macro_fail.z(2)
qc_macro_fail.compose(qc_subcircuit_too_large, inplace=True)

# ungoverned composition
qc_subcircuit_ok = QuantumCircuit(3, 3)
qc_subcircuit_ok.h(0)
qc_macro_implicit = QuantumCircuit(4, 4)
qc_macro_implicit.z(2)
qc_macro_implicit.compose(qc_subcircuit, inplace=True)

# obvious composition: disable warning
qc_subcircuit_obvious = QuantumCircuit(3, 3)
qc_subcircuit_obvious.h(0)
qc_macro_obvious = QuantumCircuit(3, 3)
qc_macro_obvious.z(2)
qc_macro_obvious.compose(qc_subcircuit_obvious, inplace=True)  # DISABLED WARNING


# ghost addition allowed on return value
def build_circuit():
    qc = QuantumCircuit(3, 3)
    qc.h(0)
    qc.cx(0, 1)
    qc.measure(0, 0)
    qc.measure(1, 1)
    qc_part_2 = QuantumCircuit(3, 3)
    qc_part_2.cx(0, 2)
    qc_part_2.measure(2, 2)
    return qc.compose(qc_part_2)  # LEGIT


# ghost addition used in an addition binary operation
qc_front = QuantumCircuit(3, 3)
qc_front.h(0)
qc_front.cx(0, 1)
qc_front.h(2)

qc_middle = QuantumCircuit(3, 3)
qc_middle.h(0)
qc_middle.cx(0, 1)
qc_middle.swap(1, 2)
qc_middle.measure([0, 1, 2], [0, 1, 2])

qc_part_2 = QuantumCircuit(3, 3)
qc_part_2.cx(0, 2)
qc_part_2.measure(2, 2)
qc = qc_front + qc_middle.compose(qc_part_2)  # LEGIT


# ghost addition used in chained compose() calls
qc_chain_1 = QuantumCircuit(2, 2)
qc_chain_1.h(0)
qc_chain_1.cx(0, 1)
qc_chain_1.measure([0, 1], [0, 1])

qc_chain_2 = QuantumCircuit(2, 2)
qc_chain_2.h(0)
qc_chain_2.cx(0, 1)
qc_chain_2.measure([0, 1], [0, 1])

qc_chain_3 = QuantumCircuit(2, 2)
qc_chain_3.rx(0.5, 0)
qc_chain_3.cx(0, 1)
qc_chain_3.measure([0, 1], [0, 1])

qc_chain = qc_chain_1.compose(qc_chain_2).compose(qc_chain_3)  # LEGIT


# incompatible composition circuit size depending on runtime value
half_adder = QuantumCircuit(3, 3)
half_adder.h(0)
half_adder.h(2)
half_adder.cx(0, 1)
qc_runtime_size = QuantumCircuit(
    len(half_adder.qubits), len(half_adder.clbits))
qc_runtime_size.compose(
    half_adder,
    qubits=list(range(len(input_circ.qubits))),
    clbits=list(range(len(input_circ.clbits))),
    inplace=True)  # LEGIT
