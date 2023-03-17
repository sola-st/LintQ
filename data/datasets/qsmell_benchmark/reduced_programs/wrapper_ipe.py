# ------------------------------------------------------------------------------
# Based on: https://github.com/Qiskit/qiskit-terra/blob/0.21.0/test/python/algorithms/test_phase_estimator.py

import numpy as np
from qiskit.algorithms.phase_estimators import (
    PhaseEstimation,
    HamiltonianPhaseEstimation,
    IterativePhaseEstimation,
)
from qiskit.opflow.evolutions import PauliTrotterEvolution, MatrixEvolution
import qiskit
from qiskit import QuantumCircuit
from qiskit.opflow import H, X, Y, Z, I, StateFn

# Based on https://github.com/Qiskit/qiskit-terra/blob/0.21.0/test/python/algorithms/test_phase_estimator.py#L185

def one_phase(
        self,
        unitary_circuit,
        state_preparation=None,
        backend_type=None,
        phase_estimator=None,
        num_iterations=6,
    ):
        """Run phase estimation with operator, eigenvalue pair `unitary_circuit`,
        `state_preparation`. Return the estimated phase as a value in :math:`[0,1)`.
        """
        if backend_type is None:
            backend_type = "qasm_simulator"
        backend = qiskit.BasicAer.get_backend(backend_type)
        qi = qiskit.utils.QuantumInstance(backend=backend, shots=10000)
        if phase_estimator is None:
            phase_estimator = IterativePhaseEstimation
        if phase_estimator == IterativePhaseEstimation:
            p_est = IterativePhaseEstimation(num_iterations=num_iterations, quantum_instance=qi)
        elif phase_estimator == PhaseEstimation:
            p_est = PhaseEstimation(num_evaluation_qubits=6, quantum_instance=qi)
        else:
            raise ValueError("Unrecognized phase_estimator")
        result = p_est.estimate(unitary=unitary_circuit, state_preparation=state_preparation)
        phase = result.phase
        return 

# https://github.com/Qiskit/qiskit-terra/blob/0.21.0/test/python/algorithms/test_phase_estimator.py#L221

state_preparation=X.to_circuit()
expected_phase=0.5
backend_type="statevector_simulator"
phase_estimator=IterativePhaseEstimation

unitary_circuit = Z.to_circuit()
phase = one_phase(
    unitary_circuit,
    state_preparation,
    backend_type=backend_type,
    phase_estimator=phase_estimator,
)

# ------------------------------------------------------------------------------

qc = unitary_circuit
