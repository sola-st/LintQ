/**
 * @name Oversized circuit.
 * @description Finds circuits instantiated with a larger number of qubits than
 * the actual number of qubits used.
 * @kind problem
 * @tags maintainability
 *       efficiency
 *       qiskit
 * @problem.severity warning
 * @precision medium
 * @id ql-oversized-circuit
 */

import python
import qiskit.Circuit
import qiskit.Qubit


// IDEA: if the circuit has subcircuits, we cannot know the real number of ops >> disable
// IDEA: if the circuit has an unknown register size, we cannot know the real number of qubits >> disable

from SubCircuit circ, int numQubits
where
  // the circuit has a number of qubits
  numQubits = circ.getNumberOfQubits() and
  numQubits > 0 and
  // there is at least one register of the circuit
  // that has at least one qubit index not used
  not exists(QubitUse bu, int i |
    i in [0 .. numQubits - 1]
  |
    bu.getAnIndex() = i and
    bu.getAGate().getQuantumCircuit() = circ
  )


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
select
    circ, "Circuit '" + circ.getName() + "' never manipulates some of its " +
    numQubits + "qubits."