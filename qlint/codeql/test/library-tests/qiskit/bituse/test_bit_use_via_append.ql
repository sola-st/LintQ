import python
import qiskit.BitUse
import qiskit.Circuit

from QubitUseViaAppend bu
where not bu.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%")
select bu,
  "but use : circuit: " + bu.getACircuitName() + " - reg: " + bu.getARegisterName() + " - index: " +
    bu.getAnIndex() + " - gate: " + bu.getAGateName()
