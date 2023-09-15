/**
 * @name Ungoverned Composition.
 * @description when two circuits are composed the wires of the two circuits
 * are connected in a way that is not specified in code but is left to Qiskit
 * based on its defualt. This can lead to unexpected results.
 * @kind problem
 * @tags maintainability
 *       recommendation
 *       qiskit
 * @problem.severity warning
 * @precision high
 * @id ql-ungoverned-composition
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit

from QuantumCircuit motherCircuit, SubCircuit subCircuit, ComposeCall composeCall
where
  // mother_circuit is the circuit that contains the sub_circuit
  // e.g. mother_circuit.compose(sub_circuit)
  motherCircuit = subCircuit.getAParentCircuit() and
  composeCall = subCircuit.getCompositionCallWith(motherCircuit) and
  // check that the two circuits are compatible in size and not obvious (becasue they have different size)
  motherCircuit.getNumberOfQubits() > subCircuit.getNumberOfQubits() and
  // by a parameter which is unknon in the current context
  not motherCircuit.hasUnknonNumberOfQubits() and
  not subCircuit.hasUnknonNumberOfQubits() and
  // they have both fixed size
  not motherCircuit.hasUnresolvedSizeRegister() and
  not subCircuit.hasUnresolvedSizeRegister() and
  // check that the compose call does not specify the wiring
  composeCall.isWiringUnspecified()
select composeCall,
  "The composition of subcircuit '" + subCircuit.getName() + "' (l: " +
    subCircuit.getLocation().getStartLine() + ", c: " + subCircuit.getLocation().getStartColumn() +
    ") to the '" + motherCircuit.getName() + "' (l: " + motherCircuit.getLocation().getStartLine() +
    ", c: " + motherCircuit.getLocation().getStartColumn() + ") " +
    "has no specified wiring (parameters 'qubits' and 'clbits' of " + "compose() are not used)."
