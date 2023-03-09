/**
 * @name Invalid Pauli String Noise Model
 * @description the pauli string used for the noise model must be of
 * the same length.
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision medium
 * @id ql-invalid-pauli-size-error
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.NoiseModel


from
    PauliError pauliError
where
    pauliError.arePauliStringsSizeIncompatible()
select
    pauliError, "Invalid noise nodel: different size of Pauli strings."