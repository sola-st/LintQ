from qiskit import QuantumCircuit, Aer, execute
from qiskit import QuantumCircuit, ClassicalRegister, QuantumRegister
from qiskit import transpile
from qiskit import IBMQ
from qiskit.providers.ibmq import least_busy
from qiskit.tools.monitor import job_monitor


IBMQ.delete_account()
IBMQ.save_account('my-token')
IBMQ.load_account()