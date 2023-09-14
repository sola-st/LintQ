import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.BitUse
import qiskit.QuantumDataFlow
import qiskit.Gate

/** Unknown quantum operator. */
abstract class UnknownQuantumOperator extends DataFlow::CallCfgNode {

  /** Circuit to which unknown quantum operations are applied. */
  abstract QuantumCircuit getQuantumCircuit();

}

class UnknownQuantumOperatorViaUnknownArgument extends UnknownQuantumOperator {
  UnknownQuantumOperatorViaUnknownArgument() {
    this instanceof QuantumOperator and
    // the qubit use associate to this operator is less than the number of qubits arguments,
    // meaning that some bit argument has some "unresolved" qubit use (e.g, qc.measure(0, i))
    exists(OperatorSpecification spec |
      this.(QuantumOperator).getGateName() = spec and
      count(QubitUse qbu | qbu.getAGate() = this) < spec.getNumberOfQubits()

    )
  }

  override QuantumCircuit getQuantumCircuit() {
    result = this.(QuantumOperator).getQuantumCircuit()
  }
}


// QUANTUM CIRCUIT EXTENDER FUNCTIONS
/** A function call that can extend a specific circuit. */
abstract class UnknownQuantumOperatorViaFunction extends DataFlow::CallCfgNode {
  /** Returns the circuit that is extended by the function call. */
  abstract QuantumCircuit getQuantumCircuit();

  /** Return the name of the function call. */
  string getCallName() {
      exists(PythonFunctionValue method, string methodName |
      method.getName() = methodName and
      method.getACall().getNode() = this.asExpr()
      |
      result = methodName
      )
  }
}

/**
 * Circuit extender fuctions via argument.
 *
 * Any function that takes a quantum circuit as argument and possibly manipulates it.
 */
class CircuitExtenderFunctionViaArg extends UnknownQuantumOperatorViaFunction {
  CircuitExtenderFunctionViaArg() {
    exists(
    QuantumCircuit qc, DataFlow::CallCfgNode actualCall, Call callNode,
    PythonFunctionValue method, string methodName
    |
    callNode = actualCall.asExpr() and
    this = actualCall and
    qc.flowsTo(this.getArg(_)) and
    // exclude the well known functions
    // instanceof, type, transpile, assemble, execute, append, compose, copy
    method.getName() = methodName and
    method.getACall().getNode() = this.asExpr() and
    not methodName in [
        "isinstance", "type", "transpile", "assemble", "execute", "append", "compose", "copy"
        ]
    )
  }

  override QuantumCircuit getQuantumCircuit() {
    exists(QuantumCircuit qc | qc.flowsTo(this.getArg(_)) | result = qc)
  }
}

/**
 * Circuit extender via implicit global.
 *
 * Any function that takes no circuit arguments but manipulates a variable that has
 * the same name as a circuit in the same file.
 */
class CircuitExtenderFunctionImplicit extends UnknownQuantumOperatorViaFunction {
  CircuitExtenderFunctionImplicit() {
    exists(
    QuantumCircuit qc, DataFlow::CallCfgNode actualCall, FunctionDef fd,
    Variable inFunctionQcVariable
    |
    // they are in the same file
    qc.getLocation().getFile() = actualCall.getLocation().getFile() and
    // the variable used in the function def
    // and variable used to refer to the circuit
    // point to the same thing (aka: proxy they have the same name)
    inFunctionQcVariable.getId() = qc.getName() and
    // the variable is in the body of the function
    fd.contains(inFunctionQcVariable.getAUse().getNode()) and
    // make sure that there is no store in the function
    not fd.contains(inFunctionQcVariable.getAStore()) and
    // the call is referred to the function def (same name and scope)
    actualCall.getFunction().asExpr().(Name).getId() = fd.getDefinedFunction().getName() and
    actualCall.getScope() = fd.getScope()
    |
    this = actualCall
    )
  }

  override QuantumCircuit getQuantumCircuit() {
    exists(
    QuantumCircuit qc, DataFlow::CallCfgNode actualCall, FunctionDef fd,
    Variable inFunctionQcVariable
    |
    // they are in the same file
    qc.getLocation().getFile() = actualCall.getLocation().getFile() and
    // the variable used in the function def
    // and variable used to refer to the circuit
    // point to the same thing (aka: proxy they have the same name)
    inFunctionQcVariable.getId() = qc.getName() and
    // the variable is in the body of the function
    fd.contains(inFunctionQcVariable.getAUse().getNode()) and
    // make sure that there is no store in the function
    not fd.contains(inFunctionQcVariable.getAStore()) and
    // the call is referred to the function def (same name and scope)
    actualCall.getFunction().asExpr().(Name).getId() = fd.getDefinedFunction().getName() and
    actualCall.getScope() = fd.getScope()
    |
    result = qc
    )
  }
}
