/**
 * @name Superfluous operation.
 * @description gates on qubits that are not measured or that do not affect other qubits
 * which are measured.
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision high
 * @id ql-superfluous-op
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.UnknownQuantumOperator
import qiskit.Gate
import qiskit.QuantumDataFlow

from Gate op, QuantumCircuit qc
where
  // targetBit = op.getATargetQubit() and
  // there is no measurement on the qubit and there is no measure_all
  not exists(Measurement m, int i |
    m.getQuantumCircuit() = op.getQuantumCircuit() and
    i >= 0
  |
    mayFollow(op, m, op.getLocation().getFile(), i)
  ) and
  // not op.getASuccessorOperator*() instanceof Measurement and
  // the circuit is not a subcircuit (usually without measurement)
  qc = op.getQuantumCircuit() and
  not qc.isSubCircuit() and
  // there are no unresolved operations
  not exists(UnknownQuantumOperator unkOp | unkOp.getQuantumCircuit() = qc)
// not undefined bit
// targetBit >= 0
select op,
  "The circuit '" + qc.getName() + "' has an operation " + "(l:" + op.getLocation().getStartLine() +
    ", c:" + op.getLocation().getStartColumn() + ") " +
    "in which some of its qubits are never measured."
