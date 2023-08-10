import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Register
import qiskit.Gate


class ComposeCall extends DataFlow::CallCfgNode {
    /**
     * Holds if the call is a compose call.
     */
    ComposeCall() {
        exists(QuantumCircuit parentCirc
            |
            this = parentCirc.getAnAttributeRead("compose").getACall()
        )
    }
}

class ReturnsNewValue extends DataFlow::CallCfgNode {
    /**
     * Holds if the call has not inplace=True
     */
    ReturnsNewValue() {
        // Holds it is a compose call without inplace=True
        // Because if inplace=True, the circuit is modified in place,
        // thus the call represent nothing.
        not exists(
            DataFlow::Node parameterInplace
            |
            parameterInplace = this.getArgByName("inplace")
            |
            parameterInplace.asExpr().(ImmutableLiteral).booleanValue() = true
        )
    }
}


class BuiltinParametrizedCircuitsConstructors extends DataFlow::CallCfgNode {
    /**
     * Holds if the call is a predefined parametrized circuit.
     * e.g. TwoLocal(3, ['h', 'cx'], 'cz', 'full', reps=3)
     * e.g. NLocal(3, ['h', 'cx'], 'cz', 'full', reps=3)
     * e.g. RealAmplitudes(3, reps=3)
     * e.g. EfficientSU2(3, reps=3)
     * e.g. ExcitationPreserving(3, reps=3)
     * e.g. PauliTwoDesign(3, reps=3)
     * e.g. QAOAAnsatz(3, reps=3)
     * They are generally imported as follows:
     * from qiskit.circuit.library import TwoLocal, NLocal, RealAmplitudes, EfficientSU2, ExcitationPreserving, PauliTwoDesign, QAOAAnsatz
     */
    BuiltinParametrizedCircuitsConstructors() {
        exists(
            string importName
            |
            importName in ["TwoLocal", "NLocal", "RealAmplitudes", "EfficientSU2", "ExcitationPreserving", "PauliTwoDesign", "QAOAAnsatz"]
            |
            this = API::moduleImport("qiskit").getMember("circuit").getMember("library").getMember(importName).getACall()
        )
    }
}


class TranspileCall extends DataFlow::CallCfgNode {
    /**
     * Holds if the call is a transpile call.
     */
    TranspileCall() {
        this = API::moduleImport("qiskit").getMember("transpile").getACall()
    }
}


class QuantumCircuitConstructor extends DataFlow::CallCfgNode {
    /**
     * Holds if the call is a QuantumCircuit constructor call.
     */
    QuantumCircuitConstructor() {
        this = API::moduleImport("qiskit").getMember("QuantumCircuit").getACall()
    }
}


class CopyCircuitCall extends DataFlow::CallCfgNode {
    /**
     * Holds if the call is a clone call.
     */
    CopyCircuitCall() {
        exists(QuantumCircuit parentCirc
            |
            this = parentCirc.getAnAttributeRead("copy").getACall()
        )
    }
}


/** A def statement returning a quantum circuit. */
class UDFFunctionDefReturningAQuantumCircuit extends FunctionDef {
    /**
     * Holds if the function def returns a quantum circuit.
     */
    UDFFunctionDefReturningAQuantumCircuit() {
        exists(
            FunctionDef fd, Return ret, QuantumCircuit qc
            |
            // the function definition has a return statement
            fd.contains(ret)
            and
            (
                // the return statement returns a QuantumCircuit
                ret.contains(qc.asExpr())
                or
                // in the return statement flows an object that is a QuantumCircuit (use local flow)
                exists(
                    DataFlow::Node objectInReturnStatement
                    |
                    ret.contains(objectInReturnStatement.asExpr())
                    and
                    qc.flowsTo(objectInReturnStatement)
                )
            )
            |
            this = fd
        )
    }
}

/** A call to a UDF returning a quantum circuit. */
class UDFCallReturningAQuantumCircuit extends DataFlow::CallCfgNode {
    /**
     * Holds if the call returns a QuantumCircuit
     */
    UDFCallReturningAQuantumCircuit() {
        exists(
            DataFlow::CallCfgNode call,
            UDFFunctionDefReturningAQuantumCircuit fd
            |
            call.getFunction().asExpr().(Name).getId() = fd.getDefinedFunction().getName()
            and
            // same scope
            call.getScope() = fd.getScope()
            |
            this = call
        )
    }
}


