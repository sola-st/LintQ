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
}
