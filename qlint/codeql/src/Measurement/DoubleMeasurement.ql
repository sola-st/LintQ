/**
 * @name Double measurement on the same qubit.
 * @description two consecutive measurements on the same qubit of a given circuit.
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision high
 * @id ql-double-measurement
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate
import qiskit.QuantumDataFlow

from Measurement measureFirst, Measurement measureSecond, int sharedQubit
where
  // measureSecond.isAppliedAfterOn(measureFirst, sharedQubit) and
  mayFollow(measureFirst, measureSecond, measureFirst.getLocation().getFile(), sharedQubit) and
  not exists(Reset res |
    sortedInOrder(measureFirst, res, measureSecond, measureFirst.getLocation().getFile(), sharedQubit))  and
    // measureSecond.mayFollowVia(measureFirst, res, sharedQubit)) and
  sharedQubit >= 0
select measureSecond,
  "Two consecutive measurements on qubit '" + sharedQubit + "' " + "at locations: (" +
    measureFirst.getLocation().getStartLine() + ", " + measureFirst.getLocation().getStartColumn() +
    ") and (" + measureSecond.getLocation().getStartLine() + ", " +
    measureSecond.getLocation().getStartColumn() + ")"
