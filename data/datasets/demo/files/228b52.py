# https://github.com/Z-928/Bugs4Q-Framework/blob/master/qiskit/36/buggy_36.py
#from qiskit import QuantumRegister, ClassicalRegister, QuantumCircuit
#from qiskit.extensions.standard import RXGate, RYGate, RZGate, U3Gate
#from qiskit.extensions.simulator import wait
from qiskit.extensions.simulator import *
from qiskit import *


from qiskit import execute, BasicAer, Aer

qubit = QuantumRegister(1, 'qubit')
circuit = QuantumCircuit(qubit)

circuit.x(qubit)
circuit.wait(1e-6, qubit)
circuit.rx(3.1416, qubit)

backend = Aer.get_backend('statevector_simulator')
job = execute(circuit, backend)
result = job.result()
outputstate = result.get_statevector(circuit, decimals=3)
print(outputstate)
