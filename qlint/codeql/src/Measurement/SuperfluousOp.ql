/**
 * @name Superfluous operation.
 * @description gates on qubits are not measured or that do not affect other qubits
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

from Gate op, int targetBit, QuantumCircuit qc
where
  // op is not a measruement
  not op instanceof MeasureGate and
  targetBit = op.getATargetQubit() and
  // there is no measurement on the qubit and there is no measure_all
  not exists(MeasureGate m | m.isAppliedAfterOn(op, targetBit)) and
  not exists(MeasurementAll mAll | mAll.getQuantumCircuit() = qc) and
  // the circuit is not a subcircuit (usually without measurement)
  qc = op.getQuantumCircuit() and
  not qc.isSubCircuit()
select op, "The qubit '" + targetBit + "' is modified but never measured."
