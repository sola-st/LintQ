import python
import qiskit.BitDef

from
  ClbitDefinition clbitDef
where
  not clbitDef.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%")
select
  clbitDef, "clbit " +
  "in reg: '" + clbitDef.getARegisterName() + "'," +
  " index: '" + clbitDef.getAnIndex() + "', " +
  " circuit: '" + clbitDef.getACircuitName() + "'"
