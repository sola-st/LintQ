import python
import qiskit.Circuit

from QuantumCircuit circ
where
  not circ.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%")
  and circ instanceof TranspiledCircuit
select circ, "Transpiled Circuit: '" + circ.getName() + "'"
