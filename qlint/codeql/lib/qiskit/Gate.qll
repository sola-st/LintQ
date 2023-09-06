import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
// import qiskit.Qubit
import qiskit.BitUse

private predicate isGateCall(DataFlow::CallCfgNode call) {
  exists(QuantumCircuit circ, OperatorSpecificationAttributeName gate_name_call |
    // detect qc.h(0)
    call = circ.getAnAttributeRead(gate_name_call).getACall()
  )
}

private predicate isGateObj(DataFlow::CallCfgNode call) {
  exists(QuantumCircuit circ, OperatorSpecificationObjectName gate_name_obj |
    // detect from qiskit.circuit.library import HGate
    call =
      API::moduleImport("qiskit")
          .getMember("circuit")
          .getMember("library")
          .getMember(gate_name_obj)
          .getACall() and
    // make sure that the gate is used in a circuit using the append()
    circ.getAnAttributeRead("append")
        .getACall()
        .(API::CallNode)
        .getParameter(0, "instruction")
        .getAValueReachingSink() = call
  )
}


/** Quantum Operator either a gate, measurement or reset. */
abstract class QuantumOperator extends DataFlow::CallCfgNode {
  // Gate() {
  //   isGateCall(this) or
  //   isGateObj(this)
  // }

  /** The name of the gate. */
  abstract string getGateName();

  /** The circuit where the gate is applied. */

  abstract QuantumCircuit getQuantumCircuit();

  /** The integer of a target qubit (no information on the register). */
  int getATargetQubit() { exists(QubitUse bu | bu.getAGate() = this | result = bu.getAnIndex()) }

  /** Holds if this gate is applied after the other gate on the same qubit. */
  pragma[inline]
  predicate isAppliedAfterOn(QuantumOperator other, int qubit_index) {
    exists(
      QuantumCircuit circ, BitUse thisBitUse, BitUse otherBitUse, ControlFlowNode thisNode,
      ControlFlowNode otherNode, ControlFlowNode circNode
    |
      // they are in the same file
      exists(File f |
        this.getLocation().getFile() = f and
        other.getLocation().getFile() = f and
        circ.getLocation().getFile() = f and
        thisBitUse.getLocation().getFile() = f and
        otherBitUse.getLocation().getFile() = f
      ) and
      // they are connected to the control flow
      thisNode = this.getNode() and
      otherNode = other.getNode() and
      // they are applied in the right order: other >> this
      otherNode.strictlyReaches(thisNode) and
      // they belong to the same circuit
      circ = this.getQuantumCircuit() and
      circ = other.getQuantumCircuit() and
      // connect bit use and the two gates
      thisBitUse.getAGate() = this and
      otherBitUse.getAGate() = other and
      (
        // // they act on the same register
        // // (if there is one explicitely instantiated)
        thisBitUse.getARegister() = otherBitUse.getARegister()
        or
        // or they act on the single quantum register of a circuit
        // experessed implicitely with e.g. QuantumCircuit(4)
        count(QuantumRegister reg | reg = circ.getAQuantumRegister() | reg) = 0 and
        circ.getNumberOfQubits() > 0
        or
        // or they act on the same quantum register but one uses the
        // integer only and the other uses the register object
        // this is unambiguous only with a single register
        // qc.h(0)
        // qc.x(qreg[0])
        count(QuantumRegister reg | reg = circ.getAQuantumRegister() | reg) = 1 and
        circ.getNumberOfQubits() > 0
      ) and
      // and they act on the same position
      // bind the qubit index
      thisBitUse.getAnIndex() = qubit_index and
      otherBitUse.getAnIndex() = qubit_index and
      // EXTRA PRECISION
      // they refer to the same circuit instance
      circNode = circ.getNode() and
      circNode.strictlyReaches(thisNode) and
      circNode.strictlyReaches(otherNode) and
      // we do not want a situation where the order is:
      // other >> initialization >> gate
      // because they would not refer to the same circuit anymore
      not otherNode.strictlyReaches(circNode)
    )
  }

