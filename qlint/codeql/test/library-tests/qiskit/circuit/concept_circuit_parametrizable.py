from qiskit.circuit import QuantumCircuit, Parameter
from qiskit.circuit.library import EfficientSU2
from qiskit.circuit.library import TwoLocal
from qiskit.circuit.library import RealAmplitudes


# using at least one parameter makes the circuit parametrizable
phi = Parameter('phi')
qc = QuantumCircuit(1)
qc.rx(phi, 0)
qc.measure_all()


# in case, the circuit comes from an unknown api call, but is uses
# assign parameters, it is parametrizable

def unknown_api_call():
    # this is an unknown api call
    # it could be anything, in this case there are no param
    qc = QuantumCircuit(2)
    theta = Parameter('theta')
    qc.crz(theta, 0, 1)
    qc.measure_all()
    return qc


qc = unknown_api_call()
qc_bound = qc.assign_parameters([0.1])

# in case, qiskit ansatz are used: e.g. qiskit.circuit.library.EfficientSU2
# the circuit is parametrizable
qc_su2 = EfficientSU2(3, reps=2)
qc_su2.measure_all()

qc_real = RealAmplitudes(3, reps=2)
qc_real.measure_all()

qc_tl = TwoLocal(3, ['h', 'rx'], 'cz', reps=2)
qc_tl.measure_all()
