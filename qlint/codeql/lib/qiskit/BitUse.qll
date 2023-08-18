import qiskit.Circuit
import qiskit.Register
import semmle.python.dataflow.new.DataFlow
import semmle.python.dataflow.new.TaintTracking
import semmle.python.ApiGraphs

class EmptySetForString extends string {
  EmptySetForString() {
    this = "a" and this = "b" // this returns the empty set
  }
}

class EmptySetForInt extends int {
  EmptySetForInt() {
    this = 1 and this = 2 // this returns the empty set
  }
}

class EmptySetForRegisterV2 extends RegisterV2 {
  EmptySetForRegisterV2() {
    this.getName() != this.getName() // this returns the empty set
  }
}

class EmptySetForQuantumCircuit extends QuantumCircuit {
  EmptySetForQuantumCircuit() {
    this.getName() != this.getName() // this returns the empty set
  }
}

/** Usage of a qubit or bit. */
abstract class BitUse extends DataFlow::LocalSourceNode {
  int getAnIndex() {
    if exists(int i | i = this.getAnIndexIfAny())
    then exists(int i | i = this.getAnIndexIfAny() | result = i)
    else result = -1
  }

  string getARegisterName() {
    if exists(RegisterV2 reg | reg = this.getARegister())
    then exists(RegisterV2 reg | reg = this.getARegister() | result = reg.getName())
    else result = "anonymous register"
  }

  string getACircuitName() {
    if exists(QuantumCircuit circ | circ = this.getACircuit())
    then exists(QuantumCircuit circ | circ = this.getACircuit() | result = circ.getName())
    else result = "anonymous circuit"
  }

  abstract int getAnIndexIfAny();

  abstract RegisterV2 getARegister();

  abstract QuantumCircuit getACircuit();

  abstract string getAGateName();

  boolean equals(BitUse other) {
    if
      this.getARegisterName() = other.getARegisterName() and
      this.getAnIndexIfAny() = other.getAnIndexIfAny() and
      this.getACircuitName() = other.getACircuitName() and
      this.getARegister() = other.getARegister() and
      this.getACircuit() = other.getACircuit()
    then result = true
    else result = false
  }
}

/** Use of a qubit. */
abstract class QubitUse extends BitUse {
  override int getAnIndexIfAny() {
    // case: qc.h(0)
    // > 0
    // case: qc.h(quantum_register[7])
    // > 7
    if
      exists(IntegerLiteral lit, DataFlow::LocalSourceNode litSource |
        not this.asExpr() instanceof Subscript and
        litSource.asExpr() = lit and
        litSource.flowsTo(this)
      )
    then
      exists(IntegerLiteral lit, DataFlow::LocalSourceNode litSource |
        not this.asExpr() instanceof Subscript and
        litSource.asExpr() = lit and
        litSource.flowsTo(this)
      |
        result = lit.getValue()
      )
    else
      if exists(QuantumRegisterV2 qreg | qreg = this.getARegister())
      then
        // case: qc.h(quantum_register) with quantum_register = QuantumRegister(2)
        // > [0, 1]
        if exists(RegisterV2 reg | reg.flowsTo(this))
        then
          exists(RegisterV2 reg, int i |
            reg.flowsTo(this) and
            i in [0 .. reg.getSize() - 1]
          |
            result = i
          )
        else
          exists(
            QuantumRegisterV2 qreg, IntegerLiteral lit, DataFlow::LocalSourceNode litSource,
            DataFlow::LocalSourceNode indexDest
          |
            qreg = this.getARegister() and
            litSource.asExpr() = lit and
            indexDest.asExpr() = this.asExpr().(Subscript).getIndex() and
            litSource.flowsTo(indexDest)
          |
            result = lit.getValue()
          )
      else result instanceof EmptySetForInt
  }

  override RegisterV2 getARegister() {
    // case: qc.h(0)
    // > EmptySetForRegisterV2
    // case: qc.h(quantum_register[7])
    // > quantum_register
    // case: qc.h(quantum_register)
    // > quantum_register
    if
      exists(RegisterV2 reg |
        reg.getScope() = this.getScope() and
        reg.getName() = this.asExpr().(Subscript).getObject().toString()
      )
    then
      exists(RegisterV2 reg |
        reg.getScope() = this.getScope() and
        reg.getName() = this.asExpr().(Subscript).getObject().toString()
      |
        result = reg
      )
    else
      if exists(RegisterV2 reg | reg.flowsTo(this))
      then exists(RegisterV2 reg | reg.flowsTo(this) | result = reg)
      else result instanceof EmptySetForRegisterV2
  }
}

