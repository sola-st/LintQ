import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.register


class QuantumCircuit extends DataFlow::CallCfgNode {
    QuantumCircuit() {
        this = API::moduleImport("qiskit").getMember("QuantumCircuit").getACall()
    }

    int get_num_qubits() {
        exists(IntegerLiteral num_qubits |
            num_qubits = this.getArg(0).asExpr() and
            result = num_qubits.getValue()
        ) or
        exists( QuantumRegister qntReg|
            // there is a dataflow between the quantum register and the quantum circuit
            exists(int i |
                qntReg.flowsTo(this.getArg(i)))
            and
            // the number of qubits is the number of qubits in the quantum register
            result = qntReg.get_num_qubits()
        )
    }

    int get_num_bits() {
        exists(IntegerLiteral num_bits |
            num_bits = this.getArg(1).asExpr() and
            result = num_bits.getValue()
        ) or
        exists( ClassicalRegister clsReg|
            // there is a dataflow between the classical register and the quantum circuit
            exists(int i |
                clsReg.flowsTo(this.getArg(i)))
            and
            // the number of bits is the number of bits in the classical register
            result = clsReg.get_num_bits()
        )
    }

    int get_total_num_bits() {
        result = sum(ClassicalRegister clsReg, int i |
            clsReg.flowsTo(this.getArg(i)) |
            clsReg.get_num_bits())
    }

    int get_total_num_qubits() {
        result = sum(QuantumRegister qntReg, int i |
            qntReg.flowsTo(this.getArg(i)) |
            qntReg.get_num_qubits())
    }

}