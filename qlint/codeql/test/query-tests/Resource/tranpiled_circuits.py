from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
from qiskit import execute, Aer, transpile

# simple gate after transpiled
circuit = QuantumCircuit(2, 2)
circuit.h(0)
circuit.cx(0, 1)
circuit.measure(0, 0)
circuit.measure(1, 1)
qc_transpiled_simple_op = transpile(
    circuit)
qc_transpiled_simple_op.h(0)  # BUG


# transpilation of a circuit ending with swap gate
circuit_w_final_swap = QuantumCircuit(2, 2)
circuit_w_final_swap.h(0)
circuit_w_final_swap.swap(0, 1)
circuit_w_final_swap_ruined = transpile(
    circuit_w_final_swap, optimization_level=3)
circuit_w_final_swap_ruined.measure([0, 1], [0, 1])  # BUG


# transpilation of a circuit to re-use as subcircuit (with SWAP) with append
subcircuit = QuantumCircuit(2, 2)
subcircuit.h(0)
subcircuit.swap(0, 1)
subcircuit.measure(0, 0)
subcircuit.measure(1, 1)
subcircuit_transpiled = transpile(
    subcircuit, optimization_level=3)
main_circuit_w_append = QuantumCircuit(2, 2)
main_circuit_w_append.append(subcircuit_transpiled, [0, 1], [0, 1])


# transpilation of a circuit to re-use as subcircuit (with SWAP) with compose
qc_sub = QuantumCircuit(2, 2)
qc_sub.h(0)
qc_sub.swap(0, 1)
qc_sub.measure(0, 0)
qc_sub.measure(1, 1)
qc_sub_transpiled = transpile(
    qc_sub, optimization_level=3)
main_circuit_w_compose = QuantumCircuit(2, 2)
main_circuit_w_compose.compose(subcircuit_transpiled, [0, 1], [0, 1])
