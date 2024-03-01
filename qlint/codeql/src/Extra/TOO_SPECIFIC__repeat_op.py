from qiskit import QuantumCircuit

qc = QuantumCircuit(3, 3)  # 3 Quantum and 3 Classical registers
hadamard = QuantumCircuit(1, name='H')
hadamard.h(0)
measureQubit = QuantumCircuit(1, 1, name='M')
measureQubit.measure(0, 0)
for i in range(3):
    for j in range(3):
        qc.append(hadamard, [j])
    for j in range(3):
        qc.append(measureQubit, [j], [j])
qc.barrier()
# proposed Qsmell fix:
# together with removing the outer loop
# qc = qc.repeat(3)
print(qc.draw())