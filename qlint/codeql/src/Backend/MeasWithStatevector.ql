/**
 * @name Measurement in a circuit with statevector backend
 * @description a circuit with measurement is run on a statevector backend and then
 * the statevector is retrieved. This might lead to unexpected results in case
 * because the measurement will distrupt the statevector and what is observed is only
 * a possible outcome measreument.
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision medium
 * @id ql-meas-with-statevector
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate
import qiskit.Backend

from QuantumCircuit qc, Backend bkd, Measurement meas, BackendRunViaRunCall run, Statevector sv
where
  // connect backend and its circuit
  qc = bkd.getACircuitToBeRun() and
  // check that the backend is statevector
  bkd.isStatevectorSimulator() and
  // check that the circuit has measurement
  meas.getQuantumCircuit() = qc and
  // check that there is a get_statevector() call on the result of the run
  // the run is of the current backend
  run.getBackend() = bkd and
  // there is a statevector that was produced by this run
  sv.producedByBackendRun() = run and
  // the measurement is applied before the run
  meas.asCfgNode().strictlyReaches(run.asCfgNode())
select qc,
  "The circuit '" + qc.getName() + "' with measurement " + "(l: " +
    meas.getLocation().getStartLine() + ", " + "c: " + meas.getLocation().getStartColumn() + ") " +
    "is run on a statevector simulator backend " + "(l: " + bkd.getLocation().getStartLine() + ", " +
    "c: " + bkd.getLocation().getStartColumn() + ") " +
    " and then the statevector is retrieved. This might lead to unexpected results in case " +
    "because the measurement will distrupt the statevector and what is observed is only " +
    "a possible outcome measreument."
// from QuantumCircuit qc, Backend bkd, Initialize initInstr
// where
//   // connect backend and its circuit
//   qc = bkd.getACircuitToBeRun() and
//   // check that the initialize instruction is in the circuit
//   qc = initInstr.getQuantumCircuit() and
//   // check that there is no transpilation
//   not qc instanceof TranspiledCircuit
// select qc,
//   "The circuit '" + qc.getName() + "' with initialize() instruction " + "(l: " +
//     initInstr.getLocation().getStartLine() + ", " + "c: " + initInstr.getLocation().getStartColumn()
//     + ") " + "is directly run on a simulator backend " + "(l: " + bkd.getLocation().getStartLine() +
//     ", " + "c: " + bkd.getLocation().getStartColumn() + ") " +
//     " without transpilation. This may lead to a crash"
