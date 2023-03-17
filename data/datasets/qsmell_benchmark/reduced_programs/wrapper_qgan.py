# ------------------------------------------------------------------------------
# Based on: https://github.com/Qiskit/qiskit-machine-learning/blob/0.4.0/test/algorithms/distribution_learners/qgan/test_qgan.py#L39

from qiskit import BasicAer, QuantumCircuit
from qiskit.circuit.library import RealAmplitudes
from qiskit.utils import algorithm_globals, QuantumInstance
from qiskit.algorithms.optimizers import CG, COBYLA
from qiskit.opflow.gradients import Gradient
from qiskit_machine_learning.algorithms import (
    NumPyDiscriminator,
    PyTorchDiscriminator,
    QGAN,
)
import qiskit_machine_learning.optionals as _optionals

seed = 7
algorithm_globals.random_seed = seed
# Number training data samples
n_v = 5000
# Load data samples from log-normal distribution with mean=1 and standard deviation=1
m_u = 1
sigma = 1
_real_data = algorithm_globals.random.lognormal(mean=m_u, sigma=sigma, size=n_v)
# Set upper and lower data values as list of k
# min/max data values [[min_0,max_0],...,[min_k-1,max_k-1]]
_bounds = [0.0, 3.0]
# Set number of qubits per data dimension as list of k qubit values[#q_0,...,#q_k-1]
num_qubits = [2]
# Batch size
batch_size = 100
# Set number of training epochs
# num_epochs = 10
num_epochs = 5

# Initialize qGAN
qgan = QGAN(
    _real_data,
    _bounds,
    num_qubits,
    batch_size,
    num_epochs,
    snapshot_dir=None,
)
qgan.seed = 7
# Set quantum instance to run the quantum generator
qi_statevector = QuantumInstance(
    backend=BasicAer.get_backend("statevector_simulator"),
    seed_simulator=2,
    seed_transpiler=2,
)
qi_qasm = QuantumInstance(
    backend=BasicAer.get_backend("qasm_simulator"),
    shots=1000,
    seed_simulator=2,
    seed_transpiler=2,
)
# Set entangler map
entangler_map = [[0, 1]]

qc = QuantumCircuit(sum(num_qubits))
qc.h(qc.qubits)

ansatz = RealAmplitudes(sum(num_qubits), reps=1, entanglement=entangler_map)
qc.compose(ansatz, inplace=True)
generator_circuit = qc

# ------------------------------------------------------------------------------
