from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
circuit = QuantumCircuit(3, 3)
circuit.h(0)
circuit.cx(0, 1)
circuit.cx(1, 2)
circuit.measure(0, 0)
circuit.measure(2, 2)
circuit.measure(0, 1)  # BUG
