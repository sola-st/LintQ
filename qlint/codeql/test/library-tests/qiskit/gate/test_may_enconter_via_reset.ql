import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate
import qiskit.Qubit
import qiskit.QuantumDataFlow

from QuantumOperator opBefore, QuantumOperator opAfter, Reset resetIntermediate, int sharedQubit
where
  not opBefore.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%") and
  not opAfter.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%") and
  sharedQubit = opBefore.getATargetQubit() and
  sortedInOrder(opBefore, resetIntermediate, opAfter, opBefore.getLocation().getFile(), sharedQubit)
select opBefore, resetIntermediate, opAfter,
  "Gate: '" + opBefore.getGateName() + "' on qubit " + sharedQubit + " is followed by gate: '" +
    resetIntermediate.getGateName() + "' and then by gate: '" + opAfter.getGateName() + "'."
