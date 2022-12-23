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
            QuantumCircuit circ, int target_qubit, int i |
            this = circ.getAnAttributeRead().getACall() and
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
            QuantumCircuit circ,
            QuantumRegister qreg,
            DataFlow::Node nd,
            DataFlow::ExprNode targetSubscript,
            Subscript subscript,
            IntegerLiteral bit,
            int i |
                this = circ.getAnAttributeRead().getACall() and
                qreg.flowsTo(nd) and
                nd.asExpr() = targetSubscript.asExpr() and
                targetSubscript.asExpr() = subscript.getObject() and
                subscript = this.getArg(i).asExpr() and
                bit = subscript.getIndex() |
                result = bit.getValue()
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

    override int get_a_target_qubit() {
        // note that measure gets qubits only in the first position
        // TODO: improve to support sequences of qubits or integers
        // e.g. qc.measure([0, 1], [0, 1])
        // from documentation Parameters
        // qubit (Union[Qubit, QuantumRegister, int, slice, Sequence[Union[Qubit, int]]]) – qubit to measure.
        // cbit (Union[Clbit, ClassicalRegister, int, slice, Sequence[Union[Clbit, int]]]) – classical bit to place the measurement in.

        // TODO: improve to support entire registers
        // e.g. qc.measure(q, c)
        exists(
            QuantumCircuit circ, int target_qubit|
            this = circ.getAnAttributeRead("measure").getACall() and
            target_qubit = this.getArg(0).asExpr().(IntegerLiteral).getValue()|
            // return a list with only the target qubit
            result = target_qubit
        )
        or
        exists(
            QuantumCircuit circ,
            QuantumRegister qreg,
            DataFlow::Node nd,
            DataFlow::ExprNode targetSubscript,
            Subscript subscript,
            IntegerLiteral bit|
                this = circ.getAnAttributeRead("measure").getACall() and
                qreg.flowsTo(nd) and
                nd.asExpr() = targetSubscript.asExpr() and
                targetSubscript.asExpr() = subscript.getObject() and
                subscript = this.getArg(0).asExpr() and
                bit = subscript.getIndex() |
                result = bit.getValue()
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