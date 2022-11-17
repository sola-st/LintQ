from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
from qiskit import execute, Aer
def get_circuit(n):
    qreg = QuantumRegister(1)
    creg = ClassicalRegister(n)
    circ = QuantumCircuit(qreg, creg)
    for i in range(n): # BUG
        circ.measure(qreg[0], creg[i]) # BUG
    return circ
aer = Aer.get_backend('qasm_simulator')
qc = get_circuit(4)
counts = execute(qc, aer).result().get_counts()
print(counts)
# {'0000': 1024}