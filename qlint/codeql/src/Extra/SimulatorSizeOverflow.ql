/**
 * @name Simulator size overflow.
 * @description Check if the circuit is larger than the supported simulator (e.g.  Aer.get_backend(’qasm_simulator’) supports max 30 qubits,  BasicAer.get_backend(’qasm_simulator’) supports max 24 qubits)
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision high
 * @id ql-simulator-size-overflow
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate
import qiskit.QuantumDataFlow
import qiskit.Backend

from Backend bkd, QuantumCircuit qc, int nQubits
where
  // the circuit is actually executed in the given backend
  bkd.getACircuitToBeRun() = qc and
  // the backend is a simulator
  (bkd.isStatevectorSimulator() or bkd.isUnitarySimulator()) and
  // bind the number of qubits
  nQubits = qc.getNumberOfQubits() and
  // the circuit is larger than the supported simulator
  nQubits > 30
select qc,
  "The circuit '" + qc.getName() + "' is larger (size: " + nQubits.toString() +
    " ) than the supported simulator (max is ca 30)."
