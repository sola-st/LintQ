
import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs


class ClassicalRegister extends DataFlow::CallCfgNode {
    ClassicalRegister() {
        this = API::moduleImport("qiskit").getMember("ClassicalRegister").getACall()
    }

    int get_num_bits() {
        exists(IntegerLiteral num_bits |
            num_bits = this.getArg(0).asExpr() and
            result = num_bits.getValue()
        )
    }

    // the classical register object can be accessed by the name of the variable
    // and an index. For example:
    // creg[0]
    // creg[1]
    // creg[2]
    // we want to a general node representing one of this accesses
    int get_an_accessed_bit() {
        exists(
            DataFlow::Node nd,
            DataFlow::ExprNode targetSubscript,
            Subscript subscript,
            IntegerLiteral bit |
            this.flowsTo(nd) and
            nd.asExpr() = targetSubscript.asExpr() and
            targetSubscript.asExpr() = subscript.getObject() and
            bit = subscript.getIndex() |
            result = bit.getValue()
        )
    }


}

class QuantumRegister extends DataFlow::CallCfgNode {
    QuantumRegister() {
        this = API::moduleImport("qiskit").getMember("QuantumRegister").getACall()
    }

    int get_num_qubits() {
        exists(IntegerLiteral num_qubits |
            num_qubits = this.getArg(0).asExpr() and
            result = num_qubits.getValue()
        )
    }

    int get_an_accessed_qubit() {
        exists(
            DataFlow::Node nd,
            DataFlow::ExprNode targetSubscript,
            Subscript subscript,
            IntegerLiteral qubit |
            this.flowsTo(nd) and
            nd.asExpr() = targetSubscript.asExpr() and
            targetSubscript.asExpr() = subscript.getObject() and
            qubit = subscript.getIndex() |
            result = qubit.getValue()
        )
    }
}