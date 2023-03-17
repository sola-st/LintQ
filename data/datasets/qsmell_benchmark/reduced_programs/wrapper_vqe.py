# ------------------------------------------------------------------------------
# Based on: https://github.com/Qiskit/qiskit-terra/blob/0.21.0/test/python/algorithms/test_vqe.py#L88

import numpy as np
from qiskit import BasicAer, QuantumCircuit
from qiskit.algorithms import VQE, AlgorithmError
from qiskit.algorithms.optimizers import (
    CG,
    COBYLA,
    L_BFGS_B,
    P_BFGS,
    QNSPSA,
    SLSQP,
    SPSA,
    TNC,
)
from qiskit.circuit.library import EfficientSU2, RealAmplitudes, TwoLocal
from qiskit.exceptions import MissingOptionalLibraryError
from qiskit.opflow import (
    AerPauliExpectation,
    Gradient,
    I,
    MatrixExpectation,
    PauliExpectation,
    PauliSumOp,
    PrimitiveOp,
    TwoQubitReduction,
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

ryrz_wavefunction = TwoLocal(rotation_blocks=["ry", "rz"], entanglement_blocks="cz")
ry_wavefunction = TwoLocal(rotation_blocks="ry", entanglement_blocks="cz")

qasm_simulator = QuantumInstance(
    BasicAer.get_backend("qasm_simulator"),
    shots=1024,
    seed_simulator=seed,
    seed_transpiler=seed,
)
statevector_simulator = QuantumInstance(
    BasicAer.get_backend("statevector_simulator"),
    shots=1,
    seed_simulator=seed,
    seed_transpiler=seed,
)

# Based on: https://github.com/Qiskit/qiskit-terra/blob/0.21.0/test/python/algorithms/test_vqe.py#L162

wavefunction = EfficientSU2(2, reps=1)
vqe = VQE(ansatz=wavefunction, expectation=MatrixExpectation())
params = [0] * wavefunction.num_parameters
circuits = vqe.construct_circuit(parameter=params, operator=h2_op)

# ------------------------------------------------------------------------------

qc = circuits[0]
