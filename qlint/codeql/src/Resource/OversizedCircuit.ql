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

// IDEA: if the circuit has subcircuits, we cannot know the real number of ops >> disable
// IDEA: if the circuit has an unknown register size, we cannot know the real number of qubits >> disable

from
    QuantumCircuit circ,
    int numQubits
where
    // the circuit has a number of qubits
    numQubits = circ.getNumberOfQubits() and
    // there is a qubits in the range of available qubits which is never used
    exists(int i |
        i in [0 .. numQubits - 1] and
        not exists(Gate g |
            g.getQuantumCircuit() = circ and
            g.getATargetQubit() = i
        )
    )
select
    circ, "Circuit '" + circ.getName() + "' never manipulates some of its " + numQubits + "qubits."