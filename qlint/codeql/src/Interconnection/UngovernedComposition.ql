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
 * @id ql-ungoverned-composition
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit


// IDEA: disable when the mapping is obvious
// (e.g., the main and sub circuits have the same size)

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
    mother_circuit.getNumberOfQubits() >= sub_circuit.getNumberOfQubits()
    and
    // check that the compose call does not specify the wiring
    not exists(compose_call.(API::CallNode).getParameter(1, "qubits"))
    and
    not exists(compose_call.(API::CallNode).getParameter(2, "clbits"))
select
    compose_call, "The composition of subcircuit '" + sub_circuit.getName() + "' " +
        "to the '" + mother_circuit.getName() + "' " +
        "has no specified wiring (parameters 'qubits' and 'clbits' of " +
        "compose() are not used)."