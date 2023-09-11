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
import qiskit.Gate
import qiskit.QuantumDataFlow

from Gate op, int targetBit, QuantumCircuit qc
where
  targetBit = op.getATargetQubit() and
  // there is no measurement on the qubit and there is no measure_all
  not exists(Measurement m | m.getQuantumCircuit() = op.getQuantumCircuit() |
    mayFollow(op, m, op.getLocation().getFile(), targetBit)
  ) and
  // the circuit is not a subcircuit (usually without measurement)
  qc = op.getQuantumCircuit() and
  not qc.isSubCircuit() and
  // there are no circuit extender
  not exists(CircuitExtenderFunction extender | extender.getExtendedQuantumCircuit() = qc) and
  // not undefined bit
  targetBit >= 0
select op, "The qubit '" + targetBit + "' is modified but never measured."
