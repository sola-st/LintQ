/**
 * @name No alignment between logical and physical qubits.
 * @description Find transpile call without initial_layout parameter.
 * @kind problem
 * @tags maintainability
 *       efficiency
 *       qiskit
 * @problem.severity warning
 * @precision medium
 * @id qsmell-lpq
 */

import python
import qiskit.Circuit
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs


from
    DataFlow::CallCfgNode transpileCall
where
    transpileCall = API::moduleImport("qiskit").getMember("transpile").getACall()
    and
    not exists(
        transpileCall.getArgByName("initial_layout")
    )
select
transpileCall, "transpile call without initial_layout"
