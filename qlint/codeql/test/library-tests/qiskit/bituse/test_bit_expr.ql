import python
import qiskit.BitUse
import qiskit.Circuit
import semmle.python.ApiGraphs

from BinaryExpr expr
where expr.getLocation().getFile().getAbsolutePath().matches("%concept_bit_expr.py")
select expr, "Bin expression resolving as: " + resolveBinArithmetic(expr)
