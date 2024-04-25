/**
 * @name Conditional gate without preceeding measurement.
 * @description when a conditional gate is applied on a qubit, there must be a preceeding measurement on that qubit.
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 *       LintQ
 * @problem.severity warning
 * @precision high
 * @id ql-conditional-without-measurement
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate
import qiskit.QuantumDataFlow

from Gate conditionedGate, int sharedQubit
where
  // ensure the gate is conditional
  conditionedGate.isConditional() and
  // it acts on a qubit
  conditionedGate.getATargetQubit() = sharedQubit and
  // all the measruement are found after this gate
  forall(Measurement followingMeasurement |
    followingMeasurement.getQuantumCircuit() = conditionedGate.getQuantumCircuit()
  |
    conditionedGate.getNode().strictlyReaches(followingMeasurement.getNode()) and
    not followingMeasurement.getNode().strictlyReaches(conditionedGate.getNode())
  ) and
  // EXTRA PRECISION - 11:55 - 14.09.23
  sharedQubit >= 0 and
  // not on subcricuits
  not conditionedGate.getQuantumCircuit().isSubCircuit() and
  // no parent of subcircuits
  not exists(SubCircuit sub | sub.getAParentCircuit() = conditionedGate.getQuantumCircuit())
select conditionedGate,
  "Conditional gate '" + conditionedGate.getGateName() + "' on qubit '" + sharedQubit + "' (l: " +
    conditionedGate.getLocation().getStartLine() + ", c: " +
    conditionedGate.getLocation().getStartColumn() + ") without preceeding measurement."
