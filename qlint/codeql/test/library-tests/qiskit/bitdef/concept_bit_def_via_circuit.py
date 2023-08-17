from qiskit.circuit import QuantumCircuit, Parameter
from qiskit.circuit.library import EfficientSU2
from qiskit.circuit.library import TwoLocal
from qiskit.circuit.library import RealAmplitudes

phi = Parameter('phi')
qc = QuantumCircuit(2, 7)
qc.rx(phi, 0)
qc.measure_all()


qc_mostly_quantum = QuantumCircuit(10, 3)
qc_mostly_quantum.h(0)


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


qc_su2 = EfficientSU2(3, reps=2)
qc_su2.measure_all()

qc_real = RealAmplitudes(4, reps=2)
qc_real.measure_all()

qc_tl = TwoLocal(3, ['h', 'rx'], 'cz', reps=2)
qc_tl.measure_all()
