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

  int getAnAbsoluteIndex() {
    if exists(int i | i = this.getAnAbsoluteIndexIfAny())
    then exists(int i | i = this.getAnAbsoluteIndexIfAny() | result = i)
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

  abstract int getAnAbsoluteIndexIfAny();

  abstract RegisterV2 getARegister();

  abstract QuantumCircuit getACircuit();

  abstract QuantumOperator getAGate();

  abstract string getAGateName();

  // boolean mayFollow(BitUse other) {
  // }
  /** Holds if the current bit follows the other qubit in any scenario. */
  predicate mustFollow(BitUse other) {
    // case: qc.h(0); qc.rx(3.14, 0)
    exists(
      QuantumOperator currentGate, QuantumOperator otherGate, int commontIndex,
      string commonCircuitName, string commonRegisterName
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
    exists(
      QuantumOperator intermediateGate, BitUse intermediateBitUseA, BitUse intermediateBitUseB
    |
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
  private predicate sameCircuit(BitUse other) {
    // case: qc.h(0); qc.h(qreg[2])
    this.getACircuitName() = other.getACircuitName() and
    this.getACircuit() = other.getACircuit()
  }

  /** Holds if the two BitUse refer to the same register. */
  predicate sameRegister(BitUse other) {
    // case: qc.h(qreg[0]); qc.h(qreg[1])
    this.getARegisterName() = other.getARegisterName() and
    this.getARegister() = other.getARegister()
    or
    // case: qc.h(0); qc.h(1)
    this.getARegisterName() = "anonymous register" and
    other.getARegisterName() = "anonymous register" and
    this.sameCircuit(other)
  }

  /** Holds if one is anonymous register and other is on the only quantum register. */
  predicate hasCircuitSingleAnonymousRegister() {
    // case QubitUse
    this instanceof QubitUse and
    this.getARegisterName() = "anonymous register" and
    count(QuantumRegisterV2 qreg | qreg = this.getACircuit().(QuantumCircuit).getAQuantumRegister()) =
      1
    or
    // case ClbitUse
    this instanceof ClbitUse and
    this.getARegisterName() = "anonymous register" and
    count(ClassicalRegisterV2 creg |
      creg = this.getACircuit().(QuantumCircuit).getAClassicalRegister()
    ) = 1
  }

  /** Holds if the other BitUse MUST refers to the same position, register and circuit. */
  predicate mustReferToSameBitOf(BitUse other) {
    this.mustReferToSameRegAndCircOf(other) and
    this.getAnIndexIfAny() = other.getAnIndexIfAny()
  }

  /**
   * Holds if the other BitUse MAY refers to the same position, register and circuit.
   *
   * Note that this caputre also cases where the variable might not be modeled
   * (e.g. qc.h(i) and qc.h(5 + 7)).
   */
  predicate mayReferToSameBitOf(BitUse other) {
    this.mustReferToSameRegAndCircOf(other) and
    this.getAnIndex() = other.getAnIndex() // this might be -1 for both
  }

  /** Holds if the other BitUse MUST refers to the same register and circuit. */
  predicate mustReferToSameRegAndCircOf(BitUse other) {
    // same type
    (
      this instanceof QubitUse and other instanceof QubitUse
      or
      this instanceof ClbitUse and other instanceof ClbitUse
    ) and
    // case: same circuit -> qc.h(0); qc.h(qreg[2])
    this.sameCircuit(other) and
    (
      // case: same default register -> qc.h(0); qc.h(1)
      this.getARegisterName() = "anonymous register" and
      other.getARegisterName() = "anonymous register"
      or
      // case: mixed but this is anonymous -> qc.h(0); qc.h(qreg[1])
      this.hasCircuitSingleAnonymousRegister()
      or
      // case: mixed but other is anonymous -> qc.h(qreg[0]); qc.h(1)
      other.hasCircuitSingleAnonymousRegister()
    )
    or
    // case: same circuit and register -> qc.h(qreg[0]); qc.h(qreg[1])
    this.sameCircuit(other) and this.sameRegister(other)
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

  override int getAnAbsoluteIndexIfAny() {
    // if this belongs to a no register it is like the relative index
    count(QuantumRegisterV2 qreg | qreg = this.getARegister()) = 0 and
    this.getAnIndexIfAny() = result
    or
    // if this belongs to a register,
    count(QuantumRegisterV2 qreg | qreg = this.getARegister()) > 0 and
    // the register is shift by the amount of positions of the previous registers
    exists(
      QuantumCircuitConstructor circ, QuantumRegisterV2 currentReg, int sizePreceedingRegs,
      int posCurrentReg
    |
      // the circuit is of this qubit use as well
      circ = this.getACircuit() and
      // connects the qubit use and its register
      currentReg = this.getARegister() and
      // it flows to the register as a specific position of the circuit constructor
      currentReg.flowsTo(circ.getArg(posCurrentReg)) and
      // the sum of the preceeding registers is...
      sizePreceedingRegs =
        sum(int iSize |
          exists(QuantumRegisterV2 iReg, int iRegPos |
            iSize = iReg.getSize() and
            // the register is part of the same circuit
            iReg.getACircuit() = circ and
            // the register flows in the same circuit constructor
            iReg.flowsTo(circ.getArg(iRegPos)) and
            // it position comes before the current register
            iRegPos < posCurrentReg
          )
        )
    |
      result = +this.getAnIndexIfAny()
    )
    or
    // if it is not a QuantumCircuitConstructor
    // then it returns -1
    not this.getACircuit() instanceof QuantumCircuitConstructor and
    result = -1
  }

  override RegisterV2 getARegister() {
    // case: qc.h(0)
    // > EmptySetForRegisterV2
    // case: qc.h(quantum_register[7])
    // > quantum_register
    // case: qc.h(quantum_register)
    // > quantum_register
    // exists(RegisterV2 reg
    // |
    //   reg.getScope() = this.getScope() and
    //   reg.getName() = this.asExpr().(Subscript).getObject().toString()
    // |
    //   result = reg
    // )
    // or
    exists(RegisterV2 reg, Value regValue |
      regValue.getOrigin() = reg.getNode() and
      this.asExpr().(Subscript).getObject().pointsTo(regValue)
    |
      result = reg
    )
    or
    exists(RegisterV2 reg | reg.flowsTo(this) | result = reg)
    or
    result instanceof EmptySetForRegisterV2
    // if
    //   exists(RegisterV2 reg |
    //     reg.getScope() = this.getScope() and
    //     reg.getName() = this.asExpr().(Subscript).getObject().toString()
    //   )
    // then
    //   exists(RegisterV2 reg |
    //     reg.getScope() = this.getScope() and
    //     reg.getName() = this.asExpr().(Subscript).getObject().toString()
    //   |
    //     result = reg
    //   )
    // else
    //   if exists(RegisterV2 reg | reg.flowsTo(this))
    //   then exists(RegisterV2 reg | reg.flowsTo(this) | result = reg)
    //   else result instanceof EmptySetForRegisterV2
  }
}

/** Use of a clbit. */
abstract class ClbitUse extends BitUse { }

/** Use of a qubit as attribute call on the circuit object. */
class QubitUseViaAttribute extends QubitUse {
  QubitUseViaAttribute() {
    exists(
      QuantumCircuit circ, OperatorSpecification gs, DataFlow::LocalSourceNode qubitListSource,
      DataFlow::CallCfgNode call
    |
      // detect qc.h(0)
      call = circ.getAnAttributeRead(gs).getACall() and
      // avoid to consider the values defined in the __get_item__() method
      // of the Register class in qiskit
      not this.getLocation()
          .getFile()
          .getAbsolutePath()
          .matches("%site-packages/qiskit/circuit/register.py")
    |
      exists(int i | i = gs.getAnArgumentIndexOfQubit() |
        call.(API::CallNode).getParameter(i).getAValueReachingSink() = qubitListSource and
        (
          // CASE: qc.h(0)
          qubitListSource.asExpr() = this.asExpr()
          or
          // CASE: qc.measure([0, 1], [0, 1])
          qubitListSource.asExpr() instanceof List and
          qubitListSource.asExpr().(List).getAnElt() = this.asExpr()
        )
      )
      or
      exists(string kyw | kyw = gs.getAnArgumentNameOfQubit() |
        call.(API::CallNode).getKeywordParameter(kyw).getAValueReachingSink() = qubitListSource and
        (
          // CASE: qc.h(qubit=0)
          qubitListSource.asExpr() = this.asExpr()
          or
          // CASE: qc.measure(qubit=[0, 1], cbit=[0, 1])
          qubitListSource.asExpr() instanceof List and
          qubitListSource.asExpr().(List).getAnElt() = this.asExpr()
        )
      )
    )
  }

  override string getAGateName() {
    exists(QuantumCircuit circ, OperatorSpecification gs, DataFlow::CallCfgNode call |
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

  override QuantumOperator getAGate() {
    exists(QuantumCircuit circ, OperatorSpecification gs, DataFlow::CallCfgNode call |
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
    exists(QuantumCircuit circ, OperatorSpecification gs, DataFlow::CallCfgNode call |
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
      QuantumCircuit circ, OperatorSpecification gs, DataFlow::LocalSourceNode qubitListSource,
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
      // avoid to consider the values defined in the __get_item__() method
      // of the Register class in qiskit
      not this.getLocation()
          .getFile()
          .getAbsolutePath()
          .matches("%site-packages/qiskit/circuit/register.py")
    |
      // CASE: qc.append(CXGate(), [0, 1])
      qubitListSource.asExpr() instanceof List and
      qubitListSource.asExpr().(List).getAnElt() = this.asExpr()
      or
      // CASE: qc.append(CXGate(), 0)
      qubitListSource.asExpr() = this.asExpr()
    )
  }

  override string getAGateName() {
    exists(
      QuantumCircuit circ, OperatorSpecification gs, DataFlow::LocalSourceNode qubitListSource,
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

  override QuantumOperator getAGate() {
    exists(
      QuantumCircuit circ, OperatorSpecification gs, DataFlow::LocalSourceNode qubitListSource,
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
      QuantumCircuit circ, OperatorSpecification gs, DataFlow::LocalSourceNode qubitListSource,
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

/** Use of a qubit in a measure_all call. */
class QubitUseViaMeasureAll extends QubitUse {
  QubitUseViaMeasureAll() {
    exists(QuantumCircuit circ |
      // detect qc.measure_all()
      this = circ.getAnAttributeRead("measure_all").getACall()
    )
  }

  override string getAGateName() { result = "measure_all" }

  override QuantumOperator getAGate() { result = this }

  override QuantumCircuit getACircuit() {
    exists(QuantumCircuit circ |
      // detect qc.measure_all()
      this = circ.getAnAttributeRead("measure_all").getACall()
    |
      result = circ
    )
  }

  override int getAnIndexIfAny() {
    exists(QuantumCircuit circ, int i |
      this = circ.getAnAttributeRead("measure_all").getACall() and
      if circ.getNumberOfQubits() > 0 then i in [0 .. circ.getNumberOfQubits() - 1] else i = -1
    |
      result = i
    )
  }
}

// GATE SPECIFICATIONS
// TODO: support mcrx, mcry, mcrz
// TODO: cu1 and cu3 are deprecated, support different versions of Qiskit
abstract class OperatorSpecification extends string {
  OperatorSpecification() {
    this instanceof OperatorSpecificationObjectName or
    this instanceof OperatorSpecificationAttributeName
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

class OperatorSpecificationAttributeName extends string {
  OperatorSpecificationAttributeName() {
    this in [
        // single bit operations
        "x", "y", "z", "h", "s", "sdg", "t", "tdg", "rx", "ry", "rz", "rv", "u1", "u2", "u3", "id",
        "u", "iden", "i", "sx", "p",
        // controlled operations
        "cx", "cnot", "cy", "cz", "ch", "cs", "csdg", "csx", "crz", "cry", "crx", "cu1", "cu3",
        "cu", "ccx", "ccz", "toffoli", "cswap", "fredkin", "mct", "rccx", "rcccx", "cp",
        // multi bit operations
        "rxx", "ryy", "rzz", "rzx", "swap", "iswap", "ms", "cr", "r", "rccx", "ecr",
        // measurements
        "measure", "measure_all",
        // reset
        "reset",
        // unitary
        "unitary",
        // initialize
        "initialize"
      ]
  }
}

class OperatorSpecificationObjectName extends string {
  OperatorSpecificationObjectName() {
    this in [
        // single operations
        "XGate", "YGate", "ZGate", "HGate", "SGate", "SdgGate", "TGate", "TdgGate", "RXGate",
        "RYGate", "RZGate", "RVGate", "U1Gate", "U2Gate", "U3Gate", "IGate", "SXGate", "PhaseGate",
        "UGate",
        // controlled operations
        "CXGate", "CYGate", "CZGate", "CHGate", "CSGate", "CSdgGate", "CSXGate", "CRZGate",
        "CRYGate", "CRXGate", "CU1Gate", "CU3Gate", "CCXGate", "CCZGate", "CSwapGate", "MCXGate",
        "RCCXGate", "RC3XGate", "CPhaseGate",
        // multi bit operations
        "RXXGate", "RYYGate", "RZZGate", "RZXGate", "SwapGate", "iSwapGate", "MSGate", "CRGate",
        "RGate", "RCCXGate", "ECRGate",
        // measurements
        "Measure",
        // reset
        "Reset",
        // unitary
        "UnitaryGate",
        // initialize
        "Initialize"
      ]
  }
}

/** Specification of gates that are unitary / reversible gates. */
abstract class OperatorSpecificationUnitary extends OperatorSpecification { }

/** Specification of gates that are not unitary and destroy the quantum state. */
abstract class OperatorSpecificationNonUnitary extends OperatorSpecification { }

// NON-UNITARY GATES
class OperatorSpecificationReset extends OperatorSpecificationNonUnitary {
  OperatorSpecificationReset() { this in ["reset", "Reset"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }
}

class OperatorSpecificationMeasureAll extends OperatorSpecificationNonUnitary {
  OperatorSpecificationMeasureAll() { this in ["measure_all"] }
}

class OperatorSpecificationMeasure extends OperatorSpecificationNonUnitary {
  OperatorSpecificationMeasure() { this in ["measure", "Measure"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }

  override string getAnArgumentNameOfClbit() { result = "cbit" }
}

class OperatorSpecificationInitialize extends OperatorSpecificationNonUnitary {
  OperatorSpecificationInitialize() { this in ["initialize", "Initialize"] }

  override string getAnArgumentNameOfQubit() { result = "qubits" }

  override string getAnArgumentNameOfParam() { result = "params" }
}

// UNITARY GATES
class OperatorSpecificationUnitaryGateObj extends OperatorSpecificationUnitary {
  OperatorSpecificationUnitaryGateObj() { this = "UnitaryGate" }

  override string getAnArgumentNameOfParam() { result = "data" }
}

class OperatorSpecificationUnitaryCall extends OperatorSpecificationUnitary {
  OperatorSpecificationUnitaryCall() { this = "unitary" }

  override string getAnArgumentNameOfParam() { result = "obj" }

  override string getAnArgumentNameOfQubit() { result = "qubits" }
}

class OperatorSpecificationSingleQubitNoParam extends OperatorSpecificationUnitary {
  OperatorSpecificationSingleQubitNoParam() {
    this in [
        "h", "x", "y", "z", "s", "sdg", "t", "tdg", "sx", "i", "id", "iden", "HGate", "XGate",
        "YGate", "ZGate", "SGate", "SdgGate", "TGate", "TdgGate", "SXGate", "IGate"
      ]
  }

  override string getAnArgumentNameOfQubit() { result = "qubit" }
}

class OperatorSpecificationPGate extends OperatorSpecificationUnitary {
  OperatorSpecificationPGate() { this in ["p", "PhaseGate"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }

  override string getAnArgumentNameOfParam() { result = "theta" }
}

class OperatorSpecificationRXGate extends OperatorSpecificationUnitary {
  OperatorSpecificationRXGate() { this in ["rx", "RXGate"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }

  override string getAnArgumentNameOfParam() { result = "theta" }
}

class OperatorSpecificationRYGate extends OperatorSpecificationUnitary {
  OperatorSpecificationRYGate() { this in ["ry", "RYGate"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }

  override string getAnArgumentNameOfParam() { result = "theta" }
}

class OperatorSpecificationRZGate extends OperatorSpecificationUnitary {
  OperatorSpecificationRZGate() { this in ["rz", "RZGate"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }

  override string getAnArgumentNameOfParam() { result = "phi" }
}

class OperatorSpecificationRVGate extends OperatorSpecificationUnitary {
  OperatorSpecificationRVGate() { this in ["rv", "RVGate"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }

  override string getAnArgumentNameOfParam() { result in ["vx", "vy", "vz"] }
}

class OperatorSpecificationU1Gate extends OperatorSpecificationUnitary {
  OperatorSpecificationU1Gate() { this in ["u1", "U1Gate"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }

  override string getAnArgumentNameOfParam() { result = "theta" }
}

class OperatorSpecificationU2Gate extends OperatorSpecificationUnitary {
  OperatorSpecificationU2Gate() { this in ["u2", "U2Gate"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }

  override string getAnArgumentNameOfParam() { result in ["phi", "lam"] }
}

class OperatorSpecificationU3Gate extends OperatorSpecificationUnitary {
  OperatorSpecificationU3Gate() { this in ["u3", "U3Gate", "u", "UGate"] }

  override string getAnArgumentNameOfQubit() { result = "qubit" }

  override string getAnArgumentNameOfParam() { result in ["theta", "phi", "lam"] }
}

// TODO: CHECK IF ALL GATES WITH PARAMS ARE PRESENT
class OperatorSpecificationCPGate extends OperatorSpecificationUnitary {
  OperatorSpecificationCPGate() { this in ["cp", "CPhaseGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }

  override string getAnArgumentNameOfParam() { result = "theta" }
}

class OperatorSpecificationCXGate extends OperatorSpecificationUnitary {
  OperatorSpecificationCXGate() { this in ["cx", "CXGate", "cnot"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }
}

class OperatorSpecificationCYGate extends OperatorSpecificationUnitary {
  OperatorSpecificationCYGate() { this in ["cy", "CYGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }
}

class OperatorSpecificationCZGate extends OperatorSpecificationUnitary {
  OperatorSpecificationCZGate() { this in ["cz", "CZGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }
}

class OperatorSpecificationCHGate extends OperatorSpecificationUnitary {
  OperatorSpecificationCHGate() { this in ["ch", "CHGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }
}

class OperatorSpecificationCSGate extends OperatorSpecificationUnitary {
  OperatorSpecificationCSGate() { this in ["cs", "CSGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }
}

class OperatorSpecificationCSdgGate extends OperatorSpecificationUnitary {
  OperatorSpecificationCSdgGate() { this in ["csdg", "CSdgGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }
}

class OperatorSpecificationCSXGate extends OperatorSpecificationUnitary {
  OperatorSpecificationCSXGate() { this in ["csx", "CSXGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }
}

// GENERIC TWO-QUBIT GATES
class OperatorSpecificationSwapGate extends OperatorSpecificationUnitary {
  OperatorSpecificationSwapGate() { this in ["swap", "SwapGate"] }

  override string getAnArgumentNameOfQubit() { result in ["qubit1", "qubit2"] }
}

class OperatorSpecificationISwapGate extends OperatorSpecificationUnitary {
  OperatorSpecificationISwapGate() { this in ["iswap", "iSwapGate"] }

  override string getAnArgumentNameOfQubit() { result in ["qubit1", "qubit2"] }
}

// CONTROL WITH PARAMS
class OperatorSpecificationCRZGate extends OperatorSpecificationUnitary {
  OperatorSpecificationCRZGate() { this in ["crz", "CRZGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }

  override string getAnArgumentNameOfParam() { result = "theta" }
}

class OperatorSpecificationCRYGate extends OperatorSpecificationUnitary {
  OperatorSpecificationCRYGate() { this in ["cry", "CRYGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }

  override string getAnArgumentNameOfParam() { result = "theta" }
}

class OperatorSpecificationCRXGate extends OperatorSpecificationUnitary {
  OperatorSpecificationCRXGate() { this in ["crx", "CRXGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }

  override string getAnArgumentNameOfParam() { result = "theta" }
}

class OperatorSpecificationCU1Gate extends OperatorSpecificationUnitary {
  OperatorSpecificationCU1Gate() { this in ["cu1", "CU1Gate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }

  override string getAnArgumentNameOfParam() { result = "theta" }
}

class OperatorSpecificationCU3Gate extends OperatorSpecificationUnitary {
  OperatorSpecificationCU3Gate() { this in ["cu3", "CU3Gate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }

  override string getAnArgumentNameOfParam() { result in ["theta", "phi", "lam"] }
}

class OperatorSpecificationCUGate extends OperatorSpecificationUnitary {
  OperatorSpecificationCUGate() { this in ["cu", "CUGate"] }

  override string getAnArgumentNameOfQubit() { result in ["control_qubit", "target_qubit"] }

  override string getAnArgumentNameOfParam() { result in ["theta", "phi", "lam", "gamma"] }
}

// TODO: CONTINUE WITH double controls
class OperatorSpecificationCSwapGate extends OperatorSpecificationUnitary {
  OperatorSpecificationCSwapGate() { this in ["cswap", "CSwapGate", "fredkin"] }

  override string getAnArgumentNameOfQubit() {
    result in ["control_qubit", "target_qubit1", "target_qubit2"]
  }
}

class OperatorSpecificationCCXGate extends OperatorSpecificationUnitary {
  OperatorSpecificationCCXGate() { this in ["ccx", "CCXGate", "toffoli"] }

  override string getAnArgumentNameOfQubit() {
    result in ["control_qubit1", "control_qubit2", "target_qubit"]
  }
}

class OperatorSpecificationCCZGate extends OperatorSpecificationUnitary {
  OperatorSpecificationCCZGate() { this in ["ccz", "CCZGate"] }

  override string getAnArgumentNameOfQubit() {
    result in ["control_qubit1", "control_qubit2", "target_qubit"]
  }
}

class OperatorSpecificationRXXGate extends OperatorSpecificationUnitary {
  OperatorSpecificationRXXGate() { this in ["rxx", "RXXGate"] }

  override string getAnArgumentNameOfQubit() { result in ["qubit1", "qubit2"] }

  override string getAnArgumentNameOfParam() { result = "theta" }
}

class OperatorSpecificationRYYGate extends OperatorSpecificationUnitary {
  OperatorSpecificationRYYGate() { this in ["ryy", "RYYGate"] }

  override string getAnArgumentNameOfQubit() { result in ["qubit1", "qubit2"] }

  override string getAnArgumentNameOfParam() { result = "theta" }
}

class OperatorSpecificationRZZGate extends OperatorSpecificationUnitary {
  OperatorSpecificationRZZGate() { this in ["rzz", "RZZGate"] }

  override string getAnArgumentNameOfQubit() { result in ["qubit1", "qubit2"] }

  override string getAnArgumentNameOfParam() { result = "theta" }
}

class OperatorSpecificationRZXGate extends OperatorSpecificationUnitary {
  OperatorSpecificationRZXGate() { this in ["rzx", "RZXGate"] }

  override string getAnArgumentNameOfQubit() { result in ["qubit1", "qubit2"] }

  override string getAnArgumentNameOfParam() { result = "theta" }
}
