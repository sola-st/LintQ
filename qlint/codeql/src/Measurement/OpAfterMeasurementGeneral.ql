/**
 * @name Operation after measurement general.
 * @description Finds usage of measure of a qubit followed by a gate on the
 * same qubit (there could be other gates in between).
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision high
 * @id ql-operation-after-measurement-general
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
  mayFollow(measure, gate, measure.getLocation().getFile(), shared_qubit) and
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
