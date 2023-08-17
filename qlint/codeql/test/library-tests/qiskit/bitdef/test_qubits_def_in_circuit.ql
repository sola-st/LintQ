import python
import qiskit.BitDef

from
  ImplicitCircuitQubitDefinition df
where
  not df.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%")
select
  df, "bit " +
  "in reg: '" + df.getARegisterName() + "'," +
  " index: '" + df.getAnIndex() + "', " +
  " circuit: '" + df.getACircuitName() + "', " +
  " type: '" + df.getTypeName() + "'"
