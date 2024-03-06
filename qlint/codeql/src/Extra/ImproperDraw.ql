/**
 * @name ImproperDraw.
 * @description The draw function does not return a string, but it has to be used as is: e.g. replace print(qc.draw(output='mpl')) with qc.draw(output='mlp').
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision high
 * @id ql-improper-draw
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate
import qiskit.QuantumDataFlow
import qiskit.Backend

from QuantumCircuit qc, DataFlow::CallCfgNode drawCall, ExprStmt e, Call printCall, StrConst str
where
  // bind circuit and its call
  qc.getAnAttributeRead("draw").getACall() = drawCall and
  // bind s to be a print statement
  exists(Name n | printCall = e.getValue() and n = printCall.getFunc() and n.getId() = "print") and
  // they are in the same file
  drawCall.getNode().getLocation().getFile() = e.getLocation().getFile() and
  // the draw is called inside the print
  printCall.getArg(0).getASubExpression*() = drawCall.asExpr() and
  // make sure that there is the mpl string, which means the output is an image
  (drawCall.getArgByName("output").asExpr() = str and str.getText() = "mpl")
select drawCall,
  "The draw function does not return a string, but it has to be used as is: e.g. replace print(qc.draw(output='mpl')) with qc.draw(output='mlp')."
