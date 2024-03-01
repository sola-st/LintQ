from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister

qr = QuantumRegister(2)
cr = ClassicalRegister(2)
qc = QuantumCircuit(qr, cr)
print("This is the initial state")
print(qc.draw(output='mpl'))  # BUG: draw mpl returns an Image
