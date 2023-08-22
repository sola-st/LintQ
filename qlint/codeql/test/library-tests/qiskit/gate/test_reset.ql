import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate
import qiskit.Qubit

from ResetGate reset
where
  not reset.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%")
select
  reset, "Reset gate in circuit: '" + reset.getQuantumCircuit().getName() +
  "' on qubit: " + reset.getATargetQubit()