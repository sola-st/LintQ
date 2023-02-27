 /**
 * @name Measure all abuse.
 * @description Finds usage of measure_all calls when an initialized classical
 * register should be used instead.
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision high
 * @id ql-measure-all-abuse
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.circuit


from
    QuantumCircuit quantumCirc,
    MeasureAll measureAllOp
where
    quantumCirc.get_a_generic_gate() = measureAllOp and
    // measureAllOp must not have add_bits parameters set to False
    not (
        measureAllOp.(API::CallNode).getParameter(
            1, "add_bits").getAValueReachingSink().asExpr().(
                ImmutableLiteral).booleanValue() = false
                ) and
    // the circuit must have a classical register
    quantumCirc.get_total_num_bits() > 0
select
    measureAllOp, "measure_all() on the circuit '" + quantumCirc.get_name() +
    "' (at location:" +
        quantumCirc.getLocation().getStartLine() + ", " +
        quantumCirc.getLocation().getStartColumn() + ") " +
    " when it has already " +
        quantumCirc.get_total_num_bits()
        + " classical bits."