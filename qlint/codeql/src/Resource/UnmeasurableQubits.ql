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

// IDEA: disable if the circuit is draw, since we probably do not care about measurment
// IDEA: disable if the circuit is run on a unitary simulator, since we do not need measurement with that
// IDEA: disable when it is returned by a function, since it might be a sub-part
// IDEA: if the circuit has an unknown register size, we cannot know the real number of qubits >> disable



from
    QuantumCircuit circ
    // EXTRA IDEA:
    // , MeasureGateCall measure
where
    // the number of qubits is larger than the number of classical bits
    circ.getNumberOfQubits() > circ.getNumberOfClassicalBits()
    // the circuit is not a subcircuit
    and not circ.isSubCircuit()
    // the circuit has no unknown register size
    and not (exists(QuantumRegister reg |
            reg = circ.getAQuantumRegister() and
            not reg.hasIntegerParameter()))
    // EXTRA IDEA
    // the circuit contains a measurement which has classical argument larger
    // than the size of the circuit
    // and measure.getQuantumCircuit() = circ
    // and measure.getATargetBit() >= circ.get_total_num_bits()
select
    circ, "Circuit '" + circ.getName() + "' has more qubits (" +
    circ.getNumberOfQubits() + ") than classical  bits (" +
    circ.getNumberOfClassicalBits() + ")"
