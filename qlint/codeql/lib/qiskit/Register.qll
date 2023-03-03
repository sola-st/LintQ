
import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs


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

}