  /** Holds if there is a path this gate to other gate via a different intermediate gate. */
  pragma[inline]
  predicate mayFollowVia(QuantumOperator other, QuantumOperator intermediate, int qubitIndex) {
    // case: other >> intermediate >> this
    // exclude case: other >> this >> intermediate
    // exclude case: intermediate >> other >> this
    // exclude (loop) case: this >> other >> intermediate >> this
    // they are all in the same file
    exists(File f |
      this.getLocation().getFile() = f and
      other.getLocation().getFile() = f and
      intermediate.getLocation().getFile() = f
      // and
      // qc.getLocation().getFile() = f
    ) and
    exists(
      ControlFlowNode thisNode, ControlFlowNode otherNode, ControlFlowNode intermediateNode,
      QuantumCircuit qc
    |
      // the control flow and the gates are connected
      thisNode = this.getNode() and
      otherNode = other.getNode() and
      intermediateNode = intermediate.getNode() and
      // they work on the same qubit
      qubitIndex = this.getATargetQubit() and
      qubitIndex = other.getATargetQubit() and
      qubitIndex = intermediate.getATargetQubit() and
      // they are in the same circuit
      qc = this.getQuantumCircuit() and
      qc = other.getQuantumCircuit() and
      qc = intermediate.getQuantumCircuit() and
      // they are connected
      otherNode.strictlyReaches(intermediateNode) and
      intermediateNode.strictlyReaches(thisNode) and
      // the intermediate gate is different from the start and target
      this != intermediate and
      other != intermediate
    )
    // this.isAppliedAfterOn(other, qubitIndex) and
    // this.isAppliedAfterOn(intermediate, qubitIndex) and
    // intermediate.isAppliedAfterOn(other, qubitIndex) and
    // // exclude: other >> this >> intermediate
    // not intermediate.isAppliedAfterOn(this, qubitIndex)
  }

  /** Holds if there is at least a path from this to other (both acting on same bit). */
  pragma[inline]
  predicate mayFollow(QuantumOperator other, int qubitIndex) { this.isAppliedAfterOn(other, qubitIndex) }

  /** Holds if all paths to this gate contain other (other is a dominator). */
  // pragma[inline]
  // predicate mustFollow(Gate other, int qubitIndex) {
  //   // TODO
  // }
  pragma[inline]
  predicate isAppliedAfter(QuantumOperator other) {
    exists(int qubit_index |
      qubit_index != -1 and
      this.isAppliedAfterOn(other, qubit_index)
    )
  }

  predicate isAppliedBefore(QuantumOperator other) { other.isAppliedAfter(this) }

  predicate isMeasurement() { this instanceof Measurement }

  /** Holds if this gate is unitary: e.g. h, x, y, z, cx, ccx, etc. */
  predicate isUnitary() { this.getGateName() instanceof OperatorSpecificationUnitary }

  /** Holds if this gate destroys the quantum state: e.g. measure, reset, measure_all */
  predicate destroysTheQuantumState() { this.getGateName() instanceof OperatorSpecificationNonUnitary }
}

private class GenericGateObj extends QuantumOperator {
  GenericGateObj() { isGateObj(this) }

  DataFlow::CallCfgNode getAppendCall() {
    exists(QuantumCircuit circ, DataFlow::CallCfgNode append_call |
      append_call = circ.getAnAttributeRead("append").getACall() and
      append_call.(API::CallNode).getParameter(0, "instruction").getAValueReachingSink() = this
    |
      result = append_call
    )
  }

  override string getGateName() {
    exists(QuantumCircuit circ, OperatorSpecificationObjectName a_supported_gate_name |
      // detect from qiskit.circuit.library import HGate
      this =
        API::moduleImport("qiskit")
            .getMember("circuit")
            .getMember("library")
            .getMember(a_supported_gate_name)
            .getACall() and
      // make sure that the gate is used in a circuit using the append()
      circ.getAnAttributeRead("append")
          .getACall()
          .(API::CallNode)
          .getParameter(0, "instruction")
          .getAValueReachingSink() = this
    |
      result = a_supported_gate_name
    )
    // result = this.(API::CallNode).getFunction().asVar().getName()
  }


