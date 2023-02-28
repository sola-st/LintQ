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
 * @id QL103-OversizedCircuit
 */

import python
import qiskit.circuit

from
    QuantumCircuit circ,
    int numQubits
where
    // the circuit has a number of qubits
    numQubits = circ.get_total_num_qubits() and
    // there is a qubits in the range of available qubits which is never used
    exists(int i |
        i in [0 .. numQubits - 1] and
        not exists(GenericGateNew g |
            g.getQuantumCircuit() = circ and
            g.getATargetQubit() = i
        )
    )
select
    circ, "Circuit '" + circ.get_name() + "' never manipulates some of its " + numQubits + "qubits."