/** Use of a clbit. */
abstract class ClbitUse extends BitUse { }

/** Use of a qubit as attribute call on the circuit object. */
class QubitUseViaAttribute extends QubitUse {
  QubitUseViaAttribute() {
    exists(
      QuantumCircuit circ, GateSpecification gs, DataFlow::LocalSourceNode locSource,
      DataFlow::CallCfgNode call
    |
      // detect qc.h(0)
      call = circ.getAnAttributeRead(gs).getACall() and
      this = locSource
    |
      exists(int i | i = gs.getAnArgumentIndexOfQubit() |
        call.(API::CallNode).getParameter(i).getAValueReachingSink() = locSource
      )
      or
      exists(string kyw | kyw = gs.getAnArgumentNameOfQubit() |
        call.(API::CallNode).getKeywordParameter(kyw).getAValueReachingSink() = locSource
      )
    )
  }

  override string getAGateName() {
    exists(QuantumCircuit circ, GateSpecification gs, DataFlow::CallCfgNode call |
      // detect qc.h(0)
      call = circ.getAnAttributeRead(gs).getACall() and
      (
        exists(int i | i = gs.getAnArgumentIndexOfQubit() |
          call.(API::CallNode).getParameter(i).getAValueReachingSink() = this
        )
        or
        exists(string kyw | kyw = gs.getAnArgumentNameOfQubit() |
          call.(API::CallNode).getKeywordParameter(kyw).getAValueReachingSink() = this
        )
      )
    |
      result = gs
    )
  }

  override QuantumCircuit getACircuit() {
    exists(QuantumCircuit circ, GateSpecification gs, DataFlow::CallCfgNode call |
      // detect qc.h(0)
      call = circ.getAnAttributeRead(gs).getACall() and
      (
        exists(int i | i = gs.getAnArgumentIndexOfQubit() |
          call.(API::CallNode).getParameter(i).getAValueReachingSink() = this
        )
        or
        exists(string kyw | kyw = gs.getAnArgumentNameOfQubit() |
          call.(API::CallNode).getKeywordParameter(kyw).getAValueReachingSink() = this
        )
      )
    |
      result = circ
    )
  }
}

/** Use of a qubit as appended call on the circuit object. */
class QubitUseViaAppend extends QubitUse {
  QubitUseViaAppend() {
    exists(
      QuantumCircuit circ, GateSpecification gs, DataFlow::LocalSourceNode locSource,
      DataFlow::LocalSourceNode qubitListSource, DataFlow::CallCfgNode appendCall,
      DataFlow::CallCfgNode gateCall
    |
      // detect qc.append(CXGate(), [0, 1])
      appendCall = circ.getAnAttributeRead("append").getACall() and
      gateCall = appendCall.(API::CallNode).getParameter(0, "instruction").getAValueReachingSink() and
      gateCall =
        API::moduleImport("qiskit")
            .getMember("circuit")
            .getMember("library")
            .getMember(gs)
            .getACall() and
      qubitListSource = appendCall.(API::CallNode).getParameter(1, "qargs").getAValueReachingSink() and
      this = locSource
    |
      if qubitListSource.asExpr() instanceof List
      then qubitListSource.asExpr().(List).getAnElt() = locSource.asExpr()
      else qubitListSource.asExpr() = locSource.asExpr()
    )
  }

  override string getAGateName() {
    exists(
      QuantumCircuit circ, GateSpecification gs, DataFlow::LocalSourceNode qubitListSource,
      DataFlow::CallCfgNode appendCall, DataFlow::CallCfgNode gateCall
    |
      // detect qc.append(CXGate(), [0, 1])
      appendCall = circ.getAnAttributeRead("append").getACall() and
      gateCall = appendCall.(API::CallNode).getParameter(0, "instruction").getAValueReachingSink() and
      gateCall =
        API::moduleImport("qiskit")
            .getMember("circuit")
            .getMember("library")
            .getMember(gs)
            .getACall() and
      qubitListSource = appendCall.(API::CallNode).getParameter(1, "qargs").getAValueReachingSink() and
      // qubitListSource.asExpr().(List).getAnElt() = this.asExpr()
      if qubitListSource.asExpr() instanceof List
      then qubitListSource.asExpr().(List).getAnElt() = this.asExpr()
      else qubitListSource.asExpr() = this.asExpr()
    |
      result = gs
    )
  }

