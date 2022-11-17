
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

}