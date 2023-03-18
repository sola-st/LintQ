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


// IMPROVEMENT:
// - check that there is no reset() after the measurement

from
    MeasureGate measure,
    Gate gate,
    int shared_qubit
where
    not gate instanceof MeasureGate and
    gate.isAppliedAfterOn(measure, shared_qubit)
select
    gate, "Operation '" + gate.getGateName() + "' on qubit " + shared_qubit +
    " after measurement at location: (" +
    measure.getLocation().getStartLine() + ", " + measure.getLocation().getStartColumn() + ")."

// from Gate gate
// // where gate.getLocation().getFile().getBaseName() = "op_after_measurement.py"
// where gate.getLocation().getFile().getBaseName() = "gate_addition.py"
// select gate