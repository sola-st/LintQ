import semmle.python.dataflow.new.DataFlow
import semmle.python.dataflow.new.TaintTracking
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.QuantumOperator


/** Holds if the second operator may follow the first one. */
bindingset[start, file]
pragma[inline]
predicate mayFollow(QuantumOperator start, QuantumOperator end, File file, int qubitIndex) {
  // they are in the same file
  start.getLocation().getFile() = file and
  end.getLocation().getFile() = file and
  // they belong to the same circuit
  start.getQuantumCircuit() = end.getQuantumCircuit() and
  // they are connected via the control flow
  exists(
    QuantumCircuit circ, QubitUse startBitUse, QubitUse endBitUse, ControlFlowNode startNode,
    ControlFlowNode endNode, ControlFlowNode circNode
  |
    // they belong to the same circuit
    circ = start.getQuantumCircuit() and
    circ = end.getQuantumCircuit() and
    // they are connected to the control flow
    startNode = start.getNode() and
    endNode = end.getNode() and
    // they are applied in the right order: start >> end
    startNode.strictlyReaches(endNode) and
    // connect bit use and the two gates
    startBitUse.getAGate() = start and
    endBitUse.getAGate() = end and
    // and they act on the same position
    // bind the qubit index
    startBitUse.getAnIndex() = qubitIndex and
    endBitUse.getAnIndex() = qubitIndex and
    // exclude undefined bit indices
    qubitIndex >= 0 and
    (
      // they act on the same register
      // (if there is one explicitely instantiated)
      startBitUse.getARegister() = endBitUse.getARegister()
      or
      // or they act on the single quantum register of a circuit
      // experessed implicitely with e.g. QuantumCircuit(4)
      count(QuantumRegisterV2 reg | reg = circ.getAQuantumRegister() | reg) = 0 and
      circ.getNumberOfQubits() > 0
      or
      // or they act on the same quantum register but one uses the
      // integer only and the other uses the register object
      // this is unambiguous only with a single register
      // qc.h(0)
      // qc.x(qreg[0])
      count(QuantumRegisterV2 reg | reg = circ.getAQuantumRegister() | reg) = 1 and
      circ.getNumberOfQubits() > 0
    ) and
    // EXTRA PRECISION
    // they refer to the same circuit instance
    circNode = circ.getNode() and
    circNode.strictlyReaches(startNode) and
    circNode.strictlyReaches(endNode) and
    // we do not want a situation where the order is:
    // other >> initialization >> gate
    // because they would not refer to the same circuit anymore
    not startNode.strictlyReaches(circNode)
  )
}

/** Holds if the two operators refer to the same qubit. */
bindingset[opA, file]
pragma[inline]
predicate manipulateSameQubit(QuantumOperator opA, QuantumOperator opB, QuantumCircuit qc, int i, File file) {
  exists(
    QubitUse qbuA, QubitUse qbuB
  |
    // they are in the same file
    opA.getLocation().getFile() = file and
    opB.getLocation().getFile() = file and
    // they belong to the same circuit
    opA.getQuantumCircuit() = qc and
    opB.getQuantumCircuit() = qc and
    // connect bit use and the two gates
    qbuA.getAGate() = opA and
    qbuB.getAGate() = opB and
    // and they act on the same position (qubit index)
    qbuA.getAnIndex() = i and
    qbuB.getAnIndex() = i and
    // exclude undefined bit indices
    i >= 0 and
    (
      // they act on the same register
      // (if there is one explicitely instantiated)
      qbuA.getARegister() = qbuB.getARegister()
      or
      // or they act on the single quantum register of a circuit
      // experessed implicitely with e.g. QuantumCircuit(4)
      count(QuantumRegisterV2 reg | reg = qc.getAQuantumRegister() | reg) = 0 and
      qc.getNumberOfQubits() > 0
      or
      // or they act on the same quantum register but one uses the
      // integer only and the other uses the register object
      // this is unambiguous only with a single register
      // qc.h(0)
      // qc.x(qreg[0])
      count(QuantumRegisterV2 reg | reg = qc.getAQuantumRegister() | reg) = 1 and
      qc.getNumberOfQubits() > 0
    )
  )
}

/** Holds if the three operators refer to the same qubit. */
bindingset[opA, opB, opC, file, i]
pragma[inline]
predicate manipulateSameQubit(QuantumOperator opA, QuantumOperator opB, QuantumOperator opC, QuantumCircuit qc, int i, File file) {
  manipulateSameQubit(opA, opB, qc, i, file) and
  manipulateSameQubit(opB, opC, qc, i, file)
}


