import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.NoiseModel


class PauliString extends StrConst {
    PauliString() {
        // it can be used in a PauliError
        exists(
            PauliError pauliError
            |
            pauliError.getPauliString() = this
        )
        or
        // it can be used in a Pauli object
        exists(
            DataFlow::CallCfgNode pauliObject
            |
            pauliObject = API::moduleImport("qiskit").getMember("circuit")
                        .getMember("QuantumCircuit").getMember("pauli").getACall()
            or
            // from qiskit.quantum_info import Pauli
            pauliObject = API::moduleImport("qiskit").getMember("quantum_info")
                        .getMember("Pauli").getACall()
            |
            this = pauliObject.getArg(0).asCfgNode().getNode()
        )
    }

    /** Check if the Pauli satisfy the regex ^[+-]?1?[ij]?[IXYZ]+$ */
    predicate isValid() {
        this.getText().regexpMatch("^[+-]?1?[ij]?[IXYZ]+$")
    }

}