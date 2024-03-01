/**
 * @name Ghost QASM import.
 * @description Check that the QuantumCircuit.from_qasm_str return value is assigned to a quantum circuit.
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision high
 * @id ql-ghost-qasm-import
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate
import qiskit.QuantumDataFlow
import qiskit.Backend

from QuantumCircuit qc, DataFlow::CallCfgNode qasmImportCall
where
  // bind circuit and its call
  qc.getAnAttributeRead("from_qasm_str").getACall() = qasmImportCall
  and
  // the return value of the from_qasm_str() method is not stored
  not exists(AssignStmt a | a.getValue().getASubExpression*() = qasmImportCall.asExpr()) and
  // the return value of the from_qasm_str() is not in a return statement
  not exists(Return r | r.getValue().(Expr).getASubExpression*() = qasmImportCall.asExpr()) and
  // the value is not in a function call
  // qc.append(qc.from_qasm_str(qasm_str))
  not exists(CompositionCall c | c.getArg(0).asExpr() = qasmImportCall.asExpr())
select qasmImportCall, "The return value of the from_qasm_str() method is not stored."
