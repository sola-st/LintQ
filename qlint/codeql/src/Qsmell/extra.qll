import python
import semmle.python.ApiGraphs
import semmle.python.dataflow.new.DataFlow
import qiskit.Circuit


/** Any method call named execute or run */
class ExecuteOrRunCalls extends Function {
    ExecuteOrRunCalls() {
        this.getName() = "execute" or this.getName() = "run"
    }
}

// create an object for
// from qiskit import execute
// from qiskit import Aer
// backend = Aer.get_backend('qasm_simulator').run(circuit, shots=1024)
class CircuitExecution extends DataFlow::CallCfgNode {
    CircuitExecution() {
        // detect execute(circuit, backend, shots=1024)
        this = API::moduleImport("qiskit").getMember("execute").getACall()
        or
        // detect Aer.get_backend('qasm_simulator').run(circuit, shots=1024)
        exists (
            DataFlow::CallCfgNode backend
            |
            backend = API::moduleImport("qiskit").getMember("Aer").getMember("get_backend").getACall()
            and this = backend.getAnAttributeRead("run").getACall()
        )
    }

    QuantumCircuit getQuantumCircuit() {
        exists(
            QuantumCircuit circ
            |
            // detect execute(circuit, backend, shots=1024)
            this = API::moduleImport("qiskit").getMember("execute").getACall()
            and this.getArg(0) = circ
            |
            result = circ
        )
        or
        exists(
            QuantumCircuit circ
            |
            // detect Aer.get_backend('qasm_simulator').run(circuit, shots=1024)
            exists (
                DataFlow::CallCfgNode backend
                |
                backend = API::moduleImport("qiskit").getMember("Aer").getMember("get_backend").getACall()
                and this = backend.getAnAttributeRead("run").getACall()
            )
            and this.getArg(0) = circ
            |
            result = circ
        )
    }
}