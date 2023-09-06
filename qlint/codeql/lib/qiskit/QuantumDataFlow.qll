import semmle.python.dataflow.new.DataFlow
import semmle.python.dataflow.new.TaintTracking
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.QuantumOperator

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
    QuantumCircuit circ, BitUse startBitUse, BitUse endBitUse, ControlFlowNode startNode,
    ControlFlowNode endNode, ControlFlowNode circNode
  |
    // they belong to the same circuit
    circ = start.getQuantumCircuit() and
    circ = end.getQuantumCircuit() and
    // they are connected to the control flow
    startNode = start.getNode() and
    endNode = end.getNode() and
    // they are applied in the right order: other >> this
    startNode.strictlyReaches(endNode) and
    // connect bit use and the two gates
    startBitUse.getAGate() = start and
    endBitUse.getAGate() = end and
    // and they act on the same position
    // bind the qubit index
    startBitUse.getAnIndex() = qubitIndex and
    endBitUse.getAnIndex() = qubitIndex and
    (
      // they act on the same register
      // (if there is one explicitely instantiated)
      startBitUse.getARegister() = endBitUse.getARegister()
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

bindingset[start, end, file, qubitIndex]
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
    intermediateNode.strictlyReaches(endNode) and
    // the intermediate gate is different from the start and target
    startNode != endNode
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
