import python
import qiskit.Circuit
import qiskit.UnknownQuantumOperator

from UnknownQuantumOperatorViaFunction func, QuantumCircuit circ
where
  not func.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%") and
  not circ.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%") and
  func.getQuantumCircuit() = circ
select func,
  "Function named '" + func.getCallName() + "' called with circuit " + circ.getName() +
    " as argument"
