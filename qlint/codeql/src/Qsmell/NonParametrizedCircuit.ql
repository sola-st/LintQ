/**
 * @name Non-Parametrized Circuit.
 * @description Finds circuits which are send for execution one at the time,
 * thus increasing the communication payload with the server
 * @kind problem
 * @tags maintainability
 *       efficiency
 *       qiskit
 * @problem.severity warning
 * @precision medium
 * @id qsmell-nc
 */

import python
import qiskit.Circuit
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs


class BindParameters extends DataFlow::CallCfgNode {
    BindParameters() {
        exists(QuantumCircuit circ, string function_call_name |
            // detect qc.bind_parameters(parameters)
            this = circ.getAnAttributeRead(function_call_name).getACall()
            and function_call_name = "bind_parameters"
        )
    }
}


/** Any method call named execute or run */
class ExecuteOrRunCalls extends Call {
    ExecuteOrRunCalls() {
        this.getFunc().(Attribute).getName() = "execute" or this.getFunc().(Attribute).getName() = "run"
    }
}


from
    File f
where
    // they are both used and the exec is used more often
    (
        count(ExecuteOrRunCalls exec | f = exec.getLocation().getFile()) -
        count(BindParameters bind | f = bind.getLocation().getFile()) > 0
    )
    or
    // only the exec is used
    (
        count(ExecuteOrRunCalls exec | f = exec.getLocation().getFile()) > 0 and
        not exists(BindParameters bind | f = bind.getLocation().getFile())
    )
select
    f, "The file has " + count(ExecuteOrRunCalls exec | f = exec.getLocation().getFile()
    ) + " execute or run calls, and a lower number of bind_parameters calls."
