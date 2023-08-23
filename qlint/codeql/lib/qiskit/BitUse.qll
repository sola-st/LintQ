import qiskit.Circuit
import qiskit.Register
import qiskit.BitDef
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

  abstract Gate getAGate();

  abstract string getAGateName();

  // boolean mayFollow(BitUse other) {
  // }
  /** Holds if the current bit follows the other qubit in any scenario. */
  predicate mustFollow(BitUse other) {
    // case: qc.h(0); qc.rx(3.14, 0)
    exists(
      Gate currentGate, Gate otherGate, int commontIndex, string commonCircuitName,
      string commonRegisterName
    |
      // either they act on the same register
      this.getARegisterName() = commonRegisterName and
      other.getARegisterName() = commonRegisterName
      or
      // they act on different ones, but one is anonymous
      this.getARegisterName() = "anonymous register" and
      other.getARegisterName() = commonRegisterName
      or
      this.getARegisterName() = commonRegisterName and
      other.getARegisterName() = "anonymous register"
    |
      // they act on the same index in the register
      this.getAnIndex() = commontIndex and
      other.getAnIndex() = commontIndex and
      // they act on the same circuit
      this.getACircuitName() = commonCircuitName and
      other.getACircuitName() = commonCircuitName and
      // the current gate is after the other gate
      this.getAGate() = currentGate and
      other.getAGate() = otherGate and
      otherGate.getNode().strictlyDominates(currentGate.getNode())
    )
    or
    // case: qc.h(0); qc.ch(0, 2); qc.x(2)
    exists(Gate intermediateGate, BitUse intermediateBitUseA, BitUse intermediateBitUseB |
      intermediateBitUseA.getAGate() = intermediateGate and
      intermediateBitUseB.getAGate() = intermediateGate and
      intermediateBitUseA.mustFollow(other) and
      this.mustFollow(intermediateBitUseB)
    )
    // or
    // // case: qc.h(0); qc.x(qreg[0]);  with qreg only register
    // exists(
    //   Gate currentGate, Gate otherGate,
    //   int commontIndex
    // |
    //   // the act on the same circuit, register and index
    //   this.getAnIndex() = commontIndex and
    //   other.getAnIndex() = commontIndex and
    //   forall(string circNameThis, string circNameOther
    //   |
    //     circNameThis = this.getACircuitName() and
    //     circNameOther = other.getACircuitName()
    //   |
    //     circNameThis = circNameOther
    //   ) and
    //   // the current gate is after the other gate
    //   this.getAGate() = currentGate and
    //   other.getAGate() = otherGate and
    //   otherGate.getNode().strictlyDominates(currentGate.getNode()) and
    //   // one of the two is anonymous and the other is not
    //   exists(RegisterV2 reg
    //   |
    //     (
    //       reg = this.getARegister() and other.getARegisterName() = "anonymous register"
    //       or
    //       reg = other.getARegister() and this.getARegisterName() = "anonymous register"
    //     ) and
    //     this.likelySameCircuit(other)
    //   )
    // )
  }

  // boolean mayFollowDirectly(BitUse other) {
  // }
  // boolean mustFollowDirectly(BitUse other) {
  // }
  /** Holds if the current bit refers to a specific BitDef. */
  predicate refersTo(BitDefinition referencedBitDef) {
    this.getARegisterName() = referencedBitDef.getARegisterName() and
    this.getAnIndexIfAny() = referencedBitDef.getAnIndexIfAny() and
    this.getACircuitName() = referencedBitDef.getACircuitName() and
    this.getARegister() = referencedBitDef.getARegister() and
    this.getACircuit() = referencedBitDef.getACircuit()
  }

  /** Holds if the two BitUse refer to the same position and circuit. */
  predicate equals(BitUse other) {
    this.getARegisterName() = other.getARegisterName() and
    this.getAnIndexIfAny() = other.getAnIndexIfAny() and
    this.getACircuitName() = other.getACircuitName() and
    this.getARegister() = other.getARegister() and
    this.getACircuit() = other.getACircuit()
  }

  /** Holds if the two BitUse refer to the same circuit. */
  predicate likelySameCircuit(BitUse other) {
    this.getACircuitName() = "anonymous circuit" and
    other.getACircuitName() = "anonymous circuit" and
    // check that they are at least part of the same register
    this.likelySameRegister(other)
    or
    this.getACircuitName() = other.getACircuitName() and
    this.getACircuit() = other.getACircuit()
  }

  /** Holds if the two BitUse refer to the same register. */
  predicate likelySameRegister(BitUse other) {
    this.getARegisterName() = "anonymous register" and
    other.getARegisterName() = "anonymous register" and
    // check that they are at least part of the same circuit
    this.likelySameCircuit(other)
    or
    this.getARegisterName() = other.getARegisterName() and
    this.getARegister() = other.getARegister()
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

  override Gate getAGate() {
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
      result = call
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

  override Gate getAGate() {
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
      result = gateCall
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

// GATE SPECIFICATIONS
// TODO: support mcrx, mcry, mcrz
// TODO: cu1 and cu3 are deprecated, support different versions of Qiskit
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
        "x", "y", "z", "h", "s", "sdg", "t", "tdg", "rx", "ry", "rz", "rv", "u1", "u2", "u3", "id", "iden",
        "i", "sx",
        // controlled operations
        "cx", "cnot", "cy", "cz", "ch", "cs", "csdg", "csx", "crz", "cry", "crx", "cu1", "cu3",
        "cu", "ccx", "ccz", "toffoli", "cswap", "fredkin", "mct", "rccx", "rcccx",
        // multi bit operations
        "rxx", "ryy", "rzz", "rzx", "swap", "iswap", "ms", "cr", "r", "rccx", "ecr",
        // measurements
        "measure", "measure_all",
        // reset
        "reset"
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

/** Specification of gates that are unitary / reversible gates. */
abstract class GateSpecificationUnitary extends GateSpecification { }

/** Specification of gates that are not unitary and destroy the quantum state. */
abstract class GateSpecificationNonUnitary extends GateSpecification { }

// NON-UNITARY GATES
class GateSpecificationReset extends GateSpecificationNonUnitary {
  GateSpecificationReset() { this in ["reset", "Reset"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }
}

class GateSpecificationMeasureAll extends GateSpecificationNonUnitary {
  GateSpecificationMeasureAll() { this in ["measure_all"] }
}

class GateSpecificationMeasure extends GateSpecificationNonUnitary {
  GateSpecificationMeasure() { this in ["measure", "Measure"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }

  override string getAnArgumentNameOfClbit() { result = "cbit" }
}

// UNITARY GATES
class GateSpecificationSingleQubitNoParam extends GateSpecificationUnitary {
  GateSpecificationSingleQubitNoParam() {
    this in [
        "h", "x", "y", "z", "s", "sdg", "t", "tdg", "sx", "i", "id", "iden", "HGate", "XGate", "YGate",
        "ZGate", "SGate", "SdgGate", "TGate", "TdgGate", "SXGate", "IGate"
      ]
  }

  override string getAnArgumentNameOfQubit() { result = "qubit" }
}

class GateSpecificationRXGate extends GateSpecificationUnitary {
  GateSpecificationRXGate() { this in ["rx", "RXGate"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }

  override string getAnArgumentNameOfParam() { result = "theta" }
}

class GateSpecificationRYGate extends GateSpecificationUnitary {
  GateSpecificationRYGate() { this in ["ry", "RYGate"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }

  override string getAnArgumentNameOfParam() { result = "theta" }
}

class GateSpecificationRZGate extends GateSpecificationUnitary {
  GateSpecificationRZGate() { this in ["rz", "RZGate"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }

  override string getAnArgumentNameOfParam() { result = "phi" }
}

class GateSpecificationRVGate extends GateSpecificationUnitary {
  GateSpecificationRVGate() { this in ["rv", "RVGate"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }

  override string getAnArgumentNameOfParam() { result in ["vx", "vy", "vz"] }
}

class GateSpecificationU1Gate extends GateSpecificationUnitary {
  GateSpecificationU1Gate() { this in ["u1", "U1Gate"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }

  override string getAnArgumentNameOfParam() { result = "theta" }
}

class GateSpecificationU2Gate extends GateSpecificationUnitary {
  GateSpecificationU2Gate() { this in ["u2", "U2Gate"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }

  override string getAnArgumentNameOfParam() { result in ["phi", "lam"] }
}

class GateSpecificationU3Gate extends GateSpecificationUnitary {
  GateSpecificationU3Gate() { this in ["u3", "U3Gate", "u", "UGate"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }

  override string getAnArgumentNameOfParam() { result in ["theta", "phi", "lam"] }
}

// TODO: CHECK IF ALL GATES WITH PARAMS ARE PRESENT
class GateSpecificationCXGate extends GateSpecificationUnitary {
  GateSpecificationCXGate() { this in ["cx", "CXGate", "cnot"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }
}

class GateSpecificationCYGate extends GateSpecificationUnitary {
  GateSpecificationCYGate() { this in ["cy", "CYGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }
}

class GateSpecificationCZGate extends GateSpecificationUnitary {
  GateSpecificationCZGate() { this in ["cz", "CZGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }
}

class GateSpecificationCHGate extends GateSpecificationUnitary {
  GateSpecificationCHGate() { this in ["ch", "CHGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }
}

class GateSpecificationCSGate extends GateSpecificationUnitary {
  GateSpecificationCSGate() { this in ["cs", "CSGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }
}

class GateSpecificationCSdgGate extends GateSpecificationUnitary {
  GateSpecificationCSdgGate() { this in ["csdg", "CSdgGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }
}

class GateSpecificationCSXGate extends GateSpecificationUnitary {
  GateSpecificationCSXGate() { this in ["csx", "CSXGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }
}

// CONTROL WITH PARAMS
class GateSpecificationCRZGate extends GateSpecificationUnitary {
  GateSpecificationCRZGate() { this in ["crz", "CRZGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }

  override string getAnArgumentNameOfParam() { result = "theta" }
}

class GateSpecificationCRYGate extends GateSpecificationUnitary {
  GateSpecificationCRYGate() { this in ["cry", "CRYGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }

  override string getAnArgumentNameOfParam() { result = "theta" }
}

class GateSpecificationCRXGate extends GateSpecificationUnitary {
  GateSpecificationCRXGate() { this in ["crx", "CRXGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }

  override string getAnArgumentNameOfParam() { result = "theta" }
}

class GateSpecificationCU1Gate extends GateSpecificationUnitary {
  GateSpecificationCU1Gate() { this in ["cu1", "CU1Gate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }

  override string getAnArgumentNameOfParam() { result = "theta" }
}

class GateSpecificationCU3Gate extends GateSpecificationUnitary {
  GateSpecificationCU3Gate() { this in ["cu3", "CU3Gate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }

  override string getAnArgumentNameOfParam() { result in ["theta", "phi", "lam"] }
}

class GateSpecificationCUGate extends GateSpecificationUnitary {
  GateSpecificationCUGate() { this in ["cu", "CUGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }

  override string getAnArgumentNameOfParam() { result in ["theta", "phi", "lam", "gamma"] }
}
// TODO: CONTINUE WITH double controls
