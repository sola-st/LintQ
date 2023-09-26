
from qiskit import QuantumRegister, ClassicalRegister, QuantumCircuit
from qiskit import Aer, execute, transpile
import matplotlib
background_color = matplotlib.colors.rgb2hex((0.95, 0.95, 0.92))

style = {'backgroundcolor': background_color}

# Create a quantum registers and a classical register
qreg = QuantumRegister(4)
creg = ClassicalRegister(3)
# Create a quantum circuit
circ = QuantumCircuit(qreg, creg)
#      ^^^^^^^^^^^^^^^^^^^^^^^^^^
#      Bug 1: Oversized circuit

# Add gates and measurements to the circuit
for i in range(3):
    circ.h(i)
circ.measure(qreg[0], creg[0])
circ.ry(0.9, qreg[0])
#    ^^^^^^^^^^^^^^^^
#    Bug 2: Operation after measurement
circ.measure([0, 1, 2], creg)

# save the drawing of the circuit
circ.draw(output='mpl', filename='motivating_example_circ.png', style=style)

N_SHOTS = 10000
# Execute the circuit on a simulator
backend_sim = Aer.get_backend("qasm_simulator")
results = backend_sim.run(transpile(circ, backend_sim), shots=N_SHOTS).result()

from qiskit.visualization import plot_histogram
plot_histogram(results.get_counts(circ)).savefig('motivating_example_result.png')

# # same circuit without measure
# circ = QuantumCircuit(qreg1, qreg2, creg)
# for i in range(3):
#     circ.h(i)
#     circ.rx(0.5, i)
# circ.ccx(0, 1, 2)
# for i in range(3):
#     circ.ry(0.9, i)
# circ.measure([0, 1, 2], creg) # Execute the circuit on a simulator

# # save the drawing of the circuit
# circ.draw(output='mpl', filename='motivating_example_no_meas_circ.png', style=style)

# backend_sim = Aer.get_backend("qasm_simulator")
# results = backend_sim.run(transpile(circ, backend_sim), shots=N_SHOTS).result()
# from qiskit.visualization import plot_histogram
# plot_histogram(results.get_counts(circ)).savefig('motivating_example_result_no_meas.png')


# circuit without registers
qc_no_reg = QuantumCircuit(4, 3)
qc_no_reg.h(0)
qc_no_reg.h(1)
qc_no_reg.h(2)
qc_no_reg.measure(0, 0)
qc_no_reg.ry(0.9, 0)
qc_no_reg.measure([0, 1, 2], [0, 1, 2])


# circuit with single register
my_reg = QuantumRegister(4)
my_class_reg = ClassicalRegister(3)
qc_single_reg = QuantumCircuit(my_reg, my_class_reg)

qc_single_reg.h(my_reg[0])
qc_single_reg.h(my_reg[1])
qc_single_reg.h(my_reg[2])
qc_single_reg.measure(my_reg[0], my_class_reg[0])
qc_single_reg.ry(0.9, my_reg[0])
qc_single_reg.measure([my_reg[0], my_reg[1], my_reg[2]], [my_class_reg[0], my_class_reg[1], my_class_reg[2]])

# last bit
qc_no_reg = QuantumCircuit(4, 3)
qc_no_reg.h(0)
qc_no_reg.h(1)
qc_no_reg.h(2)
qc_no_reg.measure(2, 2)
qc_no_reg.ry(0.9, 2)
qc_no_reg.measure([0, 1, 2], [0, 1, 2])

