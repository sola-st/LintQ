import python
import qiskit.circuit

from QuantumCircuit circ
where not circ.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%")
select circ, "Classical register '" + circ.get_name() + "' with " +
    circ.get_total_num_qubits() + " bits and " +
    circ.get_total_num_bits() + " qubits"
