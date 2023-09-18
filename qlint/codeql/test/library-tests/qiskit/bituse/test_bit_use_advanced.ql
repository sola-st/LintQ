import python
import qiskit.BitUse
import qiskit.Circuit

from QubitUse qbu
where
  qbu.getLocation().getFile().getAbsolutePath().matches("%concept_bit_range.py")
  or
  qbu.getLocation().getFile().getAbsolutePath().matches("%concept_bit_expr.py")
select qbu, qbu.getAnIndex()
