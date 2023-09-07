import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate
import qiskit.Qubit

from QuantumOperator opBefore, QuantumOperator opAfter, int shared_qubit
where
  not opBefore.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%") and
  not opAfter.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%") and
  opAfter.isAppliedAfterOn(opBefore.(QuantumOperator), shared_qubit)
select opBefore, opAfter,
  "Op: '" + opBefore.getGateName() + "' on qubit " + shared_qubit + " is followed by op: '" +
  opAfter.getGateName() + "'."
