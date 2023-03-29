import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Qubit


private class GateNameCall extends string {
    GateNameCall() {
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
        this = "cnot" or
        this = "cy" or
        this = "cz" or
        this = "ch" or
        this = "crz" or
        this = "cry" or
        this = "crx" or
        this = "cu1" or
        this = "cu3" or
        this = "swap" or
        this = "ccx" or
        this = "toffoli" or
        this = "cswap" or
        this = "rxx" or
        this = "ryy" or
        this = "rzz" or
        this = "rzx" or
        this = "mct" or
        this = "measure" or
        this = "measure_all"
    }
}

private class GateNameObj extends string {
    GateNameObj() {
        this = "XGate" or
        this = "YGate" or
        this = "ZGate" or
        this = "HGate" or
        this = "SGate" or
        this = "SdgGate" or
        this = "TGate" or
        this = "TdgGate" or
        this = "RXGate" or
        this = "RYGate" or
        this = "RZGate" or
        this = "U1Gate" or
        this = "U2Gate" or
        this = "U3Gate" or
        this = "CXGate" or
        this = "CYGate" or
        this = "CZGate" or
        this = "CHGate" or
        this = "CRZGate" or
        this = "CU1Gate" or
        this = "CU3Gate" or
        this = "SwapGate" or
        this = "CCXGate" or
        this = "CSwapGate" or
        this = "RXXGate" or
        this = "RYYGate" or
        this = "RZZGate" or
        this = "RZXGate" or
        this = "RCCXGate" or
        this = "ECRGate" or
        this = "Measure"
    }
}

private predicate isGateCall(DataFlow::CallCfgNode call) {
    exists(
        QuantumCircuit circ,
        GateNameCall gate_name_call
        |
        // detect qc.h(0)
        call = circ.getAnAttributeRead(gate_name_call).getACall()
    )
}

private predicate isGateObj(DataFlow::CallCfgNode call) {
    exists(
        QuantumCircuit circ,
        GateNameObj gate_name_obj
        |
        // detect from qiskit.circuit.library import HGate
        call = API::moduleImport("qiskit")
            .getMember("circuit").getMember("library")
            .getMember(gate_name_obj).getACall()
        and
        // make sure that the gate is used in a circuit using the append()
        circ.getAnAttributeRead("append").getACall()
            .(API::CallNode).getParameter(0, "instruction")
            .getAValueReachingSink() = call
    )
}


class Gate extends DataFlow::CallCfgNode {
    Gate() {
        isGateCall(this) or
        isGateObj(this)
    }

    abstract string getGateName();
    abstract QuantumCircuit getQuantumCircuit();

    /** The integer of a target qubit (no information on the register). */
    abstract IntegerLiteral getATargetQubit();

    predicate isAppliedAfterOn(Gate other, int qubit_index) {
        exists(
            QuantumCircuit circ,
            QubitUsedInteger this_used_qubit,
            QubitUsedInteger other_used_qubit
            |

            // // WITH TARGET QUBITS DIRECTLY - OLD VERSION
            // // they act on the same qubit
            // and this.getATargetQubit().getValue() = qubit_index
            // and other.getATargetQubit().getValue() = qubit_index

            // they are in the same file
            this.getLocation().getFile() = other.getLocation().getFile() and
            // they are applied in the right order: other >> this
            other.getNode().strictlyReaches(this.getNode())
            // they belong to the same circuit
            and circ = this.getQuantumCircuit()
            and circ = other.getQuantumCircuit()

            // // WITH QUBIT USED INDEX
            and this_used_qubit = this.getATargetQubit()
            and other_used_qubit = other.getATargetQubit()
            and
                (
                    // // they act on the same register
                    // // (if there is one explicitely instantiated)
                    this_used_qubit.getQuantumRegister() = other_used_qubit.getQuantumRegister()
                    or
                    (
                        // or they act on the single quantum register of a circuit
                        // experessed implicitely with e.g. QuantumCircuit(4)
                        count(QuantumRegister reg | reg = circ.getAQuantumRegister() | reg) = 0
                        and circ.getNumberOfQubits() > 0
                    )
                )
            // and they act on the same position
            and this_used_qubit.getQubitIndex() = other_used_qubit.getQubitIndex()
            // bind the qubit index
            and qubit_index = this_used_qubit.getQubitIndex()


            // EXTRA PRECISION
            // they refer to the same circuit instance
            and circ.getNode().strictlyReaches(this.getNode())
            and circ.getNode().strictlyReaches(other.getNode())
            // we do not want a situation where the order is:
            // other >> initialization >> gate
            // because they would not refer to the same circuit anymore
            and not other.getNode().strictlyReaches(circ.getNode())
        )
    }

