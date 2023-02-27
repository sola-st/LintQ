from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
from qiskit import execute, Aer

# classical register passed as argument in the object form
q = QuantumRegister(2)
c = ClassicalRegister(2)
qc = QuantumCircuit(q, c)
qc.h(q[0])
qc.cx(q[0], q[1])
qc.measure_all()  # BUG

# the classical circuit is shown with a singled
qc_init_w_int = QuantumCircuit(2, 2)
qc_init_w_int.h(0)
qc_init_w_int.cx(0, 1)
qc_init_w_int.measure_all()  # BUG

# presence of the add_bits=False
qc_no_add_bits = QuantumCircuit(2, 2)
qc_no_add_bits.h(0)
qc_no_add_bits.cx(0, 1)
qc_no_add_bits.measure_all(add_bits=False)  # LEGIT

# presence of the add_bits=True
qc_add_bits = QuantumCircuit(2, 2)
qc_add_bits.h(0)
qc_add_bits.cx(0, 1)
qc_add_bits.measure_all(add_bits=True)  # BUG
