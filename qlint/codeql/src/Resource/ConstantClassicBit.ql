/**
 * @name Constant Classic Bit
 * @description Finds circuits where qubits are never used but measured, leading to a constant classic bit.
 * @kind problem
 * @tags maintainability
 *       efficiency
 *       qiskit
 * @problem.severity warning
 * @precision medium
 * @id ql-constant-classic-bit
 */

import python
import qiskit.Circuit
import qiskit.Qubit


from QuantumCircuit circ, MeasureGate measure, int qubitIndex
where
  // the circuit has a measurement
  circ = measure.getQuantumCircuit() and
  measure.getATargetQubit() = qubitIndex and
  // there is no gate applied before
  not exists(Gate gate | gate.isAppliedAfterOn(measure, qubitIndex))
select
  circ, "Circuit '" + circ.getName() + "' measures qubit '" + qubitIndex + "' but never uses it."