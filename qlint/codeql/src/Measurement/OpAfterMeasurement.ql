/**
 * @name Operation after measurement.
 * @description Finds usage of measure of a qubit followed by a gate on the
 * same qubit.
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision high
 * @id ql-operation-after-measurement
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate
import qiskit.Qubit

from MeasureGate measure, Gate gate, int shared_qubit
where
  gate.isUnitary() and
  gate.isAppliedAfterOn(measure, shared_qubit) and
  not exists(ResetGate reset | gate.mayFollowVia(measure, reset, shared_qubit))
select gate,
  "Operation '" + gate.getGateName() + "' on qubit " + shared_qubit +
    " after measurement at location: (" + measure.getLocation().getStartLine() + ", " +
    measure.getLocation().getStartColumn() + ")."
