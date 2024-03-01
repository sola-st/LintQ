from qiskit import QuantumCircuit, Aer, execute

circuit = QuantumCircuit(3, 3)
circuit.h(0)
circuit.h(1)
circuit.cx(0, 2)
circuit.iden(0)
circuit.measure([0, 1, 2], [2, 1, 0])

circuit.draw()
