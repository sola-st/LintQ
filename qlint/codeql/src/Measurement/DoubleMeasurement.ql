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

from
    MeasureGate measureFirst, MeasureGate measureSecond
where
    measureSecond.isAppliedAfter(measureFirst)
select
    measureSecond, "Two consecutive measurements on qubit '" +
        measureFirst.getATargetQubit() + "' " +
    "at locations: (" +
         measureFirst.getLocation().getStartLine() + ", " +
         measureFirst.getLocation().getStartColumn() +
         ") and (" +
         measureSecond.getLocation().getStartLine() + ", " +
         measureSecond.getLocation().getStartColumn() +
    ")"