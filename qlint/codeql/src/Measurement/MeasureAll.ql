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
 * @id QL100-MeasureAll
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.circuit


from
    QuantumCircuit quantumCirc,
    ClassicalRegister classicalReg,
    MeasureAll measureAllOp
where
    quantumCirc.get_a_generic_gate() = measureAllOp and
    // the circuit must have a classical register
    // namely there must be a flow from a classical register to the argument of the
    // quantum circuit constructor
    classicalReg.(DataFlow::LocalSourceNode).flowsTo(quantumCirc.getArg(1))
select
    measureAllOp, "measure_all used on '" + quantumCirc.get_name() + "' when a classical register is present " +
    "(at location: " + measureAllOp.getLocation().getStartLine() + ", " + measureAllOp.getLocation().getStartColumn() + ")"