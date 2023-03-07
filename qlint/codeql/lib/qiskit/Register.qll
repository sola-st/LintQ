
import python
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


    Variable getVar() {
        // get the left side of the assignment
        // e.g. reg = QuantumRegister(2)
        // reg is the name of the register
        exists(
            Variable var,
            AssignStmt assignStmt
            |
            //var.getAStore() = this.asExpr()
            //and
            assignStmt.getValue() = this.asExpr()
            and
            var.getScope() = assignStmt.getScope()
            and
            assignStmt.getATarget() = var.getAStore()
            |
            // return the left side of the assignment, namely the reference
            // to the NameNode
            result = var
        )

    }


    /** Gets a qubit index/position available in this register as int.*/
    int getAQubitIndex() {
        exists(
            int i
            |
            i = [0 .. this.getSize() - 1]
            |
            result = i
        )
    }




}