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
import qiskit.Circuit



from
    QuantumCircuit quantumCirc,
    MeasurementAll measureAllOp
where
    quantumCirc = measureAllOp.getQuantumCircuit() and
    // measureAllOp must not have add_bits parameters set to False
    measureAllOp.hasDefaultArgs() and
    // the circuit must have a classical register
    quantumCirc.getNumberOfClassicalBits() > 0
select
    measureAllOp, "measure_all() on the circuit '" + quantumCirc.getName() +
    "' (at location:" +
        quantumCirc.getLocation().getStartLine() + ", " +
        quantumCirc.getLocation().getStartColumn() + ") " +
    " when it has already " +
        quantumCirc.getNumberOfQubits()
        + " classical bits."