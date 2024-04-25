# https://github.com/Z-928/Bugs4Q-Framework/blob/master/qiskit/18/buggy_18.py
from qiskit import *

if __name__ == "__main__":
    backend = Aer.get_backend('statevector_simulator')
    qc = QuantumCircuit(2, 2)
    qc = QuantumCircuit(2, 2)
    qc.h(0)
    qc.cx(0, 1)
    qc.measure([0,1], [0,1])
    result = execute(qc, backend, 100).result()
    print(result.get_counts(qc))
