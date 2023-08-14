import python
import qiskit.Circuit

from QuantumCircuit circ
where not circ.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%")
select circ, "Quantum Circuit '" + circ.getName()
    + "' with " +
    circ.getNumberOfClassicalBits() + " bits and " +
    circ.getNumberOfQubits() + " qubits"
