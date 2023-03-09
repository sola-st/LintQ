/**
 * @name Pauli string syntax error
 * @description the pauli string can only be in the format [XYZI]+, whenever
 * they are not a runtime error is raised.
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision medium
 * @id ql-invalid-pauli-string
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Pauli


from
    PauliString pauliString
where
    not pauliString.isValid()
select
    pauliString, "Invalid Pauli string: " + pauliString + "."