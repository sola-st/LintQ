import python
import qiskit.BitDef

from
  ExplicitSingleBitDefinition bitDef
where
  not bitDef.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%")
select
  bitDef, "Generic Bit :'" + bitDef.getName() + "'"