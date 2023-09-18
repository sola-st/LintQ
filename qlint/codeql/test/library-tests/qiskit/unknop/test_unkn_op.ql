import python
import qiskit.Circuit
import qiskit.UnknownQuantumOperator

from UnknownQuantumOperator unknOp, QuantumCircuit circ
where
  unknOp.getLocation().getFile().getAbsolutePath().matches("%concept_unknown_op.py") and
  circ.getLocation().getFile().getAbsolutePath().matches("%concept_unknown_op.py") and
  unknOp.getQuantumCircuit() = circ
select unknOp,
  "Unkn. Op '" + unknOp + "' called on circuit " + circ.getName()


// from QuantumOperator op, QuantumCircuit circ, QubitUse qbu
// where
//   op.getLocation().getFile().getAbsolutePath().matches("%concept_unknown_op.py") and
//   circ.getLocation().getFile().getAbsolutePath().matches("%concept_unknown_op.py") and
//   op.getQuantumCircuit() = circ and
//   qbu.getAGate() = op

// select op,
//   "Op '" + op + "' called on circuit " + circ.getName()+ " on qubit " + qbu.getAnAbsoluteIndex()

// from QuantumOperator op
// where
//   op.getLocation().getFile().getAbsolutePath().matches("%concept_unknown_op.py")
// select op,
//   "Op '" + op

// from QubitUse qbu
// where
//   qbu.getLocation().getFile().getAbsolutePath().matches("%concept_unknown_op.py")
// select qbu,
//   "QubitUse '" + qbu + "' called on circuit " + qbu.getAGate().getQuantumCircuit().getName()+ " on qubit " + qbu.getAnAbsoluteIndex()