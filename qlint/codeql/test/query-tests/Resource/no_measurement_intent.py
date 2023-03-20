"""Sometimes the measurement not needed because the intent is different.

- inspect the state vector via the  get_statevector() method
- plot the state vector via the plot_bloch_multivector() method
- print the circuit via the draw() method
- print the unitary via the get_unitary() method
- print the transpiled circuit via print(qc) method

In this case the intent is not to have classical bits and measure in them,
thus it is fine if we do not raise any warning.
"""
from qiskit import QuantumCircuit, assemble, Aer
from qiskit.visualization import plot_histogram, plot_bloch_vector
from math import sqrt, pi


# inspired by 08_8a85ae_6
svsim = Aer.get_backend('statevector_simulator')
qc = QuantumCircuit(1)  # LEGIT: statevector inspection
initial_state = [0, 1]
qc.initialize(initial_state, 0)
qobj = assemble(qc)
result = svsim.run(qobj).result()
out_state = result.get_statevector()


# inspired by 06_061e13_39
q = QuantumRegister(1)  # LEGIT: plotting intent
qc = QuantumCircuit(q)
qc.u2(pi / 2, pi / 2, q)
qc.draw('mpl')
plt.show()
plot_bloch_multivector(qc)
plt.show()
job = execute(qc, backend)
print(job.result().get_unitary(qc, decimals=3))
