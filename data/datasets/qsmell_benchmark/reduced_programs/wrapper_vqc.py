# ------------------------------------------------------------------------------
# Based on: https://github.com/Qiskit/qiskit-machine-learning/blob/0.4.0/test/algorithms/classifiers/test_vqc.py#L36

import numpy as np
import scipy
from ddt import ddt, data
from qiskit import Aer
from qiskit.algorithms.optimizers import COBYLA, L_BFGS_B
from qiskit.circuit.library import RealAmplitudes, ZZFeatureMap
from qiskit.utils import QuantumInstance, algorithm_globals

from qiskit_machine_learning.algorithms import VQC

num_classes_by_batch = []

# specify quantum instances
algorithm_globals.random_seed = 12345
sv_quantum_instance = QuantumInstance(
    Aer.get_backend("aer_simulator_statevector"),
    seed_simulator=algorithm_globals.random_seed,
    seed_transpiler=algorithm_globals.random_seed,
)
qasm_quantum_instance = QuantumInstance(
    Aer.get_backend("aer_simulator"),
    shots=100,
    seed_simulator=algorithm_globals.random_seed,
    seed_transpiler=algorithm_globals.random_seed,
)

# Based on: https://github.com/Qiskit/qiskit-machine-learning/blob/0.4.0/test/algorithms/classifiers/test_vqc.py#L64

opt, q_i = ("cobyla", "statevector")

if q_i == "statevector":
    quantum_instance = sv_quantum_instance
elif q_i == "qasm":
    quantum_instance = qasm_quantum_instance
else:
    quantum_instance = None

if opt == "bfgs":
    optimizer = L_BFGS_B(maxiter=5)
elif opt == "cobyla":
    optimizer = COBYLA(maxiter=25)
else:
    optimizer = None

num_inputs = 2
feature_map = ZZFeatureMap(num_inputs)
ansatz = RealAmplitudes(num_inputs, reps=1)
# fix the initial point
initial_point = np.array([0.5] * ansatz.num_parameters)

# construct classifier - note: CrossEntropy requires eval_probabilities=True!
classifier = VQC(
    feature_map=feature_map,
    ansatz=ansatz,
    optimizer=optimizer,
    quantum_instance=quantum_instance,
    initial_point=initial_point,
)

# construct data
num_samples = 5
# pylint: disable=invalid-name
X = algorithm_globals.random.random((num_samples, num_inputs))
y = 1.0 * (np.sum(X, axis=1) <= 1)
while len(np.unique(y)) == 1:
    X = algorithm_globals.random.random((num_samples, num_inputs))
    y = 1.0 * (np.sum(X, axis=1) <= 1)
y = np.array([y, 1 - y]).transpose()  # VQC requires one-hot encoded input

# fit to data
classifier.fit(X, y)

# score
score = classifier.score(X, y)

# ------------------------------------------------------------------------------

qc = classifier._circuit
