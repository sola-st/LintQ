# ------------------------------------------------------------------------------
# Based on: https://github.com/Qiskit/qiskit-terra/blob/0.21.0/test/python/algorithms/test_shor.py#L31

from qiskit import Aer, ClassicalRegister
from qiskit.utils import QuantumInstance
from qiskit.algorithms import Shor

backend = Aer.get_backend("qasm_simulator")
instance = Shor(quantum_instance=QuantumInstance(backend, shots=1000))

# Based on: 

shor = instance
circuit = shor.construct_circuit(N=15, a=4, measurement=True)

# ------------------------------------------------------------------------------

qc = circuit
