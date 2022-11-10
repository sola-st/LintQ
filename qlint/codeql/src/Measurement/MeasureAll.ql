/**
 * @description Finds measure_all calls with a classical register initialized.
 * @id QL100
 * @kind problem
 * @severity medium
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
predicate isClassicalRegister(Call classReg) {
    exists(ClassValue cls |
        cls.getName() = "ClassicalRegister" and
        classReg.getFunc().pointsTo(cls)
    )
}
from
    DataFlow::CallCfgNode quantumCirc,
    DataFlow::ExprNode classicalReg,
    DataFlow::ExprNode measureAll
where
    // the object should be a quantum circuit
    quantumCirc = API::moduleImport("qiskit").getMember("QuantumCircuit").getACall() and
    // this object should have an attibute access to measure_all
    measureAll = quantumCirc.getAnAttributeRead("measure_all") and
    // the circuit must have a classical register
    // namely there must be a flow from a classical register to the argument of the
    // quantum circuit constructor
    isClassicalRegister(classicalReg.asExpr()) and
    classicalReg.(DataFlow::LocalSourceNode).flowsTo(quantumCirc.getArg(1))
select
    measureAll, "measure_all used when a classical register is present",
    quantumCirc, "quantum circuit",
    classicalReg, "classical register"