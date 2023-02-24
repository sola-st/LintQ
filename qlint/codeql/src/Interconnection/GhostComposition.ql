/**
 * @name Ghost Composition.
 * @description when two circuits are composed but the inplace=True is not used
 * and the return value of the compose() method is not store, then the
 * composed circuit is lost.
 *
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision high
 * @id ql-ghost-composition
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
    // check that the compose has no named argument inplace=True
    // e.g. mother_circuit.compose(sub_circuit, inplace=True)
    // or if it exists, that it is False
    and (
            (not exists(compose_call.getArgByName("inplace")))
            or
            (compose_call.getArgByName("inplace").asExpr().(Name).getId() = "False")
    )
    // check that the return value of the compose() method is not stored
    // e.g. composed_circuit = mother_circuit.compose(sub_circuit)
    and not exists(AssignStmt a |
        a.getValue() = compose_call.asExpr()
    )
    // check that it is not used as argument of another method
    // e.g. qiskit.execute(mother_circuit.compose(sub_circuit))
    and not exists(DataFlow::CallCfgNode execute_call |
        execute_call.getArg(_).asExpr() = compose_call.asExpr()
    )

select
    compose_call, "Ghost composition at location: (" +
    compose_call.getLocation().getStartLine() + ", " +
    compose_call.getLocation().getStartColumn() +
         ")"