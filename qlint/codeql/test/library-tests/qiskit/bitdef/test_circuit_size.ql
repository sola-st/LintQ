import python
import qiskit.BitDef

from QuantumCircuit qc
where not qc.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%")
select qc,
  "number of classical bits " + qc.getNumberOfClassicalBits() + " - number of quantum bits " +
    qc.getNumberOfQubits()
