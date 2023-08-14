import python
import qiskit.Circuit

from QuantumCircuit circ
where
    not circ.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%")
    and circ.isSubCircuit()
select circ, "Sub-circuit detected: '" + circ.getName() + "'"
