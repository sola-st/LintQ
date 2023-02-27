from qiskit import QuantumCircuit, transpile
circuit = QuantumCircuit(2, 2)
circuit.h(0)
circuit.cx(0, 1)
circuit.measure([0, 1], [0, 1])
qc_transpiled_simple_op = transpile(circuit)
qc_transpiled_simple_op.h(0)  # BUG