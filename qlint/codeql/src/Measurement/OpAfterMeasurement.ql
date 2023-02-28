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
import qiskit.circuit

from
    MeasureGateCall measure,
    GateQuantumOperation gate,
    int shared_qubit
where
    gate.isAppliedAfter(measure) and
    shared_qubit = measure.getATargetQubit() and
    shared_qubit = gate.getATargetQubit()
    // make sure that there is no definition of the circuit on the
    // control flow path between the measurement and the operation
select
    gate, "Operation '" + gate.getGateName() + "' on qubit " + shared_qubit +
    " after measurement at location: (" +
    gate.getLocation().getStartLine() + ", " + gate.getLocation().getStartColumn() + ")."