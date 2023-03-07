

import qiskit.Circuit


// QubitUsed
// derived from a Quantum gate used and its argument
// implicitely connected to a default QuantumRegister via an index
// e.g. qc.h(0)
// or explicitely connected to a QuantumRegister via quantum_register[0]
// e.g. qc.h(quantum_register[0])
// .(Subscript).getIndex().(IntegerLiteral).getValue() = i
class QubitUsed extends SubscriptNode {
    // get a quantum register node which is used in a quantum gate
    // qc.h(quantum_register[0])
    QubitUsed() {
        exists(
            QuantumRegister qr, Variable reg_var
            |
            qr.getVar() = reg_var
            and
            reg_var.getAUse() = this.getObject()
        )
    }


    // get the index of the qubit used in the quantum gate
    // qc.h(quantum_register[0])
    int getQubitIndex() {
        exists(
            IntegerLiteral index
            |
            index = this.getNode().getIndex()
            |
            result = index.getValue()
        )
    }

    QuantumRegister getQuantumRegister() {
        exists(
            QuantumRegister qr
            |
            qr.getVar().getAUse() = this.getObject()
            |
            result = qr
        )
    }


}


// QubitSpace
// derived from a QuantumRegister declaration used in a QuantumCircuit
// e.g. quantum_register = QuantumRegister(2)


// Detector improvements
// find if there is any register with QubitSpace that is not used in any QubitUsed