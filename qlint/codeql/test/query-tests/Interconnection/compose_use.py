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
