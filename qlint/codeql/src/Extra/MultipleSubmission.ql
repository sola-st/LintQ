/**
 * @name Multiple Submission
 * @description Backend is repeatedly called in a loop. Consider submitting parametrized circuits.
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision high
 * @id ql-multiple_submission
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate
import qiskit.QuantumDataFlow
import qiskit.Backend

from BackendRun bkdRun, For loopNode
where loopNode.getAChildNode().contains(bkdRun.getNode().getNode())
select bkdRun, "Backend is repeatedly called in a loop. Consider submitting parametrized circuits."
