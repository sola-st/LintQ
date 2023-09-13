import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Register
import qiskit.Gate
import qiskit.Circuit

/** Simulator backend. */
class Backend extends DataFlow::CallCfgNode {
  // case: from qiskit import Aer; Aer.get_backend('qasm_simulator')
  Backend() {
    this = API::moduleImport("qiskit").getMember("Aer").getMember("get_backend").getACall() or
    this = API::moduleImport("qiskit").getMember("BasicAer").getMember("get_backend").getACall()
  }

  /** The name of the backend (according to the initialization string). */
  string getKind() {
    // case: from qiskit import Aer; Aer.get_backend('qasm_simulator')
    // > 'qasm_simulator'
    exists(StrConst str, DataFlow::LocalSourceNode strSource |
      strSource = this.getArg(0) and
      strSource.asExpr() = str
    |
      result = str.getText()
    )
  }

  /** If the simulator is statevector simulator. */
  predicate isStatevectorSimulator() {
    // case: from qiskit import Aer; Aer.get_backend('statevector_simulator')
    this.getKind().matches("%statevector%")
  }

  /** If the simulator is Unitary simulator. */
  predicate isUnitarySimulator() {
    // case: from qiskit import Aer; Aer.get_backend('unitary_simulator')
    this.getKind().matches("%unitary%")
  }

  /** Get a circuit run with this backend. */
  QuantumCircuit getACircuitToBeRun() {
    // case: Aer.get_backend('qasm_simulator').run(circuit)
    // > circuit
    exists(QuantumCircuit circuit, DataFlow::CallCfgNode runCall |
      runCall = this.getAnAttributeRead("run").getACall() and
      (
        circuit.flowsTo(runCall.getArg(0)) or
        circuit.flowsTo(runCall.getArgByName("circuits"))
      )
    |
      result = circuit
    )
    or
    // case: execute(qc, Aer.get_backend('qasm_simulator'), shots=1)
    // > qc
    exists(QuantumCircuit circuit, ExecuteCall executeCall |
      (
        circuit.flowsTo(executeCall.getArg(0)) or
        circuit.flowsTo(executeCall.getArgByName("experiments"))
      ) and
      (
        this.flowsTo(executeCall.getArg(1)) or
        this.flowsTo(executeCall.getArgByName("backend"))
      )
    |
      result = circuit
    )
  }

  /** Get a backend run with this backend. */
  BackendRun getABackendRun() {
    exists(BackendRun bkdRun |
      bkdRun.getBackend() = this
    |
      result = bkdRun
    )
  }

}

/** Backend run.
 *
 * This is a call to a backend run method.
 */
abstract class BackendRun extends DataFlow::CallCfgNode {

  abstract Backend getBackend();

}

/** A call to a backend run method. */
class BackendRunViaRunCall extends BackendRun {
  BackendRunViaRunCall() {
    exists(Backend backend, DataFlow::CallCfgNode runCall |
      runCall = backend.getAnAttributeRead("run").getACall()
    |
      this = runCall
    )
  }

  /** The backend that is run. */
  override Backend getBackend() {
    exists(Backend backend, DataFlow::CallCfgNode runCall |
      runCall = backend.getAnAttributeRead("run").getACall()
    |
      result = backend
    )
  }
}

/** A call to a backend execute method. */
class BackendRunViaExecuteCall extends BackendRun {
  BackendRunViaExecuteCall() {
    this instanceof ExecuteCall
  }

  /** The backend that is run. */
  override Backend getBackend() {
    exists(Backend backend |
      (
        backend.flowsTo(this.getArg(1)) or
        backend.flowsTo(this.getArgByName("backend"))
      )
    |
      result = backend
    )
  }
}

/** Result of a simulator run. */
class BackendResult extends DataFlow::CallCfgNode {
  BackendResult() {
    exists(BackendRun bkdRun |
      this = bkdRun.getAnAttributeRead("result").getACall()
      or
      this = bkdRun.getAnAttributeReference("result")
      or
      this = bkdRun.getAnAttributeWrite("result")
    )
  }

  /** The backend run that generated this result. */
  BackendRun getBackendRun() {
    exists(BackendRun bkdRun |
      // connect the run and its result
      this = bkdRun.getAnAttributeRead("result").getACall() or
      this = bkdRun.getAnAttributeReference("result") or
      this = bkdRun.getAnAttributeWrite("result")
    |
      result = bkdRun
    )
  }

}


/** Statevector returned by a result of a simulator run. */
class Statevector extends DataFlow::CallCfgNode {
  Statevector() {
    exists(BackendResult bkdResult |
      this = bkdResult.getAnAttributeRead("get_statevector").getACall()
    )
  }

  /** The backend run that generated this statevector. */
  BackendRun producedByBackendRun() {
    exists(BackendResult bkdResult, BackendRun bkdRun |
      // connect the run and its result
      bkdResult.getBackendRun() = bkdRun and
      // the result has been called to extract the statevector
      this = bkdResult.getAnAttributeRead("get_statevector").getACall()
    |
      result = bkdRun
    )
  }

}