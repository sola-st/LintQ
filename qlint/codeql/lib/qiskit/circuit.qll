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


    int get_num_bits_with_integers() {
        // get the number of bits as created with integrer literals
        // e.g. QuantumCircuit(2, 3)
        // the number of bits is 3
        // e.g. n = 4, QuantumCircuit(2, n)
        // the number of bits is 4
        exists(IntegerLiteral num_bits, DataFlow::LocalSourceNode source |
            source.flowsTo(this.getArg(1)) and
            source.asExpr() = num_bits |
            result = num_bits.getValue()
        )
    }

    int get_num_bits_from_registers() {
        // get the number of bits as created with initialized registers
        // creg = ClassicalRegister(3, 'c')
        // qc = QuantumCircuit(2, creg)
        // the number of bits is 3
        result = sum(
            ClassicalRegister clsReg
            |
                clsReg.flowsTo(this.getArg(_))
                or
                // there is a this.add_register() call with clsReg as argument
                exists(
                    DataFlow::CallCfgNode addRegisterCall
                    |
                    addRegisterCall = this.getAnAttributeRead("add_register").getACall() and
                    clsReg.flowsTo(addRegisterCall.getArg(0)))
            |
            clsReg.get_num_bits())

    }

    int get_total_num_bits() {
        exists(
            int num_bits_from_registers, int num_bits_with_integers |
            num_bits_from_registers = this.get_num_bits_from_registers() and
            num_bits_with_integers = this.get_num_bits_with_integers() |
            result = num_bits_from_registers + num_bits_with_integers
        ) or
        // if there is only a classical register
        exists(
            int num_bits_from_registers
            |
            num_bits_from_registers = this.get_num_bits_from_registers() and
            not exists(int num_bits_with_integers |
                num_bits_with_integers = this.get_num_bits_with_integers())
            |
            result = num_bits_from_registers
        ) or
        // if there is only a number of bits
        exists(
            int num_bits_with_integers
            |
            num_bits_with_integers = this.get_num_bits_with_integers() and
            not exists(int num_bits_from_registers |
                num_bits_from_registers = this.get_num_bits_from_registers())
            |
            result = num_bits_with_integers
        )
    }

    int get_num_qubits_with_integers() {
        exists(IntegerLiteral num_qubits, DataFlow::LocalSourceNode source |
            source.flowsTo(this.getArg(0)) and
            source.asExpr() = num_qubits |
            result = num_qubits.getValue()
        )
    }

    int get_num_qubits_from_registers() {
        result = sum(
            QuantumRegister qntReg
            |
                exists(int i | qntReg.flowsTo(this.getArg(i)))
                or
                // there is a this.add_register() call with qntReg as argument
                exists(
                    DataFlow::CallCfgNode addRegisterCall
                    |
                    addRegisterCall = this.getAnAttributeRead("add_register").getACall() and
                    qntReg.flowsTo(addRegisterCall.getArg(0)))
            |
            qntReg.get_num_qubits())
    }

    int get_total_num_qubits() {
        exists(
            int num_qubits_from_registers, int num_qubits_with_integers |
            num_qubits_from_registers = this.get_num_qubits_from_registers() and
            num_qubits_with_integers = this.get_num_qubits_with_integers() |
            result = num_qubits_from_registers + num_qubits_with_integers
        ) or
        // if there is only a quantum register
        exists(
            int num_qubits_from_registers
            |
            num_qubits_from_registers = this.get_num_qubits_from_registers() and
            not exists(int num_qubits_with_integers |
                num_qubits_with_integers = this.get_num_qubits_with_integers())
            |
            result = num_qubits_from_registers
        ) or
        // if there is only a number of qubits
        exists(
            int num_qubits_with_integers
            |
            num_qubits_with_integers = this.get_num_qubits_with_integers() and
            not exists(int num_qubits_from_registers |
                num_qubits_from_registers = this.get_num_qubits_from_registers())
            |
            result = num_qubits_with_integers
        )
    }

    predicate is_subcircuit() {
        // it is a subcircuit this circuit is the argument of the append() or
        // compose() called on another circuit
        exists(QuantumCircuit motherCircuit |
            motherCircuit != this |
            exists(DataFlow::CallCfgNode appendOrComposeCall |
                appendOrComposeCall = motherCircuit.getAnAttributeRead("append").getACall()
                or appendOrComposeCall = motherCircuit.getAnAttributeRead("compose").getACall()|
                this.flowsTo(appendOrComposeCall.getArg(0))
            )
        )

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