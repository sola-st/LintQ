import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.circuit

class GateName extends string {
    GateName() {
        this = "x" or
        this = "y" or
        this = "z" or
        this = "h" or
        this = "s" or
        this = "sdg" or
        this = "t" or
        this = "tdg" or
        this = "rx" or
        this = "ry" or
        this = "rz" or
        this = "u1" or
        this = "u2" or
        this = "u3" or
        this = "cx" or
        this = "cy" or
        this = "cz" or
        this = "ch" or
        this = "crz" or
        this = "cu1" or
        this = "cu3" or
        this = "swap" or
        this = "ccx" or
        this = "cswap" or
        this = "rxx" or
        this = "ryy" or
        this = "rzz" or
        this = "rzx" or
        this = "rzz" or
        this = "measure" or
        this = "measure_all"
    }
}

// TODO: improve to support
// from qiskit import QuantumCircuit
// qc = QuantumCircuit(2)
// qc.append(CXGate(), [0, 1])

class GenericGate extends DataFlow::CallCfgNode {

    GenericGate() {
        exists(
            QuantumCircuit circ, GateName a_supported_gate_name|
            this = circ.getAnAttributeRead(a_supported_gate_name).getACall()
        )
    }

    string get_gate_name() {
        exists(
            QuantumCircuit circ, GateName a_supported_gate_name |
            this = circ.getAnAttributeRead(a_supported_gate_name).getACall() |
            result = a_supported_gate_name
        )
    }

    QuantumCircuit get_quantum_circuit() {
        exists(
            QuantumCircuit circ |
            this = circ.getAnAttributeRead(this.get_gate_name()).getACall()|
            result = circ
        )
    }


    int get_a_target_qubit() {

        // TODO: improve to support sequences of qubits or integers
        exists(
            int target_qubit, int i |
            target_qubit = this.getArg(i).asExpr().(IntegerLiteral).getValue()|
            // return a list with only the target qubit
            result = target_qubit
        )
        // handle the case where the arguments are in accessed through a quantum
        // reigster variable like this:
        // q = QuantumRegister(2)
        // qc = QuantumCircuit(q)
        // qc.cx(q[0], q[1])
        or
        exists(
            QuantumRegister qreg,
            DataFlow::Node nd,
            DataFlow::ExprNode targetSubscript,
            Subscript subscript,
            IntegerLiteral bit,
            int i |
                qreg.flowsTo(nd) and
                nd.asExpr() = targetSubscript.asExpr() and
                targetSubscript.asExpr() = subscript.getObject() and
                subscript = this.getArg(i).asExpr() and
                bit = subscript.getIndex() |
                result = bit.getValue()
        )
        // handle the case where the arguments are variables on a loop.
        // q = QuantumRegister(2)
        // qc = QuantumCircuit(q)
        // for i in range(2):
        //     qc.h(i)
        or
        exists(
            ForNode forNodeMinimal, //AstNode forTreeMinimal,
            DataFlow::CallCfgNode rangeCall,
            CallNode call, ControlFlowNode func,
            DataFlow::LocalSourceNode sourceMaxDimension,
            IntegerLiteral maxDimension
            |

            //forTreeMinimal = forNodeMinimal.getNode().getAChildNode() and
            // make sure that the range call is for a function called range
            call.getFunction() = func and func.pointsTo(Value::named("range")) and
            // check tha the range call is in the forNodeMinimal
            rangeCall.asCfgNode() = call and
            // check that the range call is the iter of the forNodeMinimal
            forNodeMinimal.getNode().contains(call.getNode()) and
            (
                (
                    // range(n) with single argument
                    sourceMaxDimension.flowsTo(rangeCall.getArg(0)) and
                    sourceMaxDimension.asExpr() = maxDimension and
                    count(call.getAnArg().getNode()) = 1
                )
                or
                (
                    // range(i, n) with two arguments
                    // TODO To improve by checking the difference between the two
                    // values
                    sourceMaxDimension.flowsTo(rangeCall.getArg(1)) and
                    sourceMaxDimension.asExpr() = maxDimension and
                    count(call.getAnArg().getNode()) = 2
                )

            ) and


            // rangeCall.getArg(0).asExpr() = maxDimension and

            // check that this gate is defined in the scope of the for node
            forNodeMinimal.getNode().contains(this.asExpr()) and

            // check that the variable of the loop is the same contained in
            // this gate
            exists(
                Name sourceLoopVar, int argPos
                |
                // TODO improve when the variable is used in a strange way
                // for i in range(6):
                //     circ.u3(self.U3(), 0, 0,[i])
                sourceLoopVar.getVariable().getAUse().getNode() = this.getArg(argPos).asExpr()  and
                sourceLoopVar = forNodeMinimal.getNode().getASubExpression()
            ) and

            // say that the for loop must be minimal
            // namely there must not be another forNode in it
            not (exists(
                ForNode forNode
                |
                forNodeMinimal.getNode().contains(forNode.getNode()) and
                forNodeMinimal.getNode().contains(this.asExpr())
                |
                forNode != forNodeMinimal
                ))
            |
            result = [0 .. maxDimension.getValue() - 1]
        )
    }




    QuantumRegister get_a_target_qubit_in_register() {
        exists(
            QuantumCircuit circ,
            QuantumRegister qntReg |
                this = circ.getAnAttributeRead().getACall() and
                qntReg = circ.get_a_quantum_register() and
                qntReg.flowsTo(this.getArg(0)) |
                result = qntReg
        )
    }

    predicate follows(GenericGate g) {
        exists(
            QuantumCircuit circ |
                this = circ.getAnAttributeRead().getACall() and
                g = circ.getAnAttributeRead().getACall() and
                not this = g and
                this.get_a_target_qubit() = g.get_a_target_qubit() and
                this.get_quantum_circuit() = g.get_quantum_circuit() and
                g.asCfgNode().strictlyReaches(this.asCfgNode())
        )
    }
}


class Gate extends GenericGate {
    Gate() {
        exists(
            QuantumCircuit circ, GateName a_supported_gate_name |
            a_supported_gate_name != "measure"  and a_supported_gate_name != "measure_all"|
            this = circ.getAnAttributeRead(a_supported_gate_name).getACall()
        )
    }
}

class Measure extends GenericGate {
    Measure() {
        exists(
            QuantumCircuit circ, GateName a_supported_gate_name |
            a_supported_gate_name = "measure" |
            this = circ.getAnAttributeRead(a_supported_gate_name).getACall()
        )
    }

}

class MeasureAll extends GenericGate {
    MeasureAll() {
        exists(
            QuantumCircuit circ, GateName a_supported_gate_name |
            a_supported_gate_name = "measure_all" |
            this = circ.getAnAttributeRead(a_supported_gate_name).getACall()
        )
    }
}