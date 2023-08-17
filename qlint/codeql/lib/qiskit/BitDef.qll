import qiskit.Circuit
import qiskit.Register
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs

/** Definition of a qubit or bit. */
abstract class BitDefinition extends DataFlow::LocalSourceNode {
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

  abstract string getTypeName();

  abstract int getAnIndexIfAny();

  abstract RegisterV2 getARegister();

  abstract QuantumCircuit getACircuit();

  boolean equals(BitDefinition other) {
    if
      this.getARegisterName() = other.getARegisterName() and
      this.getAnIndexIfAny() = other.getAnIndexIfAny() and
      this.getACircuitName() = other.getACircuitName() and
      this.getARegister() = other.getARegister() and
      this.getACircuit() = other.getACircuit() and
      this.getTypeName() = other.getTypeName()
    then result = true
    else result = false
  }
}

abstract class QubitDefinition extends BitDefinition {
  override string getTypeName() { result = "qubit" }
}

abstract class ClbitDefinition extends BitDefinition {
  override string getTypeName() { result = "clbit" }
}

predicate isIntegerParameterOfCall(
  DataFlow::LocalSourceNode integerParameter, DataFlow::CallCfgNode call, int indexParam
) {
  exists(IntegerLiteral intLit |
    integerParameter.flowsTo(call.getArg(indexParam)) and
    integerParameter.asExpr() = intLit
  )
}

/** Qubit generated implicitly by QuantumCircuit(). */
class ImplicitCircuitQubitDefinition extends BitDefinition, QubitDefinition {
  ImplicitCircuitQubitDefinition() {
    exists(QuantumCircuit qc, DataFlow::LocalSourceNode locSource |
      qc instanceof QuantumCircuitConstructor or
      qc instanceof BuiltinParametrizedCircuitsConstructor
    |
      this = locSource and
      isIntegerParameterOfCall(locSource, qc, 0)
    )
  }

  /** Returns an index of the qubit in the register. */
  override int getAnIndexIfAny() {
    // qc = QuantumCircuit(4, 3)
    // >> [0, 1, 2, 3]
    exists(QuantumCircuit qc, DataFlow::LocalSourceNode locSource, int i |
      qc instanceof QuantumCircuitConstructor or
      qc instanceof BuiltinParametrizedCircuitsConstructor
    |
      this = locSource and
      isIntegerParameterOfCall(locSource, qc, 0) and
      i in [0 .. qc.getNumberOfQubits() - 1] and
      result = i
    )
  }

  override RegisterV2 getARegister() {
    exists(QuantumCircuit qc, DataFlow::LocalSourceNode locSource |
      qc instanceof QuantumCircuitConstructor or
      qc instanceof BuiltinParametrizedCircuitsConstructor
    |
      this = locSource and
      isIntegerParameterOfCall(locSource, qc, 0) and
      result = qc
    )
  }

  override QuantumCircuit getACircuit() {
    exists(QuantumCircuit qc, DataFlow::LocalSourceNode locSource |
      qc instanceof QuantumCircuitConstructor or
      qc instanceof BuiltinParametrizedCircuitsConstructor
    |
      this = locSource and
      isIntegerParameterOfCall(locSource, qc, 0) and
      result = qc
    )
  }
}

/** Clbit generated implicitly by QuantumCircuit(). */
class ImplicitCircuitClbitDefinition extends BitDefinition, ClbitDefinition {
  ImplicitCircuitClbitDefinition() {
    exists(QuantumCircuit qc, DataFlow::LocalSourceNode locSource |
      qc instanceof QuantumCircuitConstructor
    |
      this = locSource and
      isIntegerParameterOfCall(locSource, qc, 1)
    )
  }

  /** Returns an index of the clbit in the register. */
  override int getAnIndexIfAny() {
    // qc = QuantumCircuit(4, 3)
    // >> [0, 1, 2]
    exists(QuantumCircuit qc, DataFlow::LocalSourceNode locSource, int i |
      qc instanceof QuantumCircuitConstructor
    |
      this = locSource and
      isIntegerParameterOfCall(locSource, qc, 1) and
      i in [0 .. qc.getNumberOfClassicalBits() - 1] and
      result = i
    )
  }

