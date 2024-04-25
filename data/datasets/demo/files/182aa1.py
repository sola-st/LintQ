# https://github.com/Z-928/Bugs4Q-Framework/blob/master/qiskit/20/buggy_20.py
import qiskit as qk
from qiskit import Aer
my_backend = Aer.get_backend("qasm_simulator")
qr = qk.QuantumRegister(2)
cr = qk.ClassicalRegister(2)
qc = qk.QuantumCircuit(qr,cr)
print(qc.h(qr[0]))
measure_Z = qk.QuantumCircuit(qr,cr)
print(measure_Z.measure(qr,cr))
measure_X = qk.QuantumCircuit(qr,cr)
test_Z = qc + measure_Z
test_X = qc + measure_X
job_1 = qk.execute([test_Z,test_X],backend='my_backend',shots=1000)
result_1 = job_1.result()
result_1.get_counts(test_Z)