    predicate isAppliedAfter(Gate other) {
        exists(
            int qubit_index
            |
            this.isAppliedAfterOn(other, qubit_index)
        )
    }

    predicate isAppliedBefore(Gate other) {
        other.isAppliedAfter(this)
    }

    predicate isMeasurement() {
        (this instanceof MeasureGate or this instanceof MeasurementAll)
    }

}


private class GenericGateObj extends Gate {

    GenericGateObj() {
        isGateObj(this)
    }

    DataFlow::CallCfgNode getAppendCall() {
        exists(
            QuantumCircuit circ, DataFlow::CallCfgNode append_call
            |
            append_call = circ.getAnAttributeRead("append").getACall()
            and
            append_call
                .(API::CallNode).getParameter(0, "instruction")
                .getAValueReachingSink() = this
            |
            result = append_call
        )
    }

    override string getGateName() {
        result = this.(API::CallNode).getFunction().asVar().getName()
    }

    override QuantumCircuit getQuantumCircuit() {
        exists(
            QuantumCircuit circ
            |
            circ.getAnAttributeRead("append").getACall()
                .(API::CallNode).getParameter(0, "instruction")
                .getAValueReachingSink() = this
            |
            result = circ
        )
    }


    /* get a target qubit of this gate */
    override IntegerLiteral getATargetQubit() {
        // qc.append(CXGate(), qargs=[0, 1])
        // returns either 0 or 1
        exists(
            List qargs
            |
            qargs = getAppendCall().(API::CallNode)
                .getParameter(1, "qargs").getAValueReachingSink().asExpr()
            |
            result = qargs.getAnElt()
        )
        or
        // qc.append(CXGate(), [qreg[0], qreg[1]])
        // returns either 0 or 1
        exists(
            List qargs
            |
            qargs = getAppendCall().(API::CallNode)
                .getParameter(1, "qargs").getAValueReachingSink().asExpr()
            |
            result = qargs.getAnElt().(Subscript).getIndex()
        )
    }

}

private class GenericGateCall extends Gate {

    GenericGateCall() {
        isGateCall(this)
    }

    override string getGateName() {
        exists(
            QuantumCircuit circ, GateNameCall a_supported_gate_name |
            this = circ.getAnAttributeRead(a_supported_gate_name).getACall() |
            result = a_supported_gate_name
        )
    }

    override QuantumCircuit getQuantumCircuit() {
        exists(
            QuantumCircuit circ|
            this = circ.getAnAttributeRead(_).getACall() |
            result = circ
        )
    }

    /* get a target qubit of this gate */
    override IntegerLiteral getATargetQubit() {
        // qc.cx(0, 1)
        // returns either 0 or 1
        exists(
            API::Node p, IntegerLiteral i
            |
                isQubitParameter(p) and
                (
                    // qc.cx(0, 1)
                    p.getAValueReachingSink()
                        .asExpr() = i
                    or
                    // qc.cx(qreg[0], qreg[1])
                    p.getAValueReachingSink().asExpr().(Subscript)
                        .getIndex() = i
                    or
                    // qc.measure([0, 1], [0, 1])
                    p.getAValueReachingSink().asExpr().(List)
                        .getAnElt() = i
                )

            |
            result = i
        )
    }