  override QuantumCircuit getQuantumCircuit() {
    exists(QuantumCircuit circ |
      circ.getAnAttributeRead("append")
          .getACall()
          .(API::CallNode)
          .getParameter(0, "instruction")
          .getAValueReachingSink() = this
    |
      result = circ
    )
  }
  // /* get a target qubit of this gate */
  // override int getATargetQubit() {
  //     // qc.append(CXGate(), qargs=[0, 1])
  //     // returns either 0 or 1
  //     exists(
  //         List qargs
  //         |
  //         qargs = getAppendCall().(API::CallNode)
  //             .getParameter(1, "qargs").getAValueReachingSink().asExpr()
  //         |
  //         result = qargs.getAnElt().(IntegerLiteral).getValue()
  //     )
  //     or
  //     // qc.append(CXGate(), [qreg[0], qreg[1]])
  //     // returns either 0 or 1
  //     exists(
  //         List qargs
  //         |
  //         qargs = getAppendCall().(API::CallNode)
  //             .getParameter(1, "qargs").getAValueReachingSink().asExpr()
  //         |
  //         result = qargs.getAnElt().(Subscript).getIndex().(IntegerLiteral).getValue()
  //     )
  // }
}

private class GenericGateCall extends QuantumOperator {
  GenericGateCall() { isGateCall(this) }

  override string getGateName() {
    exists(QuantumCircuit circ, OperatorSpecificationAttributeName a_supported_gate_name |
      this = circ.getAnAttributeRead(a_supported_gate_name).getACall()
    |
      result = a_supported_gate_name
    )
  }


  override QuantumCircuit getQuantumCircuit() {
    exists(QuantumCircuit circ | this = circ.getAnAttributeRead(_).getACall() | result = circ)
  }

  // /* get a target qubit of this gate */
  // override int getATargetQubit() {
  //     // qc.cx(0, 1)
  //     // returns either 0 or 1
  //     exists(
  //         API::Node p, int i
  //         |
  //             isQubitParameter(p) and
  //             (
  //                 // qc.cx(0, 1)
  //                 p.getAValueReachingSink()
  //                     .asExpr().(IntegerLiteral).getValue() = i
  //                 or
  //                 // qc.cx(qreg[0], qreg[1])
  //                 p.getAValueReachingSink().asExpr().(Subscript)
  //                     .getIndex().(IntegerLiteral).getValue() = i
  //                 or
  //                 // qc.measure([0, 1], [0, 1])
  //                 p.getAValueReachingSink().asExpr().(List)
  //                     .getAnElt().(IntegerLiteral).getValue() = i
  //                 or
  //                 // qreg = QuantumRegister(5)
  //                 // qc.cx(qreg)
  //                 // > [0, 1, 2, 3, 4]
  //                 exists(QuantumRegisterV2 qreg
  //                 |
  //                   p.getAValueReachingSink().asExpr() = qreg.asExpr() and
  //                   i in [0, qreg.getSize() - 1]
  //                 |
  //                   result = i
  //                 )
  //             )
  //         |
  //         result = i
  //     )
  // }
  /* holds if the parameters at position i is a qubit parameter for this gate */
  predicate isQubitParameter(API::Node p) {
    (
      this.getGateName() = "cx" or
      this.getGateName() = "cz" or
      this.getGateName() = "cy" or
      this.getGateName() = "ch" or
      this.getGateName() = "cnot"
    ) and
    (
      this.(API::CallNode).getParameter(0, "control_qubit") = p
      or
      this.(API::CallNode).getParameter(1, "target_qubit") = p
    )
    or
    (this.getGateName() = "crz" or this.getGateName() = "crx" or this.getGateName() = "cry") and
    (
      this.(API::CallNode).getParameter(1, "control_qubit") = p
      or
      this.(API::CallNode).getParameter(2, "target_qubit") = p
    )
    or
    (this.getGateName() = "cu1" or this.getGateName() = "cp") and
    (
      this.(API::CallNode).getParameter(1, "control_qubit") = p
      or
      this.(API::CallNode).getParameter(2, "target_qubit") = p
    )
    or
    this.getGateName() = "cu3" and
    (
      this.(API::CallNode).getParameter(3, "control_qubit") = p
      or
      this.(API::CallNode).getParameter(4, "target_qubit") = p
    )
    or
    this.getGateName() = "cu" and
    (
      this.(API::CallNode).getParameter(4, "control_qubit") = p
      or
      this.(API::CallNode).getParameter(5, "target_qubit") = p
    )
    or
    (
      this.getGateName() = "h" or
      this.getGateName() = "x" or
      this.getGateName() = "y" or
      this.getGateName() = "z" or
      this.getGateName() = "s" or
      this.getGateName() = "sdg" or
      this.getGateName() = "t" or
      this.getGateName() = "tdg" or
      this.getGateName() = "measure"
    ) and
    this.(API::CallNode).getParameter(0, "qubit") = p
    or
    (
      this.getGateName() = "rx" or
      this.getGateName() = "ry" or
      this.getGateName() = "rz" or
      this.getGateName() = "u1" or
      this.getGateName() = "p"
    ) and
    this.(API::CallNode).getParameter(1, "qubit") = p
    or
    this.getGateName() = "u2" and
    this.(API::CallNode).getParameter(2, "qubit") = p
    or
    this.getGateName() = "u3" and
    this.(API::CallNode).getParameter(3, "qubit") = p
    or
    this.getGateName() = "u" and
    this.(API::CallNode).getParameter(3, "qubit") = p
    or
    this.getGateName() = "swap" and
    (
      this.(API::CallNode).getParameter(0, "qubit1") = p
      or
      this.(API::CallNode).getParameter(1, "qubit2") = p
    )
    or
    (this.getGateName() = "ccx" or this.getGateName() = "toffoli") and
    (
      this.(API::CallNode).getParameter(0, "control_qubit1") = p
      or
      this.(API::CallNode).getParameter(1, "control_qubit2") = p
      or
      this.(API::CallNode).getParameter(2, "target_qubit") = p
    )
    or
    this.getGateName() = "cswap" and
    (
      this.(API::CallNode).getParameter(0, "control_qubit") = p
      or
      this.(API::CallNode).getParameter(1, "target_qubit1") = p
      or
      this.(API::CallNode).getParameter(2, "target_qubit2") = p
    )
    or
    (
      this.getGateName() = "rxx" or
      this.getGateName() = "ryy" or
      this.getGateName() = "rzz" or
      this.getGateName() = "rzx"
    ) and
    (
      this.(API::CallNode).getParameter(1, "qubit1") = p
      or
      this.(API::CallNode).getParameter(2, "qubit2") = p
    )
    or
    this.getGateName() = "mct" and
    (
      this.(API::CallNode).getParameter(0, "control_qubits") = p
      or
      this.(API::CallNode).getParameter(1, "target_qubit") = p
      or
      this.(API::CallNode).getParameter(2, "ancilla_qubits") = p
    )
  }
}


