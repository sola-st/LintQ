from qiskit import QuantumCircuit, transpile
from qiskit.providers.aer import QasmSimulator
simulator = QasmSimulator()

circuit = QuantumCircuit(1, 1)
circuit.h(0)
circuit.measure([0], [0])
transpiled_circuit = transpile(circuit, simulator)
