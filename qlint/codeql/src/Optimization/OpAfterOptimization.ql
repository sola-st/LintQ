 /**
 * @name Operations after optimization.
 * @description Finds any operation (gate or measurement) is applied to a transpiled
 * circuit has some.
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision medium
 * @id QL105-OpAfterOptimization
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.circuit

from
    TranspiledCircuit transpiledCirc,
    GenericGateNew gate
where
    transpiledCirc.getScope() = gate.getScope() and
    gate = transpiledCirc.get_a_generic_gate()
select
    gate, "Gate " + gate.getGateName() + " applied to transpiled circuit: " + transpiledCirc.get_name() + "."