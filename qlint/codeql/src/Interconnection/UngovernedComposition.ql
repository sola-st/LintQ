/**
 * @name Ungoverned Composition.
 * @description when two circuits are composed the wires of the two circuits
 * are connected in a way that is not specified in code but is left to Qiskit
 * based on its defualt. This can lead to unexpected results.
 *
 * @kind problem
 * @tags maintainability
 *       recommendation
 *       qiskit
 * @problem.severity warning
 * @precision high
 * @id ql-incompatible-composition
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.circuit


from
    QuantumCircuit mother_circuit,
    QuantumCircuit sub_circuit,
    DataFlow::CallCfgNode compose_call
where
    // mother_circuit is the circuit that contains the sub_circuit
    // e.g. mother_circuit.compose(sub_circuit)
    compose_call = mother_circuit.getAnAttributeRead("compose").getACall() and
    sub_circuit.flowsTo(compose_call.getArg(0))
    // check that the two circuits are compatible
    and
    mother_circuit.get_total_num_qubits() >= sub_circuit.get_total_num_qubits()
select
    compose_call, "The composition of subcircuit '" + sub_circuit.get_name() + "' " +
        "to the '" + mother_circuit.get_name() + "' " +
        "has no specified wiring (parameters 'qubits' and 'clbits' of " +
        "compose() are not used)."