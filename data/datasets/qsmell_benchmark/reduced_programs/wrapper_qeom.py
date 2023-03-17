# ------------------------------------------------------------------------------
# Based on: https://github.com/Qiskit/qiskit-nature/blob/0.4.3/test/algorithms/excited_state_solvers/test_excited_states_solvers.py#L45

import numpy as np
from qiskit import BasicAer
from qiskit.utils import algorithm_globals, QuantumInstance
from qiskit.algorithms import NumPyMinimumEigensolver, NumPyEigensolver

from qiskit_nature.drivers import UnitsType
from qiskit_nature.drivers.second_quantization import PySCFDriver
from qiskit_nature.mappers.second_quantization import (
    BravyiKitaevMapper,
    JordanWignerMapper,
    ParityMapper,
)
from qiskit_nature.converters.second_quantization import QubitConverter
from qiskit_nature.problems.second_quantization import ElectronicStructureProblem
from qiskit_nature.algorithms import (
    GroundStateEigensolver,
    VQEUCCFactory,
    NumPyEigensolverFactory,
    ExcitedStatesEigensolver,
    QEOM,
)
import qiskit_nature.optionals as _optionals

algorithm_globals.random_seed = 8
driver = PySCFDriver(
    atom="H .0 .0 .0; H .0 .0 0.75",
    unit=UnitsType.ANGSTROM,
    charge=0,
    spin=0,
    basis="sto3g",
)

reference_energies = [
    -1.8427016,
    -1.8427016 + 0.5943372,
    -1.8427016 + 0.95788352,
    -1.8427016 + 1.5969296,
]
qubit_converter = QubitConverter(JordanWignerMapper())
electronic_structure_problem = ElectronicStructureProblem(driver)

solver = NumPyEigensolver()
ref = solver
quantum_instance = QuantumInstance(
    BasicAer.get_backend("statevector_simulator"),
    seed_transpiler=90,
    seed_simulator=12,
)

# Based on: https://github.com/Qiskit/qiskit-nature/blob/0.4.3/test/algorithms/excited_state_solvers/test_excited_states_solvers.py#L73

solver = NumPyMinimumEigensolver()
gsc = GroundStateEigensolver(qubit_converter, solver)
esc = QEOM(gsc, "sd")
results = esc.solve(electronic_structure_problem)

# ------------------------------------------------------------------------------

qc = results._raw_result._ground_state_raw_result._eigenstate.to_circuit_op()._primitive
