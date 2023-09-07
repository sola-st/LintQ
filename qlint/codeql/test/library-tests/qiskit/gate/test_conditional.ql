import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate
import qiskit.Qubit

from QuantumOperator op
where op.isConditional()
select op,
  "Operator in circuit: '" + op.getQuantumCircuit().getName() + "' on qubit: " +
    op.getATargetQubit() + " is applied conditionally based on register: '" +
    op.getAConditionRegister().getName() + "'."
// from
//   DataFlow::CallCfgNode cfgCall, Attribute attr, CallNode call, ExprStmt stmt, CallNode cifCall, ClassicalRegisterV2 creg,
//   DataFlow::CallCfgNode cifCfgCall
// where
//   cfgCall.getAnAttributeRead("c_if").asExpr() = attr and
//   cfgCall.getNode() = call
//   and
//   stmt = call.getNode().getParentNode+() and
//   cifCall.getNode() = call.getNode().getParentNode+() and
//   cifCfgCall.getNode() = cifCall and
//   cifCfgCall.(API::CallNode)
//     .getParameter(0, "classical")
//     .getAValueReachingSink() = creg
// select
//   call, attr, cfgCall, stmt, cifCall, cifCall.getAnArg(), creg
// from
//   // DataFlow::CallCfgNode call,
//   CallNode cifCall,
//   Value cif
//   // QuantumOperator op
// where
//   not cifCall.getLocation().getFile().getAbsolutePath().matches("%site-packages/qiskit/%")
//   and
//   cif.getName() = "len" and
//   cif.getACall() = cifCall
//   // and
//   // op.isConditional()
//   // cifCall.getAMethodCall("c_if")
//   // and
//   // cifCall.getAMethodCall("c_if").asExpr() = res
// select
// cifCall, cif
// select op,
//   "Operator in circuit: '" + op.getQuantumCircuit().getName() + "' on qubit: " +
//   op.getATargetQubit() + " is applied conditionally based on register: '" + op.getAConditionRegister().getName() + "'."
