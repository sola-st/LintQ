/**
 * @name Operation after measurement.
 * @description Finds usage of measure of a qubit followed by a gate on the
 * same qubit.
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 *       LintQ
 * @problem.severity warning
 * @precision high
 * @id ql-operation-after-measurement
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate
import qiskit.Qubit
import qiskit.QuantumDataFlow

from Measurement measure, Gate gate, int shared_qubit
where
  mayFollowDirectly(measure, gate, measure.getLocation().getFile(), shared_qubit) and
  not gate.isConditional()
// mayFollow(measure, gate, measure.getLocation().getFile(), shared_qubit)
// and
// forall(Reset reset |
//   measure.getQuantumCircuit() = reset.getQuantumCircuit()
// |
//   not sortedInOrder(measure, reset, gate, measure.getLocation().getFile(), shared_qubit)
// ) and
// shared_qubit >= 0
select gate,
  "Operation '" + gate.getGateName() + "' on qubit " + shared_qubit +
    " after measurement at location: (" + measure.getLocation().getStartLine() + ", " +
    measure.getLocation().getStartColumn() + ")."
