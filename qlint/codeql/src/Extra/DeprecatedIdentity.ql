/**
 * @name Deprecated Identity
 * @description Check if the deprecated iden() API is called instead of the identity()
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision high
 * @id ql-deprecated-identity
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate
import qiskit.QuantumDataFlow
import qiskit.Backend

from QuantumCircuit qc, DataFlow::CallCfgNode idenCall
where qc.getAnAttributeRead("iden").getACall() = idenCall
select idenCall, "The deprecated iden() API is called."
