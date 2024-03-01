from qiskit import QuantumCircuit, Aer, execute

circuits = QuantumCircuit(3, 3)
circuits.h(0)
circuits.h(1)
circuits.cx(0, 2)
circuits.measure([0, 1, 2], [2, 1, 0])

shots = 1024
job = execute(
    circuits,
    backend=Aer.get_backend('qasm_simulator'),
    shots=shots,
    seed=8)  # BUG: seed is not supported
result = job.result()
counts = result.get_counts(circuits)
print(counts)
