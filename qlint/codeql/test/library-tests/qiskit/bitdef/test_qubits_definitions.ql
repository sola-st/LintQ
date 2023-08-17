import python
import qiskit.BitDef

from
  QubitDefinition qubitDef
where
  not qubitDef.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%")
select
  qubitDef, "qubit " +
  "in reg: '" + qubitDef.getARegisterName() + "'," +
  " index: '" + qubitDef.getAnIndex() + "', " +
  " circuit: '" + qubitDef.getACircuitName() + "'"
