# https://github.com/Z-928/Bugs4Q-Framework/blob/master/qiskit/3/buggy_3.py
from qiskit import QuantumCircuit
import qiskit_experiments
from qiskit_experiments.library import ProcessTomography
from qiskit_experiments.library.tomography.basis.pauli_basis import (
    Pauli6PreparationBasis,
    PauliMeasurementBasis,
    PauliPreparationBasis
)

from qiskit.providers.aer import AerSimulator
from qiskit.test.mock import FakeParis
from qiskit_experiments.framework import ExperimentData

backend = AerSimulator.from_backend(FakeParis())

circ = QuantumCircuit(1,1)
circ.x(0)

tomo = ProcessTomography(
    circuit=circ,
    measurement_basis=PauliMeasurementBasis(),
    measurement_qubits=None,
    preparation_basis=PauliMeasurementBasis(),
    preparation_qubits=None,
    basis_indices=None,
    qubits=None
)

print(f"There are {len(tomo.circuits())} circuits to run")

# This works
experiment = tomo.run(analysis=False, backend=backend).block_for_results()

# This doesn't
experiment = tomo.run(analysis=True, backend=backend).block_for_results()
