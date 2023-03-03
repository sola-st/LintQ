/**
 * @name Incompatible Composition.
 * @description when two circuits are composed, the number of qubits of the
 * sub circuit must be lower thanthe number of qubits of the main circuit,
 * otherwise the composition is not possible. Same for the number of bits.
 * Another option is to specify how the two wires should be connected.
 *
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


from
    QuantumCircuit mother_circuit,
    QuantumCircuit sub_circuit,
    DataFlow::CallCfgNode compose_call
where
    // mother_circuit is the circuit that contains the sub_circuit
    // e.g. mother_circuit.compose(sub_circuit)
    compose_call = mother_circuit.getAnAttributeRead("compose").getACall() and
    sub_circuit.flowsTo(compose_call.getArg(0))
    // check that the sub_circuit has less qubits than the mother_circuit
    and
    sub_circuit.getNumberOfQubits() > mother_circuit.getNumberOfQubits()
select
    compose_call, "The subcircuit '" +sub_circuit.getName() + "' " +
        "has more qubits (" + sub_circuit.getNumberOfQubits() + ") than " +
        "the main circuit '" + mother_circuit.getName() + "' (" +
        mother_circuit.getNumberOfQubits() + ")"