/**
 * @name Ghost Composition.
 * @description when two circuits are composed but the inplace=True is not used
 * and the return value of the compose() method is not store, then the
 * composed circuit is lost.
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision high
 * @id ql-ghost-composition
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit

from ComposeCall composeCall
where
  // PROBLEMATIC PATTERN
  // check that the compose has argument inplace=False or inplace is not present
  // e.g. mother_circuit.compose(sub_circuit, inplace=False)
  composeCall instanceof ReturnsNewValue and
  // INTENDED USAGE PATTERN
  // the return value of the compose() method is not stored
  // there is no assignment with it as value or subexpression of the value
  not exists(AssignStmt a | a.getValue().getASubExpression*() = composeCall.asExpr()) and
  // the return value of the compose() is not in a return statement
  not exists(Return r | r.getValue().(Expr).getASubExpression*() = composeCall.asExpr())
select composeCall,
  "Ghost composition at location: (" + composeCall.getLocation().getStartLine() + ", " +
    composeCall.getLocation().getStartColumn() + ")"
