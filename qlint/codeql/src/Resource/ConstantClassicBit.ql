/**
 * @name Constant Classic Bit
 * @description Finds circuits where qubits are never used but measured, leading to a constant classic bit.
 * @kind problem
 * @tags maintainability
 *       efficiency
 *       qiskit
 * @problem.severity warning
 * @precision medium
 * @id ql-constant-classic-bit
 */

import python
import qiskit.Circuit
import qiskit.Qubit
import qiskit.QuantumDataFlow

// from Gate g
// select g, g.getQuantumCircuit()
// from Measurement meas
// select meas, meas.getQuantumCircuit()"Measurement circuit: " + meas.getQuantumCircuit().getName()
// from QubitUse qbu, QuantumOperator g1, QuantumOperator g2
// where
//   g1 != g2 and
//   g1 = qbu.getAGate() and
//   g2 = qbu.getAGate() and
//   g1.getLocation().getFile() != g2.getLocation().getFile()
// select
//   qbu, g1, g2, g1.getLocation().getFile(), g2.getLocation().getFile()
// from Measurement m, QubitUse bu
// where m = bu.getAGate()
// select m, bu, "Measurement circuit: " + m.getQuantumCircuit().getName() + " (l:" + m.getLocation().getStartLine() + ", c:" + m.getLocation().getStartColumn() + ") measures qubit '" + bu.getAnIndex() + "' - bituse (l:" + bu.getLocation().getStartLine() + ", c:" + bu.getLocation().getStartColumn() + ")"
// from QuantumCircuit circ, Measurement meas, int i, File f
// where
//   i = meas.getATargetQubit() and
//   circ = meas.getQuantumCircuit() and
//   circ.getLocation().getFile() = f and
//   meas.getLocation().getFile() = f and
//   forall(Gate g |
//     circ = g.getQuantumCircuit() and
//     g.getLocation().getFile() = f
//   |
//     forall(int iTargetOfGate | iTargetOfGate = g.getATargetQubit() |iTargetOfGate != i)
//   )
//   //  and
//   // i >= 0
// select meas,
//   "Circuit '" + circ.getName() + "' (l:" + circ.getLocation().getStartLine() + ", c:" + circ.getLocation().getStartColumn() + ") measures qubit '" + i + "'"
from QuantumCircuit circ, Measurement measure, int qubitIndex
where
  // only constructors
  circ instanceof QuantumCircuitConstructor and
  // the circuit has a measurement
  circ = measure.getQuantumCircuit() and
  measure.getATargetQubit() = qubitIndex and
  // there is no gate applied before
  not exists(Gate gate | circ = gate.getQuantumCircuit() |
    mayFollow(gate, measure, circ.getLocation().getFile(), qubitIndex)
  ) and
  // the qubit not undefined
  qubitIndex >= 0 and
  // there are no circuit extender
  not exists(CircuitExtenderFunction circExt | circExt.getExtendedQuantumCircuit() = circ) and
  // they are do not have any subcircuits
  not exists(SubCircuit subCirc | subCirc.getAParentCircuit() = circ)
select circ,
  "Circuit '" + circ.getName() + "' measures qubit '" + qubitIndex + "' but never uses it."
// from QuantumCircuit circ, Measurement meas, QubitUse qbuMeas, int qubitIndex, Measurement measOnDeafultState, QubitUse qbuDefaultState, int qubitIndexDefaultState
// where
//   // the circuit has a measurement
//   circ = meas.getQuantumCircuit() and
//   qbuMeas.getAGate() = meas and
//   qubitIndex = qbuMeas.getAnIndex() and
//   qbuMeas.getLocation().getFile() = circ.getLocation().getFile() and
//   // there is no manipulation on the same bit before that measurement
//   exists(QubitUse qbuOther, Gate other |
//     qbuOther.getAGate() = other and
//     other.getQuantumCircuit() = circ
//   |
//     mayFollow(other, meas, circ.getLocation().getFile(), qubitIndex)
//   ) and
//   // // there is no gate applied before
//   // not exists(Gate gate | gate.getQuantumCircuit() = circ | gate.isAppliedAfterOn(measure, qubitIndex)) and
//   // the qubit not undefined
//   qubitIndex >= 0 and
//   // // we want abother measurement on the same circuit
//   measOnDeafultState != meas and
//   measOnDeafultState = qbuDefaultState.getAGate() and
//   meas.getLocation().getFile() = measOnDeafultState.getLocation().getFile() and
//   qubitIndexDefaultState = qbuDefaultState.getAnIndex()
// select measOnDeafultState, qbuDefaultState,
//   "Circuit '" + circ.getName() + "' (l:" + circ.getLocation().getStartLine() + ", c:" + circ.getLocation().getStartColumn() + ") measures qubit '" + qubitIndexDefaultState + "' but never uses it."
