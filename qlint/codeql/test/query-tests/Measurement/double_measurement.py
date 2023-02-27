from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister

# function + two measurement created in a for loop


def get_circuit(n):
    qreg = QuantumRegister(1)
    creg = ClassicalRegister(n)
    circ = QuantumCircuit(qreg, creg)
    for i in range(n):
        circ.measure(qreg[0], creg[i])  # BUG
    return circ

# sequential double measurement - register index


qreg = QuantumRegister(3)
creg = ClassicalRegister(3)
circuit = QuantumCircuit(qreg, creg)
circuit.h(0)
circuit.cx(0, 1)
circuit.cx(1, 2)
circuit.measure(qreg[0], creg[0])
circuit.measure(qreg[2], creg[2])
circuit.measure(qreg[0], creg[1])  # BUG


# sequential double measurement - integer index
circuit = QuantumCircuit(3, 3)
circuit.h(0)
circuit.cx(0, 1)
circuit.cx(1, 2)
circuit.measure(0, 0)
circuit.measure(2, 2)
circuit.measure(0, 1)  # BUG


# sequential measurements on different qubits
# but the same index happens as qubit index and as bit index
fp_circuit = QuantumCircuit(5, 3)
fp_circuit.h(4)
fp_circuit.measure(1, 0)
fp_circuit.measure(3, 1)  # legit because it measures the qubit 3
fp_circuit.measure(4, 2)


# measurements on different bit (using loop variable)
qc_loop = QuantumCircuit(2, 2)
for i in range(2):
    qc_loop.measure(i, i)  # LEGIT