# https://github.com/Z-928/Bugs4Q-Framework/blob/master/qiskit/19/buggy_19.py
from qiskit import *
from qiskit.extensions import HGate, CXGate
import qiskit.quantum_info as qi
qc = QuantumCircuit(2)
qc.h(0)
qc.cx(0,1)

qc.draw('mpl')

# no issues with the below line
qi.Operator.from_label('HI')

# error at this line
qi.Operator.from_label('CX')
