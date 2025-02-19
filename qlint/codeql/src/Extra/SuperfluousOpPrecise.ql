/**
 * @name Superfluous operation (extra precision)
 * @description gates on qubits that are not measured or that do not affect other qubits
 * which are measured.
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision high
 * @id ql-superfluous-op-precise
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.UnknownQuantumOperator
import qiskit.Gate
import qiskit.QuantumDataFlow
import qiskit.Backend

from Gate op, QuantumCircuit qc
where
  // we focus only on Constructors
  qc instanceof QuantumCircuitConstructor and
  // the op should belong to the circuit
  qc = op.getQuantumCircuit() and
  // targetBit = op.getATargetQubit() and
  // there is no measurement on the qubit and there is no measure_all
  not exists(Measurement m, int i |
    m.getQuantumCircuit() = qc and
    i >= 0 and
    m.getATargetQubit() = i
  |
    mayFollow(op, m, op.getLocation().getFile(), i)
  ) and
  // not op.getASuccessorOperator*() instanceof Measurement and
  // the circuit is not a subcircuit (usually without measurement)
  not qc.isSubCircuit() and
  // the cicuit is not a parent of a subcircuit
  not exists(SubCircuit sub | sub.getAParentCircuit() = qc) and
  // there are no unresolved operations
  not exists(UnknownQuantumOperator unkOp | unkOp.getQuantumCircuit() = qc) and
  // the purpose is not graphical
  not exists(DataFlow::CallCfgNode drawCall | qc.getAnAttributeRead("draw").getACall() = drawCall) and
  // the circuit is actually executed in a backend (not a statevector/unitary simulator)
  exists(Backend bkd |
    bkd.getACircuitToBeRun() = qc and
    // the backend is not a simulator
    not bkd.isStatevectorSimulator() and
    not bkd.isUnitarySimulator()
  )
// and
// // it does not act on a qubit that is also manipulated by another gate
// // together with another qubit index which is then measured
// not exists(Gate otherOp, int i, int otherQubit, Measurement m |
//   i >= 0 and otherQubit >= 0 and
//   mayFollow(op, otherOp, op.getLocation().getFile(), i) and
//   mayFollow(otherOp, m, op.getLocation().getFile(), otherQubit)
// )
select op,
  "The circuit '" + qc.getName() + "' has an operation " + "(l:" + op.getLocation().getStartLine() +
    ", c:" + op.getLocation().getStartColumn() + ") " +
    "in which some of its qubits are never measured."
