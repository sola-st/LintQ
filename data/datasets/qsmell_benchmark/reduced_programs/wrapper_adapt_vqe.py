# ------------------------------------------------------------------------------
# Based on: https://github.com/Qiskit/qiskit-nature/blob/0.4.3/test/algorithms/ground_state_solvers/test_adapt_vqe.py#L60

import numpy as np

from qiskit.providers.basicaer import BasicAer
from qiskit.utils import QuantumInstance
from qiskit.algorithms import VQE
from qiskit.algorithms.optimizers import L_BFGS_B
from qiskit.opflow.gradients import Gradient, NaturalGradient
from qiskit.test import slow_test

from qiskit_nature import QiskitNatureError
from qiskit_nature.algorithms import AdaptVQE, VQEUCCFactory
from qiskit_nature.circuit.library import HartreeFock, UCC
from qiskit_nature.drivers import UnitsType
from qiskit_nature.drivers.second_quantization import PySCFDriver
from qiskit_nature.mappers.second_quantization import ParityMapper
from qiskit_nature.converters.second_quantization import QubitConverter
from qiskit_nature.problems.second_quantization import ElectronicStructureProblem
from qiskit_nature.properties.second_quantization.electronic import (
    ElectronicEnergy,
    ParticleNumber,
)
from qiskit_nature.transformers.second_quantization.electronic import ActiveSpaceTransformer
from qiskit_nature.properties.second_quantization.electronic.bases import ElectronicBasis
from qiskit_nature.properties.second_quantization.electronic.integrals import (
    OneBodyElectronicIntegrals,
    TwoBodyElectronicIntegrals,
)
import qiskit_nature.optionals as _optionals

driver = PySCFDriver(
    atom="H .0 .0 .0; H .0 .0 0.735", unit=UnitsType.ANGSTROM, basis="sto3g"
)

problem = ElectronicStructureProblem(driver)

expected = -1.85727503

qubit_converter = QubitConverter(ParityMapper())

# Based on: https://github.com/Qiskit/qiskit-nature/blob/0.4.3/test/algorithms/ground_state_solvers/test_adapt_vqe.py#L73

solver = VQEUCCFactory(
    quantum_instance=QuantumInstance(BasicAer.get_backend("statevector_simulator"))
)
calc = AdaptVQE(qubit_converter, solver)
calc.solve(problem)

# ------------------------------------------------------------------------------

qc = calc._ansatz
