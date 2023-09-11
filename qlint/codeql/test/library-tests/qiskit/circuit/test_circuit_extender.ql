import python
import qiskit.Circuit

from CircuitExtenderFunction func, QuantumCircuit circ
where
  not func.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%") and
  not circ.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%") and
  func.getExtendedQuantumCircuit() = circ

select func, "Call " + func.getCallName() + " in " + func.getLocation().getFile().getAbsolutePath() + " (l:" + func.getLocation().getStartLine() + ", c:" + func.getLocation().getStartColumn() + ") extends the circuit '" + circ.getName() + "' (l:" + circ.getLocation().getStartLine() + ", c:" + circ.getLocation().getStartColumn() + ")"
