 /**
 * @name Operations after optimization.
 * @description Finds any operation (gate or measurement) is applied to a transpiled
 * circuit has some.
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision medium
 * @id QL105-OpAfterOptimization
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.circuit

from
    DataFlow::CallCfgNode transpile,
    QuantumCircuit circ,
    QuantumCircuit transpiledCirc,
    //Assign assign,
    GenericGate gate
where
    transpile = API::moduleImport("qiskit").getMember("transpile").getACall() and
    circ = transpile.getArg(0).getALocalSource().(QuantumCircuit) and
    // check if the transpiled circuit is the target variable of the transpile call
    //transpiledCirc = transpile.getArgByName("circuits").getALocalSource().(QuantumCircuit) and
    //assign.getATarget() = transpiledCirc.asExpr() and
    //assign.getValue() = transpile.asExpr() and
    //transpiledCirc.flowsTo(gate) and
    transpiledCirc.getScope() = gate.getScope() and
    transpile.getScope() = gate.getScope() and
    gate = transpiledCirc.get_a_generic_gate() and
    transpiledCirc = gate.get_quantum_circuit()
    // the gate comes at a later line than the transpile call
    //gate.getLocation().getStartLine() > transpile.getLocation().getStartLine()
select
    transpile, gate, "Gates applied to already optimized circuit " + transpiledCirc.toString() + "."