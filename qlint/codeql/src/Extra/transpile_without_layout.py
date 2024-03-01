from qiskit import QuantumCircuit, Aer, execute
from qiskit import QuantumCircuit, ClassicalRegister, QuantumRegister
from qiskit import transpile
from qiskit import IBMQ
from qiskit.providers.ibmq import least_busy
from qiskit.tools.monitor import job_monitor


# IBMQ.delete_account()
# IBMQ.save_account('my-token')
IBMQ.load_account()


providers = IBMQ.get_provider()
# Get the least busy backend
backend = least_busy(providers.backends(simulator=False))

# Print the name of the backend
print("Using backend:", backend.name())

qc = QuantumCircuit(3, 3)

qc.h(0)
qc.h(1)
qc.cx(0, 2)
qc.cx(1, 2)
qc.measure_all(add_bits=False)

qc_transpiled = transpile(qc, backend=backend)


# Execute the transpiled circuit
job = execute(qc_transpiled, backend=backend)
job_monitor(job)

# Get the result
result = job.result()

# Print the result

print(result.get_counts(qc_transpiled))