from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
circuit = QuantumCircuit(2, 2)
circuit.h(0)  # BUG
circuit.cx(0, 1)  # BUG
circuit.measure(1, 1)
