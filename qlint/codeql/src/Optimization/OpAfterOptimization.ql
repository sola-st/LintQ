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
 * @id ql-op-after-optimization
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate

from TranspiledCircuit transpiledCirc, Gate gate
where gate = transpiledCirc.getAGate() and
    transpiledCirc.getOptimizationLvl() = 3
select
    gate, "Gate " + gate.getGateName() + " applied to transpiled circuit: "
    + transpiledCirc.getName() + "."