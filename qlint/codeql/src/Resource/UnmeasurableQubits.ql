/**
 * @name Unmeasurable qubits.
 * @description Finds circuits instantiated with a lower number of classical
 * bits than the number of qubits, meaning that the full quabntum state cannot
 * be measured.
 * @kind problem
 * @tags maintainability
 *       efficiency
 *       qiskit
 * @problem.severity warning
 * @precision medium
 * @id QL101-UnmeasurableQubits
 */

import python
import qiskit.circuit

from
    QuantumCircuit circ,
    int numQubits,
    int numClbits
where
    // the circuit has a number of qubits
    numQubits = circ.get_total_num_qubits() and
    // the circuit has a number of classical bits
    numClbits = circ.get_total_num_bits() and
    // the number of qubits is larger than the number of classical bits
    numQubits > numClbits
select circ, "we have more qubits (" + numQubits + ") than classical  bits (" + numClbits + ")"
