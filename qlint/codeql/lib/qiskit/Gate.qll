import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit


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
    abstract int getATargetQubit();

    predicate isAppliedAfter(Gate other) {
        exists(
            QuantumCircuit circ
            |
            circ = this.getQuantumCircuit() and
            circ = other.getQuantumCircuit() and
            other.getATargetQubit() = this.getATargetQubit() and
            other.asCfgNode().strictlyReaches(this.asCfgNode())
        )
    }

    predicate isAppliedBefore(Gate other) {
        other.isAppliedAfter(this)
    }

    predicate isMeasurement() {
        this instanceof MeasureGate or this instanceof MeasurementAll
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
    override int getATargetQubit() {
        // qc.append(CXGate(), qargs=[0, 1])
        // returns either 0 or 1
        exists(
            List qargs
            |
            qargs = getAppendCall().(API::CallNode).getParameter(1, "qargs").getAValueReachingSink().asExpr()
            |
            result = qargs.getAnElt().(IntegerLiteral).getValue()
        )
        or
        // qc.append(CXGate(), [qreg[0], qreg[1]])
        // returns either 0 or 1
        exists(
            List qargs
            |
            qargs = getAppendCall().(API::CallNode).getParameter(1, "qargs").getAValueReachingSink().asExpr()
            |
            result = qargs.getAnElt().(Subscript).getIndex().(IntegerLiteral).getValue()
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
            QuantumCircuit circ, GateNameCall a_supported_gate_name |
            this = circ.getAnAttributeRead(a_supported_gate_name).getACall() |
            result = circ
        )
    }

    /* get a target qubit of this gate */
    override int getATargetQubit() {
        // qc.cx(0, 1)
        // returns either 0 or 1
        exists(
            API::Node p, int i
            |
                isQubitParameter(p) and
                (
                    // qc.cx(0, 1)
                    p.getAValueReachingSink().asExpr().(IntegerLiteral).getValue() = i
                    or
                    // qc.cx(qreg[0], qreg[1])
                    p.getAValueReachingSink().asExpr().(Subscript).getIndex().(IntegerLiteral).getValue() = i
                    or
                    // qc.measure([0, 1], [0, 1])
                    p.getAValueReachingSink().asExpr().(List).getAnElt().(IntegerLiteral).getValue() = i
                )

            |
            result = i
        )
    }

    /* holds if the parameters at position i is a qubit parameter for this gate */
    predicate isQubitParameter(API::Node p) {
        ((
            this.getGateName() = "cx" or this.getGateName() = "cz" or
            this.getGateName() = "cy" or this.getGateName() = "ch"
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
        (this.getGateName() = "ccx" and
            (
                this.(API::CallNode).getParameter(1, "control_qubit1") = p
                or
                this.(API::CallNode).getParameter(2, "control_qubit2") = p
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
}

class MeasurementAny extends DataFlow::CallCfgNode {
    MeasurementAny() {
        this instanceof MeasureGate or this instanceof MeasurementAll
    }
}