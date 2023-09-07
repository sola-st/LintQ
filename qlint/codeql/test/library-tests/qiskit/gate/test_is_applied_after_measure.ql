import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate
import qiskit.Qubit

from Measurement measBefore, Gate gateAfter, int shared_qubit
where
  not measBefore.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%") and
  not gateAfter.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%") and
  shared_qubit = measBefore.getATargetQubit() and
  gateAfter.isAppliedAfterOn(measBefore, shared_qubit)
select measBefore, gateAfter,
  "Gate: '" + measBefore.getGateName() + "' on qubit " + shared_qubit + " is followed by gate: '" +
    gateAfter.getGateName() + "'."
