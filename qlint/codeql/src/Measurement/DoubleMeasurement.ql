/**
 * @name Double measurement on the same qubit.
 * @description two consecutive measurements on the same qubit of a given circuit.
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision high
 * @id QL102-DoubleMeasurement
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.circuit

from
    Measure measureFirst, Measure measureSecond
where
    measureSecond.follows(measureFirst)
    // do not put any other conditions in AND here
    // otherwise the query will become inefficient
    // https://github.com/github/codeql/issues/4909
    // that could be because of the way get_a_target_qubit() works using and OR
select
    measureSecond, "Two consecutive measurements on qubit '" +
        measureFirst.get_a_target_qubit() + "' " +
    "at locations: (" +
         measureFirst.getLocation().getStartLine() + ", " +
         measureFirst.getLocation().getStartColumn() +
         ") and (" +
         measureSecond.getLocation().getStartLine() + ", " +
         measureSecond.getLocation().getStartColumn() +
    ")"