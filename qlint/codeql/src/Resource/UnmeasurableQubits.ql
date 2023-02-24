/**
 * @name Unmeasurable qubits.
 * @description Finds circuits instantiated with a lower number of classical
 * bits than the number of qubits, meaning that the full quantum state cannot
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
    QuantumCircuit circ
where
    // the number of qubits is larger than the number of classical bits
    circ.get_total_num_qubits() > circ.get_total_num_bits()
    // the circuit is not a subcircuit
    and not circ.is_subcircuit()
select
    circ, "Circuit '" + circ.get_name() + "' has more qubits (" + circ.get_total_num_qubits() + ") than classical  bits (" + circ.get_total_num_bits() + ")"
