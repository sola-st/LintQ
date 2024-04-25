# https://github.com/Z-928/Bugs4Q-Framework/blob/master/qiskit/4/buggy_4.py
from qiskit import *
p = QuantumCircuit(8)
p.x(0)
q = QuantumCircuit(8)
q.x(0)

adder = circuit.library.arithmetic.adders.cdkm_ripple_carry_adder.CDKMRippleCarryAdder(8)
adder.compose(p, [1,2,3,4,5,6,7,8], inplace=True, front=True)
adder.compose(q, [9,10,11,12,13,14,15,16], inplace=True, front=True)

backend = Aer.get_backend('statevector_simulator')
job = backend.run(adder)