  override QuantumCircuit getACircuit() {
    exists(
      QuantumCircuit circ, GateSpecification gs, DataFlow::LocalSourceNode qubitListSource,
      DataFlow::CallCfgNode appendCall, DataFlow::CallCfgNode gateCall
    |
      // detect qc.append(CXGate(), [0, 1])
      appendCall = circ.getAnAttributeRead("append").getACall() and
      gateCall = appendCall.(API::CallNode).getParameter(0, "instruction").getAValueReachingSink() and
      gateCall =
        API::moduleImport("qiskit")
            .getMember("circuit")
            .getMember("library")
            .getMember(gs)
            .getACall() and
      qubitListSource = appendCall.(API::CallNode).getParameter(1, "qargs").getAValueReachingSink() and
      // qubitListSource.asExpr().(List).getAnElt() = this.asExpr()
      if qubitListSource.asExpr() instanceof List
      then qubitListSource.asExpr().(List).getAnElt() = this.asExpr()
      else qubitListSource.asExpr() = this.asExpr()
    |
      result = circ
    )
  }
}

class OldQubitUsedInteger extends IntegerLiteral {
  OldQubitUsedInteger() { exists(Gate gate | this = gate.getATargetQubit()) }

  Gate getGate() { exists(Gate gate | this = gate.getATargetQubit() | result = gate) }

  int getQubitIndex() { result = this.getValue() }

  QuantumRegister getQuantumRegister() {
    // OLD
    // exists(
    //     QuantumCircuit circ, QuantumRegister qr
    //     |
    //     circ = this.getGate().getQuantumCircuit() and
    //     qr = circ.getAQuantumRegister() and
    //     count(QuantumRegister reg | reg = circ.getAQuantumRegister() | reg) = 1
    //     |
    //     result = qr
    // )
    // or
    exists(QuantumRegister qr, SubscriptNode subscr |
      qr.getVar().getAUse() = subscr.getObject() and
      this = subscr.getNode().getIndex()
    |
      result = qr
    )
    // NEW
    // exists(
    //     QuantumRegister qr,
    //     QuantumCircuit circ,
    //     Gate gate
    //     |
    //     // this qubit is used in a gate
    //     this = gate.getATargetQubit()
    //     // the register belongs to the circuit
    //     and circ.getAQuantumRegister() = qr
    //     // the gate belongs to the circuit
    //     and circ = gate.getQuantumCircuit()
    //     and (
    //         // either it is the only register in the circuit
    //         // count(circ.getAQuantumRegister()) = 1
    //         // or
    //         (
    //             exists(
    //                 SubscriptNode subscr
    //                 |
    //                 // or we look for the register variable which
    //                 // is used to access the qubit (IntegerLiteral)
    //                 qr.getVar().getAUse() = subscr.getObject()
    //                 and this = subscr.getNode().getIndex()
    //             )
    //         )
    //     )
    //     |
    //     result = qr
    // )
  }
}

// GATE SPECIFICATIONS
abstract class GateSpecification extends string {
  GateSpecification() {
    this instanceof GateSpecificationObjectName or
    this instanceof GateSpecificationAttributeName
  }

  string getName() { result = this }

  /** The argument position pointing to a classical bit. */
  int getAnArgumentIndexOfClbit() {
    exists(int i |
      this.getNumberOfClbits() > 0 and
      i in [0 .. this.getNumberOfClbits() - 1]
    |
      // shift the index if there are qubits
      if this.getNumberOfQubits() > 0 then result = i + this.getNumberOfQubits() else result = i
    )
  }

  /** The named argument pointing to a classical bit. */
  string getAnArgumentNameOfClbit() { result instanceof EmptySetForString }

  /** The argument position pointing to a qubit. */
  int getAnArgumentIndexOfQubit() {
    exists(int i | this.getNumberOfQubits() > 0 and i in [0 .. this.getNumberOfQubits() - 1] |
      // shift the index if there are parameters
      if this.getNumberOfParams() > 0 then result = i + this.getNumberOfParams() else result = i
    )
  }

  /** The named argument pointing to a qubit. */
  string getAnArgumentNameOfQubit() { result instanceof EmptySetForString }

  /** The argument position pointing to a parameter. */
  int getAnArgumentIndexOfParam() {
    exists(int i |
      this.getNumberOfParams() > 0 and
      i in [0 .. this.getNumberOfParams() - 1]
    |
      result = i
    )
  }

