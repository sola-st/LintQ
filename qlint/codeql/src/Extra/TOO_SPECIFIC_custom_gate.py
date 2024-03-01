"""Use of Customized Gates.

Any customized gate is decomposable into built-in operators of the framework.
This decomposition requires a substantial higher number of operators when
compared to the equivalent solution made exclusively of built-in operators.
"""

##Import necessary modules
from qiskit import IBMQ, QuantumCircuit, ClassicalRegister, QuantumRegister
from qiskit import execute, Aer
from qiskit.qasm import pi
from qiskit.circuit import Gate
from qiskit.tools.visualization import plot_histogram, circuit_drawer
import numpy as np

provider = IBMQ.load_account()

provider.backends()

circ = QuantumCircuit(1, 1)
custom_gate = Gate('my_custom_gate', 1, [3.14, 1])
# 3.14 is an arbitrary parameter for demonstration
circ.append(custom_gate, [0])
circ.measure(0, 0)

from qiskit.providers.ibmq import least_busy
backend_lb = least_busy(provider.backends(simulator=False, operational=True))
print("Least busy backend: ", backend_lb)

#Execute quantum circuit qc 4096 times with the specified backend (backend_sim).
result = execute(circ, backend_lb, shots=4096).result()

#Output the results.
print(result.get_counts(circ))

#Draw a histogram of the results.
plot_histogram(result.get_counts(circ))