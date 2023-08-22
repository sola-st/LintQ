import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate
import qiskit.Qubit

from Gate gateBefore, Gate gateAfter, ResetGate gateIntermediateReset, int sharedQubit
where
  not gateBefore.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%") and
  not gateAfter.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%") and
  gateAfter.mayFollowVia(gateBefore, gateIntermediateReset, sharedQubit)
select gateBefore, gateIntermediateReset, gateAfter,
  "Gate: '" + gateBefore.getGateName() + "' on qubit " + sharedQubit + " is followed by gate: '" +
    gateIntermediateReset.getGateName() + "' and then by gate: '" + gateAfter.getGateName() + "'."
