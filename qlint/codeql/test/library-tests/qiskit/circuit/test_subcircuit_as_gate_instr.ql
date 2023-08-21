import python
import qiskit.Circuit

from InstructionCircuit circ
where not circ.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%")
select circ, "Quantum Circuit with to_gate or to_instruction '" + circ.getName()
    + "'"
