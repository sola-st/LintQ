from qiskit import QuantumCircuit, transpile
from qiskit.providers.fake_provider import FakeVigo
backend = FakeVigo()
qc = QuantumCircuit(3, 3)
qc.h(0)
qc.cx(0, range(1, 3))
qc.barrier()
qc.measure(range(3), range(3))
qc = transpile(qc, backend)
