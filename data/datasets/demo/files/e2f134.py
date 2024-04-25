# https://github.com/Z-928/Bugs4Q-Framework/blob/master/qiskit/5/buggy_5.py
from qiskit import *
#backend = Aer.get_backend('qasm_simulator_py')

qasm = '''OPENQASM 2.0;
include "qelib1.inc";
qreg q[1];
creg c[1];
measure q -> c;'''
qc = QuantumCircuit()
qc.from_qasm_str(qasm)

print( qc.qasm() )