/** A gate instruction (which is reversible). */
class Gate extends QuantumOperator {

  Gate() {
    this.isUnitary()
  }

  override string getGateName() {
    result = this.(GenericGateCall).getGateName()
    or
    result = this.(GenericGateObj).getGateName()
  }


  override QuantumCircuit getQuantumCircuit() {
    result = this.(GenericGateCall).getQuantumCircuit()
    or
    result = this.(GenericGateObj).getQuantumCircuit()
  }

}



/** A measurement instruction. */
abstract class Measurement extends QuantumOperator { }


class MeasureGateCall extends Measurement, GenericGateCall {
  MeasureGateCall() { this.getGateName() = "measure" }
}

class MeasureGateObj extends Measurement, GenericGateObj {
  MeasureGateObj() { this.getGateName() = "Measure" }
}

/** A measurement instruction on all qubits. */
class MeasurementAll extends Measurement, GenericGateCall {
  MeasurementAll() { this.getGateName() = "measure_all" }

  // TODO rename createsNewRegister
  predicate hasDefaultArgs() {
    not this.(API::CallNode)
        .getParameter(1, "add_bits")
        .getAValueReachingSink()
        .asExpr()
        .(ImmutableLiteral)
        .booleanValue() = false
  }
}


/** A reset instruction (brings it back to 0 state). */
abstract class Reset extends QuantumOperator { }

class ResetGateCall extends Reset, GenericGateCall {
  ResetGateCall() { this.getGateName() = "reset" }
}

class ResetGateObj extends Reset, GenericGateObj {
  ResetGateObj() { this.getGateName() = "Reset" }
}


