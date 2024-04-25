# https://github.com/Z-928/Bugs4Q-Framework/blob/master/qiskit/29/buggy_29.py
from qiskit import *
import math
def qft_dagger(circ, q, n):
    """n-qubit inverse QFT on q in circ."""
    for i in range(n-1,-1,-1):
        for m in range(n-i,1,-1):
            circ.cu1(-2*math.pi/2**m, q[i+m-1], q[i])
        circ.h(q[i])
        circ.barrier()
def n_hadamard(circ, q, n):
    "apply n qubits hadamard in circ on q"
    for i in range(n):
        circ.h(q[i])
def build_state_vector(circ, inp, s):
    "build state vector in circ from inp a binary string"
    for i, e in enumerate(inp):
        if e == '1':
            circ.x(s[i])
nancilla = 3
theta = 0.78
q = QuantumRegister(nancilla, 'q')
s = QuantumRegister(1, 's')
c = ClassicalRegister(nancilla, 'c')

qpe = QuantumCircuit(q, s, c)

build_state_vector(qpe, '1', s)

# Applying hadammard on ancilla
n_hadamard(qpe, q, nancilla)

for i in range(nancilla):
    #Applying U^(2^(n-j)) on qubit j 
    qpe.cu1(2*math.pi*theta*2**(nancilla-i-1), q[i], s[0])

# Applying inverse QFT
qft_dagger(qpe, q, nancilla)

for i in range(nancilla):
    qpe.measure(q[i],c[i])

backend = BasicAer.get_backend('qasm_simulator')
shots = 2**17
results = execute(qpe, backend, shots=1000).result()
answer = results.get_counts()   
print(answer)