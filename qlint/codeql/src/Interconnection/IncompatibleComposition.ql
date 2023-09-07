/**
 * @name Incompatible Composition.
 * @description when two circuits are composed, the number of qubits of the
 * sub circuit must be lower thanthe number of qubits of the main circuit,
 * otherwise the composition is not possible. Same for the number of bits.
 * Another option is to specify how the two wires should be connected.
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision high
 * @id ql-incompatible-composition
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit

from QuantumCircuit motherCircuit, SubCircuit subCircuit, DataFlow::CallCfgNode compositionCall
where
  // PROBLEMATIC PATTERN
  subCircuit.isSubCircuitOf(motherCircuit) and
  compositionCall = subCircuit.getACompositionCall() and
  // check that the sub_circuit has less qubits than the mother_circuit
  subCircuit.getNumberOfQubits() > motherCircuit.getNumberOfQubits() and
  // INTENDED USAGE PATTERN
  // when the subcircuit has unknown number of qubits, such as when the size is specified
  // by a parameter which is unknon in the current context
  not motherCircuit.hasUnknonNumberOfQubits()
select motherCircuit,
  "The subcircuit '" + subCircuit.getName() + "' (qubits=" +
    subCircuit.getNumberOfQubits() + ") at location: (" + subCircuit.getLocation().getStartLine() + ", " + subCircuit.getLocation().getStartColumn() + ") " +
    " is larger than parent '" + motherCircuit.getName() +
    "' (qubits=" + motherCircuit.getNumberOfQubits() + ") at location: (" + motherCircuit.getLocation().getStartLine() + ", " + motherCircuit.getLocation().getStartColumn() + ")." +
    " The composition at location: (" + compositionCall.getLocation().getStartLine() + ", " + compositionCall.getLocation().getStartColumn() + ") is not possible."
