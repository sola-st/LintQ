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
 * @id ql-unmeasurable-qubits
 */

import python
import qiskit.Circuit

from
    QuantumCircuit circ
    // EXTRA IDEA:
    // , MeasureGateCall measure
where
    // the number of qubits is larger than the number of classical bits
    circ.getNumberOfQubits() > circ.getNumberOfClassicalBits()
    // the circuit is not a subcircuit
    and not circ.isSubCircuit()
    // EXTRA IDEA
    // the circuit contains a measurement which has classical argument larger
    // than the size of the circuit
    // and measure.getQuantumCircuit() = circ
    // and measure.getATargetBit() >= circ.get_total_num_bits()
select
    circ, "Circuit '" + circ.getName() + "' has more qubits (" + circ.getNumberOfQubits() + ") than classical  bits (" + circ.getNumberOfClassicalBits() + ")"
