# ------------------------------------------------------------------------------
# Based on: https://github.com/Qiskit/qiskit-terra/blob/0.21.0/test/python/algorithms/test_amplitude_estimators.py

import numpy as np
from qiskit import QuantumRegister, QuantumCircuit, BasicAer
from qiskit.circuit.library import QFT, GroverOperator
from qiskit.utils import QuantumInstance
from qiskit.algorithms import (
    AmplitudeEstimation,
    MaximumLikelihoodAmplitudeEstimation,
    IterativeAmplitudeEstimation,
    FasterAmplitudeEstimation,
    EstimationProblem,
)
from qiskit.quantum_info import Operator, Statevector

class BernoulliStateIn(QuantumCircuit):
    """A circuit preparing sqrt(1 - p)|0> + sqrt(p)|1>."""

    def __init__(self, probability):
        super().__init__(1)
        angle = 2 * np.arcsin(np.sqrt(probability))
        self.ry(angle, 0)

class BernoulliGrover(QuantumCircuit):
    """The Grover operator corresponding to the Bernoulli A operator."""

    def __init__(self, probability):
        super().__init__(1, global_phase=np.pi)
        self.angle = 2 * np.arcsin(np.sqrt(probability))
        self.ry(2 * self.angle, 0)

    def power(self, power, matrix_power=False):
        if matrix_power:
            return super().power(power, True)

        powered = QuantumCircuit(1)
        powered.ry(power * 2 * self.angle, 0)
        return 

# Based on: https://github.com/Qiskit/qiskit-terra/blob/0.21.0/test/python/algorithms/test_amplitude_estimators.py#L514

backend_str = "statevector_simulator"
expect = 0.2

def is_good_state(bitstr):
    return bitstr[1] == "1"

# construct the estimation problem where the second qubit is ignored
a_op = QuantumCircuit(2)
a_op.ry(2 * np.arcsin(np.sqrt(0.2)), 0)

# oracle only affects first qubit
oracle = QuantumCircuit(2)
oracle.z(0)

# reflect only on first qubit
q_op = GroverOperator(oracle, a_op, reflection_qubits=[0])

# but we measure both qubits (hence both are objective qubits)
problem = EstimationProblem(
    a_op, objective_qubits=[0, 1], grover_operator=q_op, is_good_state=is_good_state
)

# construct algo
backend = QuantumInstance(
    BasicAer.get_backend(backend_str), seed_simulator=2, seed_transpiler=2
)
# cannot use rescaling with a custom grover operator
fae = FasterAmplitudeEstimation(0.01, 5, rescale=False, quantum_instance=backend)

# ------------------------------------------------------------------------------

qc = fae.construct_circuit(problem, k=5, measurement=True)
