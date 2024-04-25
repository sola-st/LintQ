# https://github.com/Z-928/Bugs4Q-Framework/blob/master/qiskit/41/buggy_41.py
import numpy as np
import matplotlib.pyplot as plt
import warnings
warnings.filterwarnings('ignore')

from qiskit import QuantumCircuit, QuantumRegister, Aer, transpile, assemble
from qiskit.providers.aer import AerSimulator
from qiskit.providers.aer.library import save_statevector

# XX(t) subcircuit
def XX(target_time):
    XX_qr = QuantumRegister(2)
    XX_qc = QuantumCircuit(XX_qr, name='XX')

    XX_qc.ry(np.pi/2,[0,1])
    XX_qc.cnot(0,1)
    XX_qc.rz(2*target_time,1)
    XX_qc.cnot(0,1)
    XX_qc.ry(-np.pi/2,[0,1])
    return XX_qc

# YY(t) subcircuit
def YY(target_time):
    YY_qr = QuantumRegister(2)
    YY_qc = QuantumCircuit(YY_qr, name='YY')

    YY_qc.rx(np.pi/2,[0,1])
    YY_qc.cnot(0,1)
    YY_qc.rz(2*target_time,1)
    YY_qc.cnot(0,1)
    YY_qc.rx(-np.pi/2,[0,1])
    return YY_qc

# ZZ(t) subcircuit
def ZZ(target_time):
    ZZ_qr = QuantumRegister(2)
    ZZ_qc = QuantumCircuit(ZZ_qr, name='ZZ')

    ZZ_qc.cnot(0,1)
    ZZ_qc.rz(2*target_time,1)
    ZZ_qc.cnot(0,1)
    return ZZ_qc

# create ZZ(t)YY(t)XX(t) circuit and prepare in initial state
def quantum_circuit(target_time, num_qubits, initial_state):
    # initialize quantum circuit for 2 qubits
    qr = QuantumRegister(num_qubits)
    qc = QuantumCircuit(qr)
    # initialize circuit
    qc.initialize(initial_state)
    # construct circuit from ZZ(t), YY(t), and XX(t) subcircuits
    for i in range(0, num_qubits - 1):
        qc.append(ZZ(target_time), [qr[i], qr[i+1]])
        qc.append(YY(target_time), [qr[i], qr[i+1]])
        qc.append(XX(target_time), [qr[i], qr[i+1]])
    # measure qubits
    qc.measure_all()
    return qc

# create circuit
qc = quantum_circuit(target_time=0.0, num_qubits=2, initial_state='10')
print(qc)

backend = Aer.get_backend('statevector_simulator')
qobj = transpile(qc,backend)
job = assemble(qobj)
run_job = backend.run(job)
