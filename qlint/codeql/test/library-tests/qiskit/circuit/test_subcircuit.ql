import python
import qiskit.circuit

from QuantumCircuit circ
where
    not circ.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%")
    and circ.is_subcircuit()
select circ, "Sub-circuit detected: '" + circ.get_name() + "'"
