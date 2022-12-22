import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.register
import qiskit.gate


class QuantumCircuit extends DataFlow::CallCfgNode {
    QuantumCircuit() {

        this = API::moduleImport("qiskit").getMember("transpile").getACall()
        or
        this = API::moduleImport("qiskit").getMember("QuantumCircuit").getACall()
    }

    string get_name() {
        exists(AssignStmt a |
            a.contains(this.getNode().getNode()) and
            result = a.getATarget().(Name).getId()
        )
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

    Gate get_a_gate() {
        exists(Gate g | g.get_quantum_circuit() = this |
            result = g
        )
    }

    GenericGate get_a_generic_gate() {
        exists(GenericGate g | g.get_quantum_circuit() = this |
            result = g
        )
    }

    QuantumRegister get_a_quantum_register() {
        exists(QuantumRegister qntReg, int i |
            qntReg.flowsTo(this.getArg(i)) |
            result = qntReg
        )
    }

    ClassicalRegister get_a_classical_register() {
        exists(ClassicalRegister clsReg, int i |
            clsReg.flowsTo(this.getArg(i)) |
            result = clsReg
        )
    }

}

class TranspiledCircuit extends QuantumCircuit{
    TranspiledCircuit () {
        this = API::moduleImport("qiskit").getMember("transpile").getACall()
        // exists(
        //     DataFlow::CallCfgNode transpileCall,
        //     Assign assignment,
        //     DataFlow::CallCfgNode leftSide
        //         |
        //         transpileCall = API::moduleImport("qiskit").getMember("transpile").getACall() |
        //         // the transpile call flows in the left-hand side of the assignment
        //         leftSide.asExpr() = assignment.getATarget() and
        //         //transpileCall.flowsTo(leftSide) and
        //         this = leftSide
        // )
    }
}