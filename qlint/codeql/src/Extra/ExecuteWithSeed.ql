/**
 * @name Execute with Seed
 * @description execute API is called with a seed parameter that is ignored.
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision high
 * @id ql-execute-with-seed
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate
import qiskit.QuantumDataFlow
import qiskit.Backend

from ExecuteCall exec, AstNode seedNode
where exec.getArgByName("seed").asExpr() = seedNode
select exec, "The execute API is called with a seed parameter that is ignored."
