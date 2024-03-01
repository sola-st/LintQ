"""Superfluous Operations.

A gate that does not get measured and does not influence (happens before)
any other gate.
"""

from qiskit import QuantumCircuit, Aer, compile, execute

qc = QuantumCircuit(4, 3)
qc.h(0)
qc.h(1)  # BUG: This gate is superfluous never measured
qc.cx(0, 2)
qc.h(2)
qc.h(3)
qc.measure([0, 2, 3], [0, 2, 3])

result = execute(qc, Aer.get_backend('qasm_simulator')).result()
counts = result.get_counts(qc)
print(counts)
