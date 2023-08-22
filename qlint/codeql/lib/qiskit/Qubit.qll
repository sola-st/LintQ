
// import qiskit.Circuit
// import qiskit.Register
// import tutorial
// // QubitUsed
// // derived from a Quantum gate used and its argument
// // implicitely connected to a default QuantumRegister via an index
// // e.g. qc.h(0)
// // or explicitely connected to a QuantumRegister via quantum_register[0]
// // e.g. qc.h(quantum_register[0])
// // TODO rename QubitAccess
// class QubitUsedInteger extends IntegerLiteral {
//     QubitUsedInteger() {
//         exists(
//             Gate gate
//             |
//             this = gate.getATargetQubit()
//         )
//     }
//     Gate getGate() {
//         exists(
//             Gate gate
//             |
//             this = gate.getATargetQubit()
//             |
//             result = gate
//         )
//     }
//     int getQubitIndex() {
//         result = this.getValue()
//     }
//     QuantumRegister getQuantumRegister() {
//         // OLD
//         // exists(
//         //     QuantumCircuit circ, QuantumRegister qr
//         //     |
//         //     circ = this.getGate().getQuantumCircuit() and
//         //     qr = circ.getAQuantumRegister() and
//         //     count(QuantumRegister reg | reg = circ.getAQuantumRegister() | reg) = 1
//         //     |
//         //     result = qr
//         // )
//         // or
//         exists(
//             QuantumRegister qr, SubscriptNode subscr
//             |
//             qr.getVar().getAUse() = subscr.getObject()
//             and
//             this = subscr.getNode().getIndex()
//             |
//             result = qr
//         )
//         // NEW
//         // exists(
//         //     QuantumRegister qr,
//         //     QuantumCircuit circ,
//         //     Gate gate
//         //     |
//         //     // this qubit is used in a gate
//         //     this = gate.getATargetQubit()
//         //     // the register belongs to the circuit
//         //     and circ.getAQuantumRegister() = qr
//         //     // the gate belongs to the circuit
//         //     and circ = gate.getQuantumCircuit()
//         //     and (
//         //         // either it is the only register in the circuit
//         //         // count(circ.getAQuantumRegister()) = 1
//         //         // or
//         //         (
//         //             exists(
//         //                 SubscriptNode subscr
//         //                 |
//         //                 // or we look for the register variable which
//         //                 // is used to access the qubit (IntegerLiteral)
//         //                 qr.getVar().getAUse() = subscr.getObject()
//         //                 and this = subscr.getNode().getIndex()
//         //             )
//         //         )
//         //     )
//         //     |
//         //     result = qr
//         // )
//     }
// }
// QubitUsed
// derived from a Quantum gate used and its argument
// implicitely connected to a default QuantumRegister via an index
// e.g.  qc.h(0)
// or explicitely connected to a QuantumRegister via quantum_register[0]
// e.g. qc.h(quantum_register[0])
// .(Subscript).getIndex().(IntegerLiteral).getValue() = i
// class QubitUsed extends SubscriptNode {
//     // get a quantum register node which is used in a quantum gate
//     // qc.h(quantum_register[0])
//     QubitUsed() {
//         exists(
//             QuantumRegister qr, Variable reg_var
//             |
//             qr.getVar() = reg_var
//             and
//             reg_var.getAUse() = this.getObject()
//         ) or
//         exists(
//             QuantumRegister qr, Variable reg_var
//             |
//             qr.getVar() = reg_var
//             and
//             reg_var.getAUse() = this.getObject()
//         )
//     }
//     // get the index of the qubit used in the quantum gate
//     // qc.h(quantum_register[0])
//     int getQubitIndex() {
//         exists(
//             IntegerLiteral index
//             |
//             index = this.getNode().getIndex()
//             |
//             result = index.getValue()
//         )
//     }
//     QuantumRegister getQuantumRegister() {
//         exists(
//             QuantumRegister qr
//             |
//             qr.getVar().getAUse() = this.getObject()
//             |
//             result = qr
//         )
//     }
// }
// QubitSpace
// derived from a QuantumRegister declaration used in a QuantumCircuit
// e.g. quantum_register = QuantumRegister(2)
// Detector improvements
// find if there is any register with QubitSpace that is not used in any QubitUsed
