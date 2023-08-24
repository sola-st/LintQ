import python
import qiskit.BitUse
import qiskit.Circuit

from BitUse bu
where not bu.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%")
select bu, bu.getAGate(),
  "bit use : circuit: " + bu.getACircuitName() + " - reg: " + bu.getARegisterName() + " - index: " +
    bu.getAnIndex() + " - gate: " + bu.getAGateName()
