import matplotlib.pyplot as plt
import numpy as np
from qiskit import IBMQ, Aer
from qiskit.providers.ibmq import least_busy
from qiskit import QuantumCircuit, ClassicalRegister, QuantumRegister, execute
from qiskit.visualization import plot_histogram
pi = np.pi


def grover_circuit(n):
    qc = QuantumCircuit(n)
    for qubit in range(n):
        qc.h(qubit)
    qc.x(0)
    qc.x(2)
    qc.barrier()
    qc.cu1(pi / 4, 0, 3)
    qc.cx(0, 1)
    qc.cu1(-pi / 4, 1, 3)
    qc.cx(0, 1)
    qc.cu1(pi / 4, 1, 3)
    qc.cx(1, 2)
    qc.cu1(-pi / 4, 2, 3)
    qc.cx(0, 2)
    qc.cu1(pi / 4, 2, 3)
    qc.cx(1, 2)
    qc.cu1(-pi / 4, 2, 3)
    qc.cx(0, 2)
    qc.cu1(pi / 4, 2, 3)
    qc.barrier()
    qc.x(0)
    qc.x(2)
    qc.barrier()
    for qubit in range(n):
        qc.h(qubit)
    for qubit in range(n):
        qc.x(qubit)
    qc.barrier()
    qc.cu1(pi / 4, 0, 3)
    qc.cx(0, 1)
    qc.cu1(-pi / 4, 1, 3)
    qc.cx(0, 1)
    qc.cu1(pi / 4, 1, 3)
    qc.cx(1, 2)
    qc.cu1(-pi / 4, 2, 3)
    qc.cx(0, 2)
    qc.cu1(pi / 4, 2, 3)
    qc.cx(1, 2)
    qc.cu1(-pi / 4, 2, 3)
    qc.cx(0, 2)
    qc.cu1(pi / 4, 2, 3)
    for qubit in range(n):
        qc.x(qubit)
    for qubit in range(n):
        qc.h(qubit)
    return qc


n = 4
qc = grover_circuit(n)
qc.measure_all()


## WRAPPER - DO NOT EDIT
from qsmell.utils.quantum_circuit_to_matrix import Justify, qc2matrix
import os
qc = qc
this_file_name = os.path.basename(__file__)
destination_folder = '/home/paltenmo/projects/qlint/data/analysis_results/demo/qsmell/matrix_format'
target_file = os.path.join(destination_folder, this_file_name.replace('.py', '.csv'))
qc2matrix(qc, Justify.none, target_file)