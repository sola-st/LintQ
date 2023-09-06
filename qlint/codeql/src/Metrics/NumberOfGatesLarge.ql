/**
 * @name Number of gates (really large)
 * @description compute the number of gates for each file
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity warning
 * @precision low
 * @id ql-ngates-large
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate

from File file, int nGates
where
  nGates = count(Gate gate | gate.getLocation().getFile() = file) and
  nGates > 1000
select file, "The number of gates is " + nGates
