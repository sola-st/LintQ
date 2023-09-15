import python
import qiskit.BitUse
import qiskit.Circuit

from QuantumOperator op, OperatorSpecificationUnitaryGateObj gs
where
  // not op.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%") and
  op.getGateName() = gs
select op
