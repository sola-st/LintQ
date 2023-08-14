import python
import qiskit.Circuit

from QuantumCircuit circ
where
  not circ.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%")
  and circ instanceof BuiltinParametrizedCircuitsConstructor
select circ, "Builtin Parametrized Circuit: '" + circ.getName() + "'"