/** Holds if the second operator may DIRECTLY follow the first one (with no operators in between). */
bindingset[start, file]
pragma[inline]
predicate mayFollowDirectly(QuantumOperator start, QuantumOperator end, File file, int qubitIndex) {
  // mayFollow(start, end, file, qubitIndex) and
  // // check that they are immiatelly consecutive
  // not exists(QuantumOperator other |
  //   sortedInOrder(start, other, end, file, qubitIndex)
  // )
  exists(
    ControlFlowNode startNode,
    ControlFlowNode endNode,
    ControlFlowNode circNode,
    QuantumCircuit qc
  |
    startNode = start.getNode() and
    endNode = end.getNode() and
    circNode = qc.getNode() and
    // they all refer to the same qubit
    manipulateSameQubit(start, end, qc, qubitIndex, file) and
    // they are connected: start > end
    startNode.strictlyReaches(endNode) and
    // there is nothing in between
    not exists(
      QuantumOperator intermediate,
      ControlFlowNode intermediateNode
    |
      intermediateNode = intermediate.getNode() and
      // the node must be different from both at the same time
      intermediateNode != startNode and
      intermediateNode != endNode and
      // they all refer to the same qubit
      manipulateSameQubit(start, intermediate, end, qc, qubitIndex, file) and
      // such that it is between start and end
      startNode.strictlyReaches(intermediateNode) and
      intermediateNode.strictlyReaches(endNode)
    ) and
    // EXTRA PRECISION
    // they refer to the same circuit instance
    circNode.strictlyReaches(startNode) and
    circNode.strictlyReaches(endNode) and
    // we do not want a situation where the order is:
    // start >> initialization >> end
    // because they would not refer to the same circuit anymore
    not startNode.strictlyReaches(circNode)
  )
}


bindingset[start, intermediate, end, file, qubitIndex]
pragma[inline]
predicate sortedInOrder(
  QuantumOperator start, QuantumOperator intermediate, QuantumOperator end, File file,
  int qubitIndex
) {
  // they are in the same file
  start.getLocation().getFile() = file and
  intermediate.getLocation().getFile() = file and
  end.getLocation().getFile() = file and
  // they are in the same function
  // case: other >> intermediate >> this
  // exclude case: other >> this >> intermediate
  // exclude case: intermediate >> other >> this
  // exclude (loop) case: this >> other >> intermediate >> this
  // they are all in the same file
  exists(
    ControlFlowNode startNode, ControlFlowNode intermediateNode, ControlFlowNode endNode,
    QuantumCircuit qc
  |
    // the control flow and the gates are connected
    startNode = start.getNode() and
    intermediateNode = intermediate.getNode() and
    endNode = end.getNode() and
    // they work on the same qubit
    qubitIndex = start.getATargetQubit() and
    qubitIndex = intermediate.getATargetQubit() and
    qubitIndex = end.getATargetQubit() and
    // they are in the same circuit
    qc = start.getQuantumCircuit() and
    qc = intermediate.getQuantumCircuit() and
    qc = end.getQuantumCircuit() and
    // they are connected
    startNode.strictlyReaches(intermediateNode) and
    intermediateNode.strictlyReaches(endNode)
  )
}
// /** A node representing a use of a qubit in a DAG. */
// newtype TBitUseNode =
//   TBitUseAppend(QuantumOperatorViaAppend op, AppendCall appendCall, QuantumCircuit circ, OperatorSpecificationObjectName name, DataFlow::Node bitUse) {
//     op =
//       API::moduleImport("qiskit")
//           .getMember("circuit")
//           .getMember("library")
//           .getMember(name)
//           .getACall()
//     and
//     appendCall =
//       circ.getAnAttributeRead("append")
//         .getACall()
//     and
//     op = appendCall
//       .(API::CallNode)
//       .getParameter(0, "instruction")
//       .asSink()
//       // .getAValueReachingSink()
//     and
//     bitUse =
//       appendCall
//       .(API::CallNode)
//       .getParameter(1, "qargs")
//       .asSink()
//       // .getAValueReachingSink()
//   }
//   or
//   TBitUseAttribute(QuantumOperatorViaAttribute op, OperatorSpecificationAttributeName name) {
//     exists(QuantumCircuit circ |
//       // detect qc.h(0)
//       op = circ.getAnAttributeRead(name).getACall()
//     )
//   }
// /** A node representing a use of a qubit in a DAG. */
// class BitUseNode extends TBitUseNode {
//   // case: qc.append(HGate(), [0]) >> HGate
//   QuantumOperatorViaAppend opAppend;
//   OperatorSpecificationObjectName nameOpObject;
//   // case: qc.h(0) >> h
//   QuantumOperatorViaAttribute opAttribute;
//   OperatorSpecificationAttributeName nameOpAttribute;
//   string toString() {
//     this instanceof TBitUseAppend and
//     result = nameOpObject
//     or
//     this instanceof TBitUseAttribute and
//     result = nameOpAttribute
//   }
// }
