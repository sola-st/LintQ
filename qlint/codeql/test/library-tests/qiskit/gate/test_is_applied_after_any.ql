import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate
import qiskit.Qubit

from Gate gateBefore, Gate gateAfter, int shared_qubit
where
  not gateBefore.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%") and
  not gateAfter.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%") and
  gateAfter.isAppliedAfterOn(gateBefore, shared_qubit)
select gateBefore, gateAfter,
  "Gate: '" + gateBefore.getGateName() + "' on qubit " + shared_qubit + " is followed by gate: '" +
    gateAfter.getGateName() + "'."
