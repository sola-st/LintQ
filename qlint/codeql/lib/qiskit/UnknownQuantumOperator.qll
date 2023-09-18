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

/** Append calls that append unknown subcircuit (namely not QuantumOperators). */
class UnknownQuantumOperatorViaAppend extends UnknownQuantumOperator {
  UnknownQuantumOperatorViaAppend() {
    exists(QuantumCircuit qc, DataFlow::CallCfgNode actualCall |
      qc.getAnAttributeRead("append").getACall() = actualCall and
      // there is not known quantum operator (e.g. gate, measure, etc.) as arument
      // e.g. qc.append(unknown_op, [qubit1, qubit2, qubit3])
      not exists(QuantumOperator op |
        op.flowsTo(this.(API::CallNode).getParameter(0, "instruction").asSink())
      )
    |
      this = actualCall
    )
  }

  override QuantumCircuit getQuantumCircuit() {
    exists(QuantumCircuit qc | qc.getAnAttributeRead("append").getACall() = this | result = qc)
  }
}

/** A function call that can extend a specific circuit. */
abstract class UnknownQuantumOperatorViaFunction extends UnknownQuantumOperator {
  /** Return the name of the function call. */
  string getCallName() {
    // exists(PythonFunctionValue method, string methodName |
    //   method.getName() = methodName and
    //   method.getACall().getNode() = this.asExpr()
    // |
    //   result = methodName
    // )
    // or
    // exists(ImportMember importMember, string importMemberName, Call callNode |
    //   importMemberName = importMember.getName() and
    //   callNode = this.asExpr() and
    //   callNode.getASubExpression().(Name).getId() = importMemberName and
    //   callNode.getScope() = importMember.getScope()
    // |
    //   result = importMemberName
    // )
    exists(Value unknVal | unknVal.getACall().getNode() = this.asExpr() |
      result = unknVal.getName()
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
      QuantumCircuit qc, DataFlow::CallCfgNode actualCall, Call callNode, string functionCallName
    |
      callNode = actualCall.asExpr() and
      this = actualCall and
      qc.flowsTo(this.getArg(_)) and
      // exclude the well known functions
      // instanceof, type, transpile, assemble, execute, append, compose, copy
      (
        // case:
        // def my_function(qc):
        //   qc.measure(0, 1)
        // my_function(qc)
        exists(PythonFunctionValue method |
          method.getName() = functionCallName and
          method.getACall().getNode() = this.asExpr()
        )
        or
        // case:
        // from qiskit import my_function
        // my_function(qc)
        exists(ImportMember importMember |
          functionCallName = importMember.getName() and
          callNode.getASubExpression().(Name).getId() = functionCallName and
          callNode.getScope() = importMember.getScope()
        )
      ) and
      not functionCallName in [
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
