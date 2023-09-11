/**
 * @name Initialize without transpilation
 * @description the circuit with initialize() instruction is directly run on a simulator backend
 * without transpilation.
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision medium
 * @id ql-init-without-transpilation
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate
import qiskit.Backend

from QuantumCircuit qc, Backend bkd, Initialize initInstr
where
  // connect backend and its circuit
  qc = bkd.getACircuitToBeRun() and
  // check that the initialize instruction is in the circuit
  qc = initInstr.getQuantumCircuit() and
  // check that there is no transpilation
  not qc instanceof TranspiledCircuit
select qc,
  "The circuit '" + qc.getName() + "' with initialize() instruction " + "(l: " +
    initInstr.getLocation().getStartLine() + ", " + "c: " + initInstr.getLocation().getStartColumn()
    + ") " + "is directly run on a simulator backend " + "(l: " + bkd.getLocation().getStartLine() +
    ", " + "c: " + bkd.getLocation().getStartColumn() + ") " +
    " without transpilation. This may lead to a crash"
