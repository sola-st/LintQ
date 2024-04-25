/**
 * @name Oversized circuit.
 * @description Finds circuits instantiated with a larger number of qubits than
 * the actual number of qubits used.
 * @kind problem
 * @tags maintainability
 *       efficiency
 *       qiskit
 *       LintQ
 * @problem.severity warning
 * @precision medium
 * @id ql-oversized-circuit
 */

import python
import qiskit.Circuit
import qiskit.Qubit
import qiskit.UnknownQuantumOperator

// IDEA: if the circuit has subcircuits, we cannot know the real number of ops >> disable
// IDEA: if the circuit has an unknown register size, we cannot know the real number of qubits >> disable
// IDEA: disable on built-in circuits e.g. QFT, Grover, etc. because they already have their set of gates internally.
// IDEA: model and consider append operations with unknown arg as well e.g. qc.append(unknown_object, [qubit1, qubit2, qubit3])
from QuantumCircuit circ, int numQubits
where
  // the circuit has a number of qubits
  numQubits = circ.getNumberOfQubits() and
  numQubits > 0 and
  // there is at least one register of the circuit
  // that has at least one qubit index not used
  not exists(QubitUse bu, int i | i in [0 .. numQubits - 1] |
    bu.getAnAbsoluteIndex() = i and
    bu.getAGate().getQuantumCircuit() = circ
  ) and
  // EXTRA PRECISION
  // we focus only on Constructors
  circ instanceof QuantumCircuitConstructor and
  // ALTERNATIVE
  // // it is not a transpiled circuit
  // not circ instanceof TranspiledCircuit and
  // // the circuit is a subcircuit or parent of a circuit
  // not circ instanceof SubCircuit and
  // the cicuit is not a parent of a subcircuit
  not exists(SubCircuit sub | sub.getAParentCircuit() = circ) and
  // there is no initialize op, because it can potentially touch all the qubits
  not exists(Initialize init | init.getQuantumCircuit() = circ) and
  // and the circuit has no unknown register size
  not exists(QuantumRegisterV2 reg | reg = circ.getAQuantumRegister() and not reg.hasKnownSize()) and
  // there are no unresolved operations
  not exists(UnknownQuantumOperator unkOp | unkOp.getQuantumCircuit() = circ)
// reg = circ.getAQuantumRegister() and reg.getSize() > 0 |
// exists(int i | i in [0 .. reg.getSize() - 1] |
//     not exists(QubitUsedInteger qubitUsed |
//         qubitUsed.getQuantumRegister() = reg and
//         qubitUsed.getQubitIndex() = i and
//         // which is not a measurement
//         not qubitUsed.getGate() instanceof MeasureGate)
// ))
// // the circuit has no unknown register size
// and not ( exists(QuantumRegister reg |
//         reg = circ.getAQuantumRegister() and not reg.hasIntegerParameter()
//     ))
// // check if the circuit has subcircuits
// and not (exists(QuantumCircuit sub | sub.isSubCircuitOf(circ)))
select circ,
  "Circuit '" + circ.getName() + "' never manipulates some of its " + numQubits + "qubits."
