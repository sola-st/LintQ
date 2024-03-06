/**
 * @name Number of qubits and bits
 * @description compute the number of qubits and bits used in each cicuit
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity warning
 * @precision low
 * @id ql-qc-size
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate

from QuantumCircuit qc, int nQubits, int nClbits
where
  nClbits = qc.getNumberOfClassicalBits() and
  nQubits = qc.getNumberOfQubits() and
  not qc.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%")
select qc,
  "Circuit '" + qc.getName() + "' has " + nQubits + " qubits and " + nClbits + " classical bits."
