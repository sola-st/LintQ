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
select
    gate, "Operation after measurement: " + gate.toString() + " on qubit " + measure.get_a_target_qubit().toString() + "."