# ------------------------------------------------------------------------------
# Based on: https://github.com/Qiskit/qiskit-machine-learning/blob/0.4.0/test/algorithms/classifiers/test_qsvc.py#L36

import numpy as np

from qiskit import BasicAer
from qiskit.circuit.library import ZZFeatureMap
from qiskit.utils import QuantumInstance, algorithm_globals
from qiskit_machine_learning.algorithms import QSVC, SerializableModelMixin
from qiskit_machine_learning.kernels import QuantumKernel
from qiskit_machine_learning.exceptions import (
    QiskitMachineLearningError,
    QiskitMachineLearningWarning,
)

algorithm_globals.random_seed = 10598

statevector_simulator = QuantumInstance(
    BasicAer.get_backend("statevector_simulator"),
    shots=1,
    seed_simulator=algorithm_globals.random_seed,
    seed_transpiler=algorithm_globals.random_seed,
)

feature_map = ZZFeatureMap(feature_dimension=2, reps=2)

sample_train = np.asarray(
    [
        [3.07876080, 1.75929189],
        [6.03185789, 5.27787566],
        [6.22035345, 2.70176968],
        [0.18849556, 2.82743339],
    ]
)
label_train = np.asarray([0, 0, 1, 1])

sample_test = np.asarray([[2.199114860, 5.15221195], [0.50265482, 0.06283185]])
label_test = np.asarray([0, 1])

# Based on: https://github.com/Qiskit/qiskit-machine-learning/blob/0.4.0/test/algorithms/classifiers/test_qsvc.py#L63

qkernel = QuantumKernel(
    feature_map=feature_map, quantum_instance=statevector_simulator
)

qsvc = QSVC(quantum_kernel=qkernel)
qsvc.fit(sample_train, label_train)
score = qsvc.score(sample_test, label_test)

# ------------------------------------------------------------------------------

qc = qsvc.quantum_kernel.feature_map