  override RegisterV2 getARegister() {
    exists(QuantumCircuit qc, DataFlow::LocalSourceNode locSource |
      qc instanceof QuantumCircuitConstructor
    |
      this = locSource and
      isIntegerParameterOfCall(locSource, qc, 1) and
      result = qc
    )
  }

  override QuantumCircuit getACircuit() {
    exists(QuantumCircuit qc, DataFlow::LocalSourceNode locSource |
      qc instanceof QuantumCircuitConstructor
    |
      this = locSource and
      isIntegerParameterOfCall(locSource, qc, 1) and
      result = qc
    )
  }
}

/** Bits generated implicitly by QuantumRegister() and ClassicalRegister(). */
abstract class ImplicitRegisterBitDefinition extends BitDefinition {
  /** Returns an index of the bit in the register. */
  override int getAnIndexIfAny() {
    exists(int i | i in [0 .. this.(RegisterV2).getSize() - 1] | result = i)
  }

  /** Returns the register of the bit. */
  override RegisterV2 getARegister() { result = this }

  /** Returns the circuit in which the bit is added. */
  override QuantumCircuit getACircuit() {
    // get the circuit from the register
    result = this.getARegister().getACircuit()
  }
}

/** Qubit generated implicitly by QuantumRegister(). */
class ImplicitRegisterQubitDefinition extends ImplicitRegisterBitDefinition, QubitDefinition {
  ImplicitRegisterQubitDefinition() {
    exists(QuantumRegisterV2 qreg, int i | i in [0 .. qreg.getSize() - 1] | this = qreg)
  }
}

/** Clbit generated implicity by ClassicalRegister() */
class ImplicitRegisterClbitDefinition extends ImplicitRegisterBitDefinition, ClbitDefinition {
  ImplicitRegisterClbitDefinition() {
    exists(ClassicalRegisterV2 creg, int i | i in [0 .. creg.getSize() - 1] | this = creg)
  }
}

// EXPLICIT INITIALIZATION OF SINGLE BITS
/** Bits generated by Qubit() or Clbit(). */
abstract class ExplicitSingleBitDefinition extends BitDefinition {
  /** Returns the name of the identifier of the bit. */
  string getName() {
    exists(AssignStmt a |
      a.contains(this.(DataFlow::CallCfgNode).getNode().getNode()) and
      result = a.getATarget().(Name).getId()
    )
  }

  /** Return the index paramer of the current bit. */
  override int getAnIndexIfAny() {
    // single_bit = Clbit(register=creg, index=2)
    result =
      this.(API::CallNode)
          .getParameter(1, "index")
          .getAValueReachingSink()
          .asExpr()
          .(IntegerLiteral)
          .getValue()
  }

  /** Returns the register of the current bit. */
  override RegisterV2 getARegister() {
    // single_bit = Clbit(register=creg, index=2)
    exists(RegisterV2 reg |
      reg.asExpr() =
        this.(API::CallNode).getParameter(0, "register").getAValueReachingSink().asExpr()
    |
      result = reg
    )
  }

  /** Returns the circuit in which the bit is added. */
  override QuantumCircuit getACircuit() {
    // get the circuit from the register
    result = this.getARegister().getACircuit()
  }
}

/** Qubit generated by Qubit(). */
class ExplicitSingleQubitDefinition extends ExplicitSingleBitDefinition, QubitDefinition {
  ExplicitSingleQubitDefinition() {
    this = API::moduleImport("qiskit").getMember("Qubit").getACall()
    or
    this = API::moduleImport("qiskit").getMember("circuit").getMember("Qubit").getACall()
  }
}

/** Clbit generated by Clbit(). */
class ExplicitSingleClbitDefinition extends ExplicitSingleBitDefinition, ClbitDefinition {
  ExplicitSingleClbitDefinition() {
    this = API::moduleImport("qiskit").getMember("Clbit").getACall()
    or
    this = API::moduleImport("qiskit").getMember("circuit").getMember("Clbit").getACall()
  }
}