  /** The named argument pointing to a parameter. */
  string getAnArgumentNameOfParam() { result instanceof EmptySetForString }

  /** Number of bits used in the gate. */
  int getNumberOfBits() { result = this.getNumberOfQubits() + this.getNumberOfClbits() }

  /** Number of parameters used in the gate. */
  int getNumberOfParams() { result = count(string s | s = this.getAnArgumentNameOfParam()) }

  /** Number of classical bits used in the gate. */
  int getNumberOfClbits() { result = count(string s | s = this.getAnArgumentNameOfClbit()) }

  /** Number of qubits used in the gate. */
  int getNumberOfQubits() { result = count(string s | s = this.getAnArgumentNameOfQubit()) }
}

class GateSpecificationAttributeName extends string {
  GateSpecificationAttributeName() {
    this in [
        // single bit operations
        "x", "y", "z", "h", "s", "sdg", "t", "tdg", "rx", "ry", "rz", "rv", "u1", "u2", "u3", "id",
        "i", "sx",
        // controlled operations
        "cx", "cnot", "cy", "cz", "ch", "cs", "csdg", "csx", "crz", "cry", "crx", "cu1", "cu3",
        "ccx", "ccz", "toffoli", "cswap", "fredkin", "mct", "rccx", "rcccx",
        // multi bit operations
        "rxx", "ryy", "rzz", "rzx", "swap", "iswap", "ms", "cr", "r", "rccx", "ecr",
        // measurements
        "measure", "measure_all"
      ]
  }
}

class GateSpecificationObjectName extends string {
  GateSpecificationObjectName() {
    this in [
        // single operations
        "XGate", "YGate", "ZGate", "HGate", "SGate", "SdgGate", "TGate", "TdgGate", "RXGate",
        "RYGate", "RZGate", "RVGate", "U1Gate", "U2Gate", "U3Gate", "IGate", "SXGate",
        // controlled operations
        "CXGate", "CYGate", "CZGate", "CHGate", "CSGate", "CSdgGate", "CSXGate", "CRZGate",
        "CRYGate", "CRXGate", "CU1Gate", "CU3Gate", "CCXGate", "CCZGate", "CSwapGate", "MCXGate",
        "RCCXGate", "RC3XGate",
        // multi bit operations
        "RXXGate", "RYYGate", "RZZGate", "RZXGate", "SwapGate", "iSwapGate", "MSGate", "CRGate",
        "RGate", "RCCXGate", "ECRGate",
      ]
  }
}

class GateSpecificationSingleQubitNoParam extends GateSpecification {
  GateSpecificationSingleQubitNoParam() {
    this in [
        "h", "x", "y", "z", "s", "sdg", "t", "tdg", "sx", "i", "id", "HGate", "XGate", "YGate",
        "ZGate", "SGate", "SdgGate", "TGate", "TdgGate", "SXGate", "IGate"
      ]
  }

  override string getAnArgumentNameOfQubit() { result = "qubit" }
}

class GateSpecificationRXGate extends GateSpecification {
  GateSpecificationRXGate() { this in ["rx", "RXGate"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }

  override string getAnArgumentNameOfParam() { result = "theta" }
}

class GateSpecificationRYGate extends GateSpecification {
  GateSpecificationRYGate() { this in ["ry", "RYGate"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }

  override string getAnArgumentNameOfParam() { result = "theta" }
}

class GateSpecificationRZGate extends GateSpecification {
  GateSpecificationRZGate() { this in ["rz", "RZGate"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }

  override string getAnArgumentNameOfParam() { result = "phi" }
}

class GateSpecificationRVGate extends GateSpecification {
  GateSpecificationRVGate() { this in ["rv", "RVGate"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }

  override string getAnArgumentNameOfParam() { result in ["vx", "vy", "vz"] }
}

// TODO CONTINUE GATES SINGLE QUBITS WITH PARAMS
class GateSpecificationCXGate extends GateSpecification {
  GateSpecificationCXGate() { this in ["cx", "CXGate", "cnot"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }
}

class GateSpecificationCYGate extends GateSpecification {
  GateSpecificationCYGate() { this in ["cy", "CYGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }
}

class GateSpecificationCZGate extends GateSpecification {
  GateSpecificationCZGate() { this in ["cz", "CZGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }
}

class GateSpecificationCHGate extends GateSpecification {
  GateSpecificationCHGate() { this in ["ch", "CHGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }
}
// TODO continue controlled gates and the rest
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