/** A function call returning a quantum circuit object. */
class CallReturningAQuantumCircuit extends DataFlow::CallCfgNode {
    /**
     * Holds if the call returns a QuantumCircuit
     */
    CallReturningAQuantumCircuit() {
        (
            this instanceof ComposeCall
            or
            this instanceof CopyCircuitCall
            or
            this instanceof BuiltinParametrizedCircuitsConstructors
            or
            this instanceof TranspileCall
            or
            this instanceof QuantumCircuitConstructor
            or
            this instanceof UDFCallReturningAQuantumCircuit
        )
        and
        this instanceof ReturnsNewValue
    }
}




class QuantumCircuit extends DataFlow::CallCfgNode {
    /**
     * Holds if the circuit has been initialized with QuantumCircuit:
     * e.g. qc = QuantumCircuit(2, 3)
     * or if it is the target value of an assignment statement which assignes
     * the reutrn value of a function call to a variable, and this return value
     * is a QuantumCircuit:
     * e.g. qc = transpile(circuit, backend)
     * e.g. qc = qc1 + qc2
     * e.g. qc = qc1.compose(qc2)
     * e.g. qc = qc1.copy()
     * e.g. qc = qc1.decompose()
     * e.g. qc = TwoLocal(3, ['h', 'cx'], 'cz', 'full', reps=3)
     */
    QuantumCircuit() {
        this instanceof CallReturningAQuantumCircuit
    }

    string getName() {
        exists(AssignStmt a |
            a.contains(this.getNode().getNode()) and
            result = a.getATarget().(Name).getId()
        )
    }


    private int get_num_bits_with_integers() {
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

    private int get_num_bits_from_registers() {
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
            clsReg.getSize())

    }

    int getNumberOfClassicalBits() {
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

    private int get_num_qubits_with_integers() {
        exists(IntegerLiteral num_qubits, DataFlow::LocalSourceNode source |
            source.flowsTo(this.getArg(0)) and
            source.asExpr() = num_qubits |
            result = num_qubits.getValue()
        )
    }

    private int get_num_qubits_from_registers() {
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
            qntReg.getSize())
    }

    int getNumberOfQubits() {
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

    predicate isSubCircuit() {
        exists(QuantumCircuit qc |
            this.isSubCircuitOf(qc)
        )
    }

    predicate isSubCircuitOf(QuantumCircuit other) {
        this != other and
        // this circuit is the argument of the append() or compose() called on
        // another circuit
        exists(DataFlow::CallCfgNode appendOrComposeCall |
            appendOrComposeCall = other.getAnAttributeRead("append").getACall()
            or appendOrComposeCall = other.getAnAttributeRead("compose").getACall()|
            this.flowsTo(appendOrComposeCall.getArg(0))
        )
    }

    Gate getAGate() {
        exists(Gate g | g.getQuantumCircuit() = this |
            result = g
        )
    }

    //* Returns a QuantumRegister added to a circuit. */
    QuantumRegister getAQuantumRegister() {
        exists(QuantumRegister qntReg, int i |
            qntReg.flowsTo(this.getArg(i)) |
            result = qntReg
        ) or
        // there is a this.add_register() call with qntReg as argument
        exists(
            QuantumRegister qntReg, DataFlow::CallCfgNode addRegisterCall
            |
            addRegisterCall = this.getAnAttributeRead("add_register").getACall() and
            qntReg.flowsTo(addRegisterCall.getArg(0))
            |
            result = qntReg
        )
    }

    ClassicalRegister getAClassicalRegister() {
        exists(ClassicalRegister clsReg, int i |
            clsReg.flowsTo(this.getArg(i)) |
            result = clsReg
        ) or
        // there is a this.add_register() call with clsReg as argument
        exists(
            ClassicalRegister clsReg, DataFlow::CallCfgNode addRegisterCall
            |
            addRegisterCall = this.getAnAttributeRead("add_register").getACall() and
            clsReg.flowsTo(addRegisterCall.getArg(0))
            |
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

    int getOptimizationLvl() {
        result = this.( API::CallNode ).getParameter(7, "optimization_level")
            .getAValueReachingSink().asExpr().(IntegerLiteral).getValue()
    }
}