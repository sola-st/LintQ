# ------------------------------------------------------------------------------
# Based on: https://github.com/Qiskit/qiskit-terra/blob/0.21.0/test/python/algorithms/test_vqd.py#L53

import numpy as np

from qiskit import BasicAer, QuantumCircuit
from qiskit.algorithms import VQD, AlgorithmError
from qiskit.algorithms.optimizers import (
    COBYLA,
    L_BFGS_B,
    SLSQP,
)
from qiskit.circuit.library import EfficientSU2, RealAmplitudes, TwoLocal
from qiskit.exceptions import MissingOptionalLibraryError
from qiskit.opflow import (
    AerPauliExpectation,
    I,
    MatrixExpectation,
    MatrixOp,
    PauliExpectation,
    PauliSumOp,
    PrimitiveOp,
    X,
    Z,
)

from qiskit.utils import QuantumInstance, algorithm_globals, has_aer

seed = 50
algorithm_globals.random_seed = seed
h2_op = (
    -1.052373245772859 * (I ^ I)
    + 0.39793742484318045 * (I ^ Z)
    - 0.39793742484318045 * (Z ^ I)
    - 0.01128010425623538 * (Z ^ Z)
    + 0.18093119978423156 * (X ^ X)
)
h2_energy = -1.85727503
h2_energy_excited = [-1.85727503, -1.24458455]

test_op = MatrixOp(np.diagflat([3, 5, -1, 0.8, 0.2, 2, 1, -3])).to_pauli_op()
test_results = [-3, -1]

ryrz_wavefunction = TwoLocal(
    rotation_blocks=["ry", "rz"], entanglement_blocks="cz", reps=1
)
ry_wavefunction = TwoLocal(rotation_blocks="ry", entanglement_blocks="cz")

qasm_simulator = QuantumInstance(
    BasicAer.get_backend("qasm_simulator"),
    shots=2048,
    seed_simulator=seed,
    seed_transpiler=seed,
)
statevector_simulator = QuantumInstance(
    BasicAer.get_backend("statevector_simulator"),
    shots=1,
    seed_simulator=seed,
    seed_transpiler=seed,
)

# Based on: https://github.com/Qiskit/qiskit-terra/blob/0.21.0/test/python/algorithms/test_vqd.py#L139

wavefunction = EfficientSU2(2, reps=1)
vqd = VQD(k=2, ansatz=wavefunction, expectation=MatrixExpectation())
params = [0] * wavefunction.num_parameters
circuits = vqd.construct_circuit(parameter=params, operator=h2_op)

# ------------------------------------------------------------------------------

qc = circuits[0]
