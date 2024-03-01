"""Ghost QASM import.

Check that the QuantumCircuit.from_qasm_str return value is assigned to a
 quantum circuit,
"""

from qiskit import QuantumCircuit

qasm_str = """OPENQASM 2.0;
include "qelib1.inc";
qreg q[3];
creg c[3];
h q[0];
h q[1];
cx q[0],q[2];
h q[2];

measure q[0] -> c[0];
measure q[1] -> c[1];
measure q[2] -> c[2];
"""
qc = QuantumCircuit(3, 3)
qc.from_qasm_str(qasm_str)  # BUG: qc is not used

qc = QuantumCircuit(3, 3)
qc.append(QuantumCircuit.from_qasm_str(qasm_str))  # LEGAL

print(qc.draw())
