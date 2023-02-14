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
 * @id QL104-OpAfterMeasurement
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.circuit

from
    Measure measure,
    Gate gate
where
    gate.follows(measure)
    // do not put any other conditions in AND here
    // otherwise the query will become inefficient
    // https://github.com/github/codeql/issues/4909
    // that could be because of the way get_a_target_qubit() works using and OR
select
    gate, "Operation '" + gate.get_gate_name() + "' on qubit " + measure.get_a_target_qubit().toString() + " after measurement " +
    "at location: (" + gate.getLocation().getStartLine() + ", " + gate.getLocation().getStartColumn() + ")."