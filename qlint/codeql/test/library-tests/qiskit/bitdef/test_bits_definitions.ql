import python
import qiskit.BitDef

from BitDefinition bitDef
where not bitDef.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%")
select bitDef,
  "generic bit (type: " + bitDef.getTypeName() + ") " + "in reg: '" + bitDef.getARegisterName() +
    "'," + " index: '" + bitDef.getAnIndex() + "', " + " circuit: '" + bitDef.getACircuitName() +
    "'"
