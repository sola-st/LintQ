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

# Based on: https://github.com/Qiskit/qiskit-terra/blob/0.21.0/test/python/algorithms/test_amplitude_estimators.py#L260

efficient_circuit = True
prob = 0.5
problem = EstimationProblem(BernoulliStateIn(prob), objective_qubits=[0])

for k in [2, 5]:
    qae = MaximumLikelihoodAmplitudeEstimation(k)
    angle = 2 * np.arcsin(np.sqrt(prob))

    # compute all the circuits used for MLAE
    circuits = []

    # 0th power
    q_objective = QuantumRegister(1, "q")
    circuit = QuantumCircuit(q_objective)
    circuit.ry(angle, q_objective)
    circuits += [circuit]

    # powers of 2
    for power in range(k):
        q_objective = QuantumRegister(1, "q")
        circuit = QuantumCircuit(q_objective)

        # A operator
        circuit.ry(angle, q_objective)

        # Q^(2^j) operator
        if efficient_circuit:
            qae.grover_operator = BernoulliGrover(prob)
            circuit.ry(2 * 2**power * angle, q_objective[0])

        else:
            oracle = QuantumCircuit(1)
            oracle.z(0)
            state_preparation = QuantumCircuit(1)
            state_preparation.ry(angle, 0)
            grover_op = GroverOperator(oracle, state_preparation)
            for _ in range(2**power):
                circuit.compose(grover_op, inplace=True)
        circuits += [circuit]

    actual_circuits = qae.construct_circuits(problem, measurement=True)

# ------------------------------------------------------------------------------

qc = actual_circuits[-1]
