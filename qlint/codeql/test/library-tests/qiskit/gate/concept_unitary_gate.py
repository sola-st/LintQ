from qiskit.extensions import UnitaryGate

circ = QuantumCircuit(2)

unkn = "unkn"

circ.append(UnitaryGate(data=unkn), qargs=unkn)