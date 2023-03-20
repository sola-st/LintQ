
import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs


class PauliError extends DataFlow::CallCfgNode {

    PauliError() {
        // OLDER API
        // from qiskit.providers.aer.noise.errors import pauli_error
        this = API::moduleImport("qiskit").getMember("providers")
            .getMember("aer").getMember("noise").getMember("errors")
            .getMember("pauli_error").getACall()
        or
        // NEWER API
        this = API::moduleImport("qiskit_aer").getMember("noise")
            .getMember("pauli_error").getACall()
    }

    StrConst getPauliString() {
        // pauli_error([('XY', p), ('I', 1 - p)])
        // extract 'XY' and 'I'
        exists(
            StrConst strConst
            |
            this.getArg(0).asCfgNode().getNode().contains(strConst)
            |
            result = strConst
            )
    }

    /** Check that the Pauli String are of different size.*/
    predicate arePauliStringSameSize() {
        // pauli_error([('XY', p), ('I', 1 - p)])
        // extract 'XY' and 'I'
        not exists(
            string str1, string str2
            |
            this.getPauliString().getText() = str1
            and
            this.getPauliString().getText() = str2
            |
            str1.length() != str2.length()
            )
    }


}