    /* holds if the parameters at position i is a qubit parameter for this gate */
    predicate isQubitParameter(API::Node p) {
        ((
            this.getGateName() = "cx" or this.getGateName() = "cz" or
            this.getGateName() = "cy" or this.getGateName() = "ch" or
            this.getGateName() = "cnot"
          ) and
            (
                this.(API::CallNode).getParameter(0, "control_qubit") = p
                or
                this.(API::CallNode).getParameter(1, "target_qubit") = p
            )) or
        ((this.getGateName() = "crz" or this.getGateName() = "crx" or this.getGateName() = "cry") and
            (
                this.(API::CallNode).getParameter(1, "control_qubit") = p
                or
                this.(API::CallNode).getParameter(2, "target_qubit") = p
            )) or
        ((this.getGateName() = "cu1"  or this.getGateName() = "cp")
            and
            (
                this.(API::CallNode).getParameter(1, "control_qubit") = p
                or
                this.(API::CallNode).getParameter(2, "target_qubit") = p
            )) or
        (this.getGateName() = "cu3" and
            (
                this.(API::CallNode).getParameter(3, "control_qubit") = p
                or
                this.(API::CallNode).getParameter(4, "target_qubit") = p
            )) or
        (this.getGateName() = "cu" and
        (
            this.(API::CallNode).getParameter(4, "control_qubit") = p
            or
            this.(API::CallNode).getParameter(5, "target_qubit") = p
        )) or
        ((
            this.getGateName() = "h" or this.getGateName() = "x" or
            this.getGateName() = "y" or this.getGateName() = "z" or
            this.getGateName() = "s" or this.getGateName() = "sdg" or
            this.getGateName() = "t" or this.getGateName() = "tdg" or
            this.getGateName() = "measure"
          ) and
                this.(API::CallNode).getParameter(0, "qubit") = p) or
        ((
            this.getGateName() = "rx" or this.getGateName() = "ry" or
            this.getGateName() = "rz" or this.getGateName() = "u1" or
            this.getGateName() = "p"
            ) and
                this.(API::CallNode).getParameter(1, "qubit") = p) or
        (this.getGateName() = "u2" and
                this.(API::CallNode).getParameter(2, "qubit") = p) or
        (this.getGateName() = "u3" and
                this.(API::CallNode).getParameter(3, "qubit") = p) or
        (this.getGateName() = "u" and
                this.(API::CallNode).getParameter(3, "qubit") = p) or
        (this.getGateName() = "swap" and
            (
                this.(API::CallNode).getParameter(0, "qubit1") = p
                or
                this.(API::CallNode).getParameter(1, "qubit2") = p
            )) or
        ((
            this.getGateName() = "ccx" or this.getGateName() = "toffoli"
            ) and
            (
                this.(API::CallNode).getParameter(0, "control_qubit1") = p
                or
                this.(API::CallNode).getParameter(1, "control_qubit2") = p
                or
                this.(API::CallNode).getParameter(2, "target_qubit") = p
            )) or
        (this.getGateName() = "cswap" and
            (
                this.(API::CallNode).getParameter(0, "control_qubit") = p
                or
                this.(API::CallNode).getParameter(1, "target_qubit1") = p
                or
                this.(API::CallNode).getParameter(2, "target_qubit2") = p
            )) or
        ((
            this.getGateName() = "rxx" or this.getGateName() = "ryy" or
            this.getGateName() = "rzz" or this.getGateName() = "rzx"
          )
            and
            (
                this.(API::CallNode).getParameter(1, "qubit1") = p
                or
                this.(API::CallNode).getParameter(2, "qubit2") = p
            )) or
        ((
            this.getGateName() = "mct"
            )
            and
            (
                this.(API::CallNode).getParameter(0, "control_qubits") = p
                or
                this.(API::CallNode).getParameter(1, "target_qubit") = p
                or
                this.(API::CallNode).getParameter(2, "ancilla_qubits") = p
            ))
    }

}

class MeasureGate extends GenericGateCall {
    MeasureGate() {
        this.getGateName() = "measure"
    }

    int getATargetBit() {
        exists(
            API::Node p, int i
            |
            p = this.(API::CallNode).getParameter(1, "cbit")  and
            (
                // qc.measure(0, 1)
                p.getAValueReachingSink().asExpr().(IntegerLiteral).getValue() = i
                or
                // qc.measure(qreg[0], creg[1])
                p.getAValueReachingSink().asExpr().(Subscript).getIndex().(IntegerLiteral).getValue() = i
                or
                // qc.measure([0, 1], [0, 1])
                p.getAValueReachingSink().asExpr().(List).getAnElt().(IntegerLiteral).getValue() = i
            )
            |
            result = i
        )
    }
}

class MeasurementAll extends GenericGateCall {
    MeasurementAll() {
        this.getGateName() = "measure_all"
    }


    // TODO rename createsNewRegister
    predicate hasDefaultArgs() {
        not this.(API::CallNode).getParameter(
            1, "add_bits").getAValueReachingSink().asExpr().(
                ImmutableLiteral).booleanValue() = false
    }
}

class MeasurementAny extends DataFlow::CallCfgNode {
    MeasurementAny() {
        this instanceof MeasureGate or this instanceof MeasurementAll
    }
}