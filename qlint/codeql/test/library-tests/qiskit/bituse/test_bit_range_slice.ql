import python
import qiskit.BitUse
import qiskit.Circuit

from Slice slice, QuantumRegisterV2 qreg
where slice.getLocation().getFile().getAbsolutePath().matches("%concept_bit_range.py")
select slice, qreg.resolveSlice(slice)
// from Call range
// where range.getLocation().getFile().getAbsolutePath().matches("%concept_bit_range.py")
// select range, resolveRange(range)
// from QubitUse bu
// where
//   bu.getLocation().getFile().getAbsolutePath().matches("%concept_bit_range.py")
// select bu, bu.getAnAbsoluteIndex()
// from
//   Call call, Value functionValue, DataFlow::CallCfgNode callCfg, //int i,
//   IntegerLiteral iStart, DataFlow::LocalSourceNode sourceStart, DataFlow::Node sinkStart,
//   IntegerLiteral iEnd, DataFlow::LocalSourceNode sourceEnd, DataFlow::Node sinkEnd
// where
//   // LEFT
//   sourceStart.asExpr() = iStart and
//   sourceStart.flowsTo(sinkStart) and
//   call.getLocation().getFile().getAbsolutePath().matches("%concept_bit_range.py") and
//   // RIGHT
//   sourceEnd.asExpr() = iEnd and
//   sourceEnd.flowsTo(sinkEnd) and
//   call.getLocation().getFile().getAbsolutePath().matches("%concept_bit_range.py") and
//   // CALL
//   call.getLocation().getFile().getAbsolutePath().matches("%concept_bit_range.py") and
//   functionValue.getName() = "range" and
//   functionValue.getACall().getNode() = call and
//   callCfg.asExpr() = call and
//   //
//   (
//     call.getArg(0) = sinkStart.asExpr() and
//     call.getArg(1) = sinkEnd.asExpr()
//   )
// select
//   call, "Call to range with arguments: " + iStart.getValue() + ", " + iEnd.getValue()
