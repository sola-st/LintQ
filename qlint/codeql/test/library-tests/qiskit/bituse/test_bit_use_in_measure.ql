import python
import qiskit.BitUse
import qiskit.Circuit

from QubitUse bu
where
  not bu.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%") and
  bu.getAGate() instanceof Measurement
select bu, bu.getAGate(),
  "but use : circuit: " + bu.getACircuitName() + " - reg: " + bu.getARegisterName() + " - index: " +
    bu.getAnIndex() + " - gate: " + bu.getAGateName()
