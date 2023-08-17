
import python
import qiskit.Circuit
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
// import Variables.Definition
import semmle.python.dataflow.new.TaintTracking

abstract class Register extends DataFlow::CallCfgNode {


    // the register object can be accessed by the name of the variable
    // and an index. For example: reg[0] or reg[x]
    // we want to a general node representing one of this accesses
    int getSize() {
        exists(IntegerLiteral size, DataFlow::LocalSourceNode source
            |
            source.flowsTo(this.getArg(0)) and
            source.asExpr() = size
            |
            result = size.getValue()
        )
    }

    // TODO rename hasKnownSize
    //* Holds if the circuit has integer parameter. */
    predicate hasIntegerParameter() {
        exists(DataFlow::LocalSourceNode source
            |
            source.flowsTo(this.getArg(0))
            |
            source.asExpr() instanceof IntegerLiteral
        )
    }

    int getAnAccessedPosition() {
        exists(
            DataFlow::Node nd,
            DataFlow::ExprNode targetSubscript,
            Subscript subscript,
            IntegerLiteral position |
            this.flowsTo(nd) and
            nd.asExpr() = targetSubscript.asExpr() and
            targetSubscript.asExpr() = subscript.getObject() and
            position = subscript.getIndex() |
            result = position.getValue()
        )
    }


    Variable getVar() {
        // get the left side of the assignment
        // e.g. reg = QuantumRegister(2)
        // reg is the name of the register
        exists(
            Variable var,
            AssignStmt assignStmt
            // ,
            // Scope same_scope
            |
            //var.getAStore() = this.asExpr()
            //and
            assignStmt.getValue() = this.asExpr()
            // and this.getScope() = same_scope
            // and var.getScope() = same_scope
            // and assignStmt.getScope() = same_scope
            and assignStmt.getATarget() = var.getAStore()
            |
            // return the left side of the assignment, namely the reference
            // to the NameNode
            result = var
        )

    }


    // /** Gets a index/position available in this register as int.*/
    // int getAQubitIndex() {
    //     exists(
    //         int i
    //         |
    //         i = [0 .. this.getSize() - 1]
    //         |
    //         result = i
    //     )
    // }

}


class ClassicalRegister extends Register {
    ClassicalRegister() {
        this = API::moduleImport("qiskit").getMember("ClassicalRegister").getACall()
    }
}

class QuantumRegister extends Register {
    QuantumRegister() {
        this = API::moduleImport("qiskit").getMember("QuantumRegister").getACall()
    }


    // Expr getName() {
    //     // get the left side of the assignment
    //     // e.g. reg = QuantumRegister(2)
    //     // reg is the name of the register
    //     exists(
    //         AssignStmt assignStmt
    //         |
    //         assignStmt.getValue() = this.asExpr()
    //         |
    //         // return the left side of the assignment, namely the reference
    //         // to the NameNode
    //         result = assignStmt.getATarget()
    //     )

    // }






}



// REGISTER

/** QuantumRegister and ClassicalRegister calls. */
abstract class RegisterV2 extends DataFlow::CallCfgNode {

    /** Returns the size of the register. */
    int getSize() {
      // register = QuantumRegister(size=2)
      // >> 2
      result = this.( API::CallNode ).getParameter(0, "size")
            .getAValueReachingSink().asExpr().(IntegerLiteral).getValue()
    }

    /** Returns true if the size of the register is known. */
    boolean hasKnownSize() {
      // register = QuantumRegister(size=2)
      // >> true
      // x = external_call()
      // register = QuantumRegister(size=x)
      // >> false
      if
        exists(int size | this.getSize() = size)
      then
        result = true
      else
        result = false
    }

    /** Returns the name of the identifier of the register. */
    string getName() {
      exists(AssignStmt a |
        a.contains(this.getNode().getNode()) and
        result = a.getATarget().(Name).getId()
      )
    }

    /** Returns the identifier of the register. */
    Variable getVar() {
      // get the left side of the assignment
      // reg = QuantumRegister(2)
      // >> reg
      exists(Variable var, AssignStmt assignStmt |
        assignStmt.getValue() = this.asExpr()
        and assignStmt.getATarget() = var.getAStore()
        |
        result = var
      )
    }

    /** Returns the circuit in which the register is added. */
    QuantumCircuit getACircuit() {
      // reg = QuantumRegister(2)
      // qc.add_register(reg)
      // >> qc
      // qc2 = QuantumCircuit(reg)
      // >> qc2
      exists(QuantumCircuit qc, int i |
        this.flowsTo(qc.getArg(i))
      |
        result = qc
      ) or
      // there is a this.add_register() call
      exists(QuantumCircuit qc, DataFlow::CallCfgNode addRegisterCall |
        addRegisterCall = qc.getAnAttributeRead("add_register").getACall() and
        this.flowsTo(addRegisterCall.getArg(0))
      |
        result = qc
      )
    }

  }


  /** Qubits generated by QuantumRegister(). */
  class QuantumRegisterV2 extends RegisterV2 {
    QuantumRegisterV2() {
      this = API::moduleImport("qiskit").getMember("QuantumRegister").getACall()
      or
      this = API::moduleImport("qiskit").getMember("circuit").getMember("QuantumRegister").getACall()
    }
  }

  /** Clbits generated by ClassicalRegister(). */
  class ClassicalRegisterV2 extends RegisterV2 {
    ClassicalRegisterV2() {
      this = API::moduleImport("qiskit").getMember("ClassicalRegister").getACall()
      or
      this = API::moduleImport("qiskit").getMember("circuit").getMember("ClassicalRegister").getACall()
    }
  }