/**
 * @name Ghost from qasm
 * @description when a circuit is created from a qasm string
 * and the return value of the from_qasm_str() method is not store, then the
 * circuit is not used
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision high
 * @id ql-ghost-from-qasm
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit

from FromQasmStrCall fromQasmStrCall
where
  // PROBLEMATIC USAGE
  // the return value of the from_qasm_str() method is not stored
  // there is no assignment with it as value or subexpression of the value
  not exists(AssignStmt a | a.getValue().getASubExpression*() = fromQasmStrCall.asExpr()) and
  // INTENDED USAGE
  // the return value of the from_qasm_str() is not in a return statement
  not exists(Return r | r.getValue().(Expr).getASubExpression*() = fromQasmStrCall.asExpr())
select fromQasmStrCall,
  "Ghost from_qasm_str at location: (" + fromQasmStrCall.getLocation().getStartLine() + ", " +
    fromQasmStrCall.getLocation().getStartColumn() + ")"
