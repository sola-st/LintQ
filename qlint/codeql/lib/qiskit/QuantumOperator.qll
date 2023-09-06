
// import python
// import semmle.python.dataflow.new.DataFlow
// import semmle.python.ApiGraphs
// import qiskit.Circuit
// import qiskit.BitUse
// import qiskit.QuantumDataFlow


// /** An Operator representing manipulation on a qubit, such as gates and measurements. */
// abstract class QuantumOperator extends DataFlow::CallCfgNode {

//   /** A bit use by the operator. */
//   // abstract BitUseNode getBitUse();
// }

// /** An Operator added with append. */
// class QuantumOperatorViaAppend extends QuantumOperator {
//   QuantumOperatorViaAppend() {
//     exists(QuantumCircuit circ, OperatorSpecificationObjectName name |
//       // detect from qiskit.circuit.library import HGate
//       this =
//         API::moduleImport("qiskit")
//             .getMember("circuit")
//             .getMember("library")
//             .getMember(name)
//             .getACall() and
//       // make sure that the gate is used in a circuit using the append()
//       this =
//         circ.getAnAttributeRead("append")
//           .getACall()
//           .(API::CallNode)
//           .getParameter(0, "instruction")
//           .getAValueReachingSink()
//     )
//   }

//   // override BitUseNode getBitUse() {
//   //   result = TBitUseAppend(this, nameOpObject)
//   // }
// }

// /** An Operator added with an attribute call. */
// class QuantumOperatorViaAttribute extends QuantumOperator {
//   QuantumOperatorViaAttribute() {
//     exists(QuantumCircuit circ, OperatorSpecificationAttributeName name |
//       // detect qc.h(0)
//       this = circ.getAnAttributeRead(name).getACall()
//     )
//   }
// }

