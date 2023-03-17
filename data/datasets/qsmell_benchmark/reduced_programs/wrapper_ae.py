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

# Based on: https://github.com/Qiskit/qiskit-terra/blob/0.21.0/test/python/algorithms/test_amplitude_estimators.py#L173

efficient_circuit = True
prob = 0.5

problem = EstimationProblem(BernoulliStateIn(prob), objective_qubits=[0])
for m in [2, 5]:
    qae = AmplitudeEstimation(m)
    angle = 2 * np.arcsin(np.sqrt(prob))

    # manually set up the inefficient AE circuit
    qr_eval = QuantumRegister(m, "a")
    qr_objective = QuantumRegister(1, "q")
    circuit = QuantumCircuit(qr_eval, qr_objective)

    # initial Hadamard gates
    for i in range(m):
        circuit.h(qr_eval[i])

    # A operator
    circuit.ry(angle, qr_objective)

    if efficient_circuit:
        qae.grover_operator = BernoulliGrover(prob)
        for power in range(m):
            circuit.cry(2 * 2**power * angle, qr_eval[power], qr_objective[0])
    else:
        oracle = QuantumCircuit(1)
        oracle.z(0)

        state_preparation = QuantumCircuit(1)
        state_preparation.ry(angle, 0)
        grover_op = GroverOperator(oracle, state_preparation)
        for power in range(m):
            circuit.compose(
                grover_op.power(2**power).control(),
                qubits=[qr_eval[power], qr_objective[0]],
                inplace=True,
            )

    # fourier transform
    iqft = QFT(m, do_swaps=False).inverse().reverse_bits()
    circuit.append(iqft.to_instruction(), qr_eval)

    actual_circuit = qae.construct_circuit(problem, measurement=True)

# ------------------------------------------------------------------------------

qc = actual_circuit
