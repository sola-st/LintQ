/**
 * @name Transpile Without Layout
 * @description Check if the transpile call had no initial_layout parameter when a non-simulator backend is used
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision high
 * @id ql-transpile-without-layout
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate
import qiskit.QuantumDataFlow
import qiskit.Backend

from TranspileCall transpileCall
where
  // there is no backend
  not exists(DataFlow::Node parameterBackend |
    parameterBackend = transpileCall.getArgByName("backend")
  ) and
  // there is no initial_layout
  not exists(DataFlow::Node parameterInitialLayout |
    parameterInitialLayout = transpileCall.getArgByName("initial_layout")
  )
select transpileCall,
  "The transpile call had no initial_layout parameter when a non-simulator backend is used."
