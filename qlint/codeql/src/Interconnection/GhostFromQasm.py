from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
qasm = '''OPENQASM 2.0;
include "qelib1.inc";
qreg q[1];
creg c[1];
measure q -> c;'''
qc = QuantumCircuit()
qc.from_qasm_str(qasm)  # BUG - the new circuit is lost
qc.draw()  # returns empty circuit
