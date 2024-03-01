"""Measure Out-of-Bound.

Insufficient length of classical registers, a measurement is applied and the
result is stored into a classical register index which is greater than the
max register size.
"""

from qiskit import QuantumCircuit, Aer, execute

qc = QuantumCircuit(20, 20)
qc.h(0)
qc.h(1)

qc.measure([0, 1], [21, 22])  # BUG: out-of-bound measurement
print(qc.draw())

