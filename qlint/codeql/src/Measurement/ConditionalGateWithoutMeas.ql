/**
 * @name Conditional gate without preceeding measurement.
 * @description when a conditional gate is applied on a qubit, there must be a preceeding measurement on that qubit.
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
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
  // no preceeding measurement is found
  not exists(Measurement preceedingMeas |
    mayFollow(preceedingMeas, conditionedGate, conditionedGate.getLocation().getFile(), sharedQubit)
  )
select conditionedGate,
  "Conditional gate '" + conditionedGate.getGateName() + "' on qubit '" + sharedQubit + "' (l: " +
    conditionedGate.getLocation().getStartLine() + ", c: " +
    conditionedGate.getLocation().getStartColumn() + ") without preceeding measurement."
