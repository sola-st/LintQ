from qiskit import QuantumCircuit
qc = QuantumCircuit(3)
qc.cswap(0, 1, 2)
print(qc)
from qiskit.circuit.library import CZGate
print(CZGate().to_matrix())
from qiskit.circuit.library import CPhaseGate
from math import pi
print(CPhaseGate(pi).to_matrix())
from qiskit.circuit.library import CRZGate
from math import pi
print(CRZGate(pi).to_matrix())
from qiskit import QuantumCircuit
qc = QuantumCircuit(5)
qc.mcx([0, 1, 3, 4], 2)
print(qc)
qc = QuantumCircuit(3)
qc.ccx(0, 2, 1)
qc.draw()
qc = QuantumCircuit(3)
qc.toffoli(0, 2, 1)
qc.draw()

## WRAPPER - DO NOT EDIT
from qsmell.utils.quantum_circuit_to_matrix import Justify, qc2matrix
import os
qc = qc
this_file_name = os.path.basename(__file__)
qc2matrix(qc, Justify.none, this_file_name.replace('.py', '.csv'))