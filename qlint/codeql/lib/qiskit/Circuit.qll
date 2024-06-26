import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Register
import qiskit.Gate

/** Composition call (append() and compose()) to join two circuits. */
abstract class CompositionCall extends DataFlow::CallCfgNode { }

/** Call to the compose() api on a circuit. */
class ComposeCall extends CompositionCall {
  /**
   * Holds if the call is a compose call.
   */
  ComposeCall() {
    exists(QuantumCircuit parentCirc | this = parentCirc.getAnAttributeRead("compose").getACall())
  }

  /** Holds if the wiring of the composition is unspecified. */
  predicate isWiringUnspecified() {
    not exists(this.(API::CallNode).getParameter(1, "qubits")) and
    not exists(this.(API::CallNode).getParameter(2, "clbits"))
  }
}

/** Call to the append() api on a circuit. */
class AppendCall extends DataFlow::CallCfgNode {
  /**
   * Holds if the call is a append call.
   */
  AppendCall() {
    exists(QuantumCircuit parentCirc | this = parentCirc.getAnAttributeRead("append").getACall())
  }
}

/** Call to from_qasm_str() api. */
class FromQasmStrCall extends DataFlow::CallCfgNode {
  /**
   * Holds if the call is a from_qasm_str call.
   */
  FromQasmStrCall() {
    exists(QuantumCircuit qc | this = qc.getAnAttributeRead("from_qasm_str").getACall())
  }
}

/** Call to to_instruction. */
class ToInstructionCall extends DataFlow::CallCfgNode {
  /**
   * Holds if the call is a to_instruction call.
   */
  ToInstructionCall() {
    exists(QuantumCircuit parentCirc |
      this = parentCirc.getAnAttributeRead("to_instruction").getACall()
    )
  }
}

/** Call to to_gate. */
class ToGateCall extends DataFlow::CallCfgNode {
  /**
   * Holds if the call is a to_gate call.
   */
  ToGateCall() {
    exists(QuantumCircuit parentCirc | this = parentCirc.getAnAttributeRead("to_gate").getACall())
  }
}

/**
 * Circuit that is appended/composed to another circuit.
 *
 * Note that it includes:
 * - (actual subcircuit) circuit that are appened and compesed to circuit
 * - (potential subcircuit) circuit that are defined in a function and returned
 * - (potential subcircuit) circuit that flow to a returned statement
 * - (potential subcircuit) circuit that are called with to_instruction() or to_gate()
 */
class SubCircuit extends QuantumCircuit {
  /**
   * Holds if the circuit is appended to another circuit.
   */
  SubCircuit() {
    // qc1.append(qc_this)
    exists(AppendCall appendCall |
      appendCall.(API::CallNode).getParameter(0, "instruction").getAValueReachingSink().asExpr() =
        this.asExpr()
    )
    or
    // qc1.compose(qc_this)
    exists(ComposeCall composeCall |
      composeCall.(API::CallNode).getParameter(0, "other").getAValueReachingSink().asExpr() =
        this.asExpr()
    )
    or
    // holds if the circuit returned by a function is appended to another/composed
    // to another circuit
    exists(FunctionDef fd, Return ret, QuantumCircuit qc, DataFlow::CallCfgNode actualCall |
      // the function definition has a return statement
      fd.contains(ret) and
      // the fd is actually used somewhere
      actualCall.getFunction().asExpr().(Name).getId() = fd.getDefinedFunction().getName() and
      // same scope
      actualCall.getScope() = fd.getScope() and
      // the call reaches the append or compose call as sink
      exists(DataFlow::CallCfgNode appendOrComposeCall |
        appendOrComposeCall instanceof AppendCall and
        appendOrComposeCall
            .(API::CallNode)
            .getParameter(0, "instruction")
            .getAValueReachingSink()
            .asExpr() = actualCall.asExpr()
        or
        appendOrComposeCall instanceof ComposeCall and
        appendOrComposeCall
            .(API::CallNode)
            .getParameter(0, "other")
            .getAValueReachingSink()
            .asExpr() = actualCall.asExpr()
      ) and
      (
        // the return statement returns a QuantumCircuit
        ret.contains(qc.asExpr())
        or
        // in the return statement flows an object that is a QuantumCircuit (use local flow)
        exists(DataFlow::Node objectInReturnStatement |
          ret.contains(objectInReturnStatement.asExpr()) and
          qc.flowsTo(objectInReturnStatement)
        )
      )
    |
      this = qc
    )
    or
    // hold if the circuit is returned by a function
    exists(Return ret |
      (
        // the return statement returns a QuantumCircuit
        ret.contains(this.asExpr())
        or
        // in the return statement flows an object that is a QuantumCircuit (use local flow)
        exists(DataFlow::Node objectInReturnStatement |
          ret.contains(objectInReturnStatement.asExpr()) and
          this.flowsTo(objectInReturnStatement)
        )
      )
    )
    or
    // qc_this.to_gate()
    // qc_this.to_instruction()
    this instanceof InstructionCircuit
  }

  /** Returns one of the circuit that uses the current subcircuit. */
  QuantumCircuit getAParentCircuit() {
    exists(AppendCall appendCall, QuantumCircuit parent |
      appendCall.(API::CallNode).getParameter(0, "instruction").getAValueReachingSink().asExpr() =
        this.asExpr() and
      parent.getAnAttributeRead("append").getACall().asExpr() = appendCall.asExpr() and
      result = parent
    )
    or
    exists(ComposeCall composeCall, QuantumCircuit parent |
      composeCall.(API::CallNode).getParameter(0, "other").getAValueReachingSink().asExpr() =
        this.asExpr() and
      parent.getAnAttributeRead("compose").getACall().asExpr() = composeCall.asExpr() and
      result = parent
    )
  }

  /** Return the compose/append call that created the subcircuit relationship. */
  DataFlow::CallCfgNode getACompositionCall() { result = this.getCompositionCallWith(_) }

  /** Return the compose/append call that attached this circuit to the target circuit. */
  DataFlow::CallCfgNode getCompositionCallWith(QuantumCircuit qc) {
    exists(AppendCall appendCall |
      appendCall = qc.getAnAttributeRead("append").getACall() and
      appendCall.(API::CallNode).getParameter(0, "instruction").getAValueReachingSink().asExpr() =
        this.asExpr() and
      result = appendCall
    )
    or
    exists(ComposeCall composeCall |
      composeCall = qc.getAnAttributeRead("compose").getACall() and
      composeCall.(API::CallNode).getParameter(0, "other").getAValueReachingSink().asExpr() =
        this.asExpr() and
      result = composeCall
    )
  }
}

/** Circuit that is used as insturction/gate. */
class InstructionCircuit extends QuantumCircuit {
  /** Holds for objects that have to_instruction of to_gate calls. */
  InstructionCircuit() {
    exists(ToInstructionCall instrCall, QuantumCircuit qc |
      instrCall = qc.getAnAttributeRead("to_instruction").getACall()
    |
      this = qc
    )
    or
    exists(ToGateCall gateCall, QuantumCircuit qc |
      gateCall = qc.getAnAttributeRead("to_gate").getACall()
    |
      this = qc
    )
  }
}

/** Circuit that is called with assign_parameters. */
class ParametrizedCircuit extends DataFlow::CallCfgNode {
  /**
   * Holds if the circuit is called with assign_parameters() api.
   * TODO: support also the case where a Parameter() object is used by a gate
   * of the current circuit.
   */
  ParametrizedCircuit() {
    exists(QuantumCircuit qc, DataFlow::CallCfgNode actualCall |
      this = qc and
      actualCall = qc.getAnAttributeRead("assign_parameters").getACall()
    )
  }
}

/** Circuit created by a assign_parameters call. */
class InstanceOfParameterizedCircuit extends DataFlow::CallCfgNode {
  /**
   * Holds if the call is an assign_parameters call.
   */
  InstanceOfParameterizedCircuit() {
    exists(DataFlow::CallCfgNode unknownQc |
      // this works even if the assign_parameters call is not directly on the a
      // known circuit object.
      this = unknownQc.getAnAttributeRead("assign_parameters").getACall()
    )
  }
}

/** Call to any function call which has inplace=False or the default value. */
class ReturnsNewValue extends DataFlow::CallCfgNode {
  /**
   * Holds if the call has not inplace=True
   */
  ReturnsNewValue() {
    // Holds it is a compose call without inplace=True
    // Because if inplace=True, the circuit is modified in place,
    // thus the call represent nothing.
    not exists(DataFlow::Node parameterInplace | parameterInplace = this.getArgByName("inplace") |
      parameterInplace.asExpr().(ImmutableLiteral).booleanValue() = true
    )
  }
}

/** A constructor of built-in prametrized circuit in the Qiskit library. */
class BuiltinParametrizedCircuitsConstructor extends DataFlow::CallCfgNode {
  /**
   * Holds if the call is a predefined parametrized circuit.
   * e.g. TwoLocal(3, ['h', 'cx'], 'cz', 'full', reps=3)
   * e.g. NLocal(3, ['h', 'cx'], 'cz', 'full', reps=3)
   * e.g. RealAmplitudes(3, reps=3)
   * e.g. EfficientSU2(3, reps=3)
   * e.g. ExcitationPreserving(3, reps=3)
   * e.g. PauliTwoDesign(3, reps=3)
   * e.g. QAOAAnsatz(3, reps=3)
   * They are generally imported as follows:
   * from qiskit.circuit.library import TwoLocal, NLocal, RealAmplitudes, EfficientSU2,
   * ExcitationPreserving, PauliTwoDesign, QAOAAnsatz
   */
  BuiltinParametrizedCircuitsConstructor() {
    exists(string importName |
      importName in [
          "TwoLocal", "NLocal", "RealAmplitudes", "EfficientSU2", "ExcitationPreserving",
          "PauliTwoDesign", "QAOAAnsatz"
        ]
    |
      this =
        API::moduleImport("qiskit")
            .getMember("circuit")
            .getMember("library")
            .getMember(importName)
            .getACall()
      or
      this = API::moduleImport("qiskit").getMember(importName).getACall()
    )
  }
}

/** A call to the transpile API. */
class TranspileCall extends DataFlow::CallCfgNode {
  /**
   * Holds if the call is a transpile call.
   */
  TranspileCall() { this = API::moduleImport("qiskit").getMember("transpile").getACall() }
}

/** A call to the assemble API. */
class AssembleCall extends DataFlow::CallCfgNode {
  /**
   * Holds if the call is a assemble call.
   */
  AssembleCall() { this = API::moduleImport("qiskit").getMember("assemble").getACall() }
}

/** A call to the execute API. */
class ExecuteCall extends DataFlow::CallCfgNode {
  /**
   * Holds if the call is a execute call.
   */
  ExecuteCall() { this = API::moduleImport("qiskit").getMember("execute").getACall() }
}

/** A constructor to QuantumCircuit API. */
class QuantumCircuitConstructor extends DataFlow::CallCfgNode {
  /**
   * Holds if the call is a QuantumCircuit constructor call.
   */
  QuantumCircuitConstructor() {
    this = API::moduleImport("qiskit").getMember("QuantumCircuit").getACall()
    or
    // from qiskit.circuit import QuantumCircuit
    this = API::moduleImport("qiskit").getMember("circuit").getMember("QuantumCircuit").getACall()
  }
}

/** A call to .copy() on a circuit object. */
class CopyCircuitCall extends DataFlow::CallCfgNode {
  /**
   * Holds if the call is a clone call.
   */
  CopyCircuitCall() {
    exists(QuantumCircuit parentCirc | this = parentCirc.getAnAttributeRead("copy").getACall())
  }

  /** Returns the original circuit that is copied. */
  QuantumCircuit getOriginalCircuit() {
    exists(QuantumCircuit parentCirc |
      this = parentCirc.getAnAttributeRead("copy").getACall() and
      result = parentCirc
    )
  }
}

/** A function definition that returns a circuit object. */
class UDFFunctionDefReturningAQuantumCircuit extends FunctionDef {
  /**
   * Holds if the function def returns a quantum circuit.
   */
  UDFFunctionDefReturningAQuantumCircuit() {
    exists(FunctionDef fd, Return ret, QuantumCircuit qc |
      // the function definition has a return statement
      fd.contains(ret) and
      (
        // the return statement returns a QuantumCircuit
        ret.contains(qc.asExpr())
        or
        // in the return statement flows an object that is a QuantumCircuit (use local flow)
        exists(DataFlow::Node objectInReturnStatement |
          ret.contains(objectInReturnStatement.asExpr()) and
          qc.flowsTo(objectInReturnStatement)
        )
      )
    |
      this = fd
    )
  }

  /** The circuit returned in the UDF function. */
  QuantumCircuit getCircuitInLocalScope() {
    exists(Return ret, QuantumCircuit qc |
      // the function definition has a return statement
      this.contains(ret) and
      (
        // the return statement returns a QuantumCircuit
        ret.contains(qc.asExpr())
        or
        // in the return statement flows an object that is a QuantumCircuit (use local flow)
        exists(DataFlow::Node objectInReturnStatement |
          ret.contains(objectInReturnStatement.asExpr()) and
          qc.flowsTo(objectInReturnStatement)
        )
      )
    |
      result = qc
    )
  }

  /** Get a call to this function definition. It has to be in the same scope. */
  DataFlow::CallCfgNode getACall() {
    exists(DataFlow::CallCfgNode call |
      call.getFunction().asExpr().(Name).getId() = this.getDefinedFunction().getName() and
      // same scope
      call.getScope() = this.getScope()
    |
      result = call
    )
  }
}

/** A call to a UDF function that returns a circuit object. */
class UDFCallReturningAQuantumCircuit extends DataFlow::CallCfgNode {
  /**
   * Holds if the call returns a QuantumCircuit
   */
  UDFCallReturningAQuantumCircuit() {
    exists(UDFFunctionDefReturningAQuantumCircuit fd | this = fd.getACall())
  }
}

// QUANTUM CIRCUIT AND ITS PROPER SUBCLASSES
/** A call to ANY function that returns a circuit object. */
class QuantumCircuit extends DataFlow::CallCfgNode {
  /**
   * Holds if the call returns a QuantumCircuit
   *
   * Some examples:
   * e.g. qc = QuantumCircuit(2, 3)
   * e.g. qc = transpile(circuit, backend)
   * e.g. qc = qc1.compose(qc2)
   * e.g. qc = qc1.copy()
   * e.g. qc = TwoLocal(3, ['h', 'cx'], 'cz', 'full', reps=3)
   * // TODO e.g. qc = qc1.decompose()
   * // TODO e.g. qc = qc1 + qc2
   */
  QuantumCircuit() {
    (
      this instanceof ComposeCall
      or
      this instanceof CopyCircuitCall
      or
      this instanceof BuiltinParametrizedCircuitsConstructor
      or
      this instanceof TranspileCall
      or
      this instanceof QuantumCircuitConstructor
      or
      this instanceof UDFCallReturningAQuantumCircuit
      or
      this instanceof InstanceOfParameterizedCircuit
    ) and
    this instanceof ReturnsNewValue
  }

  /** Returns the name of the identifier of the circuit. */
  string getName() {
    exists(AssignStmt a |
      a.contains(this.getNode().getNode()) and
      result = a.getATarget().(Name).getId()
    )
  }

  /** Returns the number of classical bits of the circuit (via integer), 0 if none. */
  private int get_num_bits_with_integers() {
    // get the number of bits as created with integrer literals
    // e.g. QuantumCircuit(2, 3)
    // the number of bits is 3
    // e.g. n = 4, QuantumCircuit(2, n)
    // the number of bits is 4
    if
      not exists(IntegerLiteral num_bits, DataFlow::LocalSourceNode source |
        source.flowsTo(this.getArg(1)) and
        source.asExpr() = num_bits
      )
    then result = 0
    else
      exists(IntegerLiteral num_bits, DataFlow::LocalSourceNode source |
        source.flowsTo(this.getArg(1)) and
        source.asExpr() = num_bits
      |
        result = num_bits.getValue()
      )
  }

  /** Returns the number of classical bits of the circuit (via registers), 0 if none. */
  private int get_num_bits_from_registers() {
    // get the number of bits as created with initialized registers
    // creg = ClassicalRegister(3, 'c')
    // qc = QuantumCircuit(2, creg)
    // the number of bits is 3
    if
      not exists(ClassicalRegisterV2 clsReg |
        clsReg.flowsTo(this.getArg(_))
        or
        // there is a this.add_register() call with clsReg as argument
        exists(DataFlow::CallCfgNode addRegisterCall |
          addRegisterCall = this.getAnAttributeRead("add_register").getACall() and
          clsReg.flowsTo(addRegisterCall.getArg(0))
        )
      )
    then result = 0
    else
      result =
        sum(ClassicalRegisterV2 clsReg |
          clsReg.flowsTo(this.getArg(_))
          or
          // there is a this.add_register() call with clsReg as argument
          exists(DataFlow::CallCfgNode addRegisterCall |
            addRegisterCall = this.getAnAttributeRead("add_register").getACall() and
            clsReg.flowsTo(addRegisterCall.getArg(0))
          )
        |
          clsReg.getSize()
        )
  }

  int getNumberOfClassicalBits() {
    (
      if
        this instanceof CopyCircuitCall and
        this.get_num_bits_from_registers() = 0 and
        this.get_num_bits_with_integers() = 0
      then
        // if it is a copy of another circuit, return the number of classical bits
        // of the original circuit
        exists(QuantumCircuit originalCirc |
          originalCirc = this.(CopyCircuitCall).getOriginalCircuit()
        |
          result = originalCirc.getNumberOfClassicalBits()
        )
      else
        exists(int num_bits_from_registers, int num_bits_with_integers |
          num_bits_from_registers = this.get_num_bits_from_registers() and
          num_bits_with_integers = this.get_num_bits_with_integers()
        |
          result = num_bits_from_registers + num_bits_with_integers
        )
    )
    or
    // if there is only a classical register
    exists(int num_bits_from_registers |
      num_bits_from_registers = this.get_num_bits_from_registers() and
      not exists(int num_bits_with_integers |
        num_bits_with_integers = this.get_num_bits_with_integers()
      )
    |
      result = num_bits_from_registers
    )
    or
    // if there is only a number of bits
    exists(int num_bits_with_integers |
      num_bits_with_integers = this.get_num_bits_with_integers() and
      not exists(int num_bits_from_registers |
        num_bits_from_registers = this.get_num_bits_from_registers()
      )
    |
      result = num_bits_with_integers
    )
  }

  /** Returns the number of qubits of the circuit (via intger), 0 if none. */
  private int get_num_qubits_with_integers() {
    // if there is no integer literal, return 0
    if
      not exists(IntegerLiteral num_qubits, DataFlow::LocalSourceNode source |
        source.flowsTo(this.getArg(0)) and
        source.asExpr() = num_qubits
      )
    then result = 0
    else
      exists(IntegerLiteral num_qubits, DataFlow::LocalSourceNode source |
        source.flowsTo(this.getArg(0)) and
        source.asExpr() = num_qubits
      |
        result = num_qubits.getValue()
      )
  }

  /** Returns the number of qubits of the circuit (via registers), 0 if none. */
  private int get_num_qubits_from_registers() {
    // if there is no quantum register, return 0
    if
      not exists(QuantumRegisterV2 qntReg |
        exists(int i | qntReg.flowsTo(this.getArg(i)))
        or
        // there is a this.add_register() call with qntReg as argument
        exists(DataFlow::CallCfgNode addRegisterCall |
          addRegisterCall = this.getAnAttributeRead("add_register").getACall() and
          qntReg.flowsTo(addRegisterCall.getArg(0))
        )
      )
    then result = 0
    else
      result =
        sum(QuantumRegisterV2 qntReg |
          exists(int i | qntReg.flowsTo(this.getArg(i)))
          or
          // there is a this.add_register() call with qntReg as argument
          exists(DataFlow::CallCfgNode addRegisterCall |
            addRegisterCall = this.getAnAttributeRead("add_register").getACall() and
            qntReg.flowsTo(addRegisterCall.getArg(0))
          )
        |
          qntReg.getSize()
        )
  }

  /** Holds if there is at least one unresolved size register. */
  predicate hasUnresolvedSizeRegister() {
    exists(DataFlow::LocalSourceNode someUnknown |
      // something is used in the constructor QuantumCircuit(2, someUnknown)
      (
        someUnknown.flowsTo(this.getArg(_))
        or
        exists(DataFlow::CallCfgNode addRegisterCall |
          addRegisterCall = this.getAnAttributeRead("add_register").getACall() and
          someUnknown.flowsTo(addRegisterCall.getArg(0))
        )
      ) and
      // nor a register nor an integer literal
      not someUnknown instanceof RegisterV2 and
      not someUnknown.asExpr() instanceof IntegerLiteral
    )
  }

  int getNumberOfQubits() {
    (
      if
        this instanceof CopyCircuitCall and
        this.get_num_qubits_from_registers() = 0 and
        this.get_num_qubits_with_integers() = 0
      then
        // if it is a copy of another circuit, return the number of quantum bits
        // of the original circuit
        exists(QuantumCircuit originalCirc |
          originalCirc = this.(CopyCircuitCall).getOriginalCircuit()
        |
          result = originalCirc.getNumberOfQubits()
        )
      else
        exists(int num_qubits_from_registers, int num_qubits_with_integers |
          num_qubits_from_registers = this.get_num_qubits_from_registers() and
          num_qubits_with_integers = this.get_num_qubits_with_integers()
        |
          result = num_qubits_from_registers + num_qubits_with_integers
        )
    )
    or
    // if there is only a quantum register
    exists(int num_qubits_from_registers |
      num_qubits_from_registers = this.get_num_qubits_from_registers() and
      not exists(int num_qubits_with_integers |
        num_qubits_with_integers = this.get_num_qubits_with_integers()
      )
    |
      result = num_qubits_from_registers
    )
    or
    // if there is only a number of qubits
    exists(int num_qubits_with_integers |
      num_qubits_with_integers = this.get_num_qubits_with_integers() and
      not exists(int num_qubits_from_registers |
        num_qubits_from_registers = this.get_num_qubits_from_registers()
      )
    |
      result = num_qubits_with_integers
    )
  }

  predicate isSubCircuit() { this instanceof SubCircuit }

  predicate isSubCircuitOf(QuantumCircuit other) {
    this != other and
    this instanceof SubCircuit and
    this.(SubCircuit).getAParentCircuit() = other
  }

  /** Holds if the modeling was not able to derive the number of qubits. */
  predicate hasUnknonNumberOfQubits() { this.getNumberOfQubits() = 0 }

  /** Holds if the modeling was not able to derive the number of classical bits. */
  predicate hasUnknonNumberOfClassicalBits() { this.getNumberOfClassicalBits() = 0 }

  QuantumOperator getAGate() {
    exists(QuantumOperator g | g.getQuantumCircuit() = this | result = g)
  }

  //* Returns a QuantumRegister added to a circuit. */
  QuantumRegisterV2 getAQuantumRegister() {
    exists(QuantumRegisterV2 qntReg, int i | qntReg.flowsTo(this.getArg(i)) | result = qntReg)
    or
    // there is a this.add_register() call with qntReg as argument
    exists(QuantumRegisterV2 qntReg, DataFlow::CallCfgNode addRegisterCall |
      addRegisterCall = this.getAnAttributeRead("add_register").getACall() and
      qntReg.flowsTo(addRegisterCall.getArg(0))
    |
      result = qntReg
    )
  }

  ClassicalRegisterV2 getAClassicalRegister() {
    exists(ClassicalRegisterV2 clsReg, int i | clsReg.flowsTo(this.getArg(i)) | result = clsReg)
    or
    // there is a this.add_register() call with clsReg as argument
    exists(ClassicalRegisterV2 clsReg, DataFlow::CallCfgNode addRegisterCall |
      addRegisterCall = this.getAnAttributeRead("add_register").getACall() and
      clsReg.flowsTo(addRegisterCall.getArg(0))
    |
      result = clsReg
    )
  }
}

// QUANTUM CIRCUIT SUBCLASSES
/** A circuit generated by a transpile API. */
class TranspiledCircuit extends QuantumCircuit {
  TranspiledCircuit() { this instanceof TranspileCall }

  int getOptimizationLvl() {
    result =
      this.(API::CallNode)
          .getParameter(7, "optimization_level")
          .getAValueReachingSink()
          .asExpr()
          .(IntegerLiteral)
          .getValue()
  }

  override int getNumberOfQubits() {
    exists(QuantumCircuit qc |
      qc = this.(API::CallNode).getParameter(0, "circuits").getAValueReachingSink()
    |
      result = qc.getNumberOfQubits()
    )
  }

  override int getNumberOfClassicalBits() {
    exists(QuantumCircuit qc |
      qc = this.(API::CallNode).getParameter(0, "circuits").getAValueReachingSink()
    |
      result = qc.getNumberOfClassicalBits()
    )
  }
}

/** A circuit object created via a user-defined function. */
class UDFQuantumCircuit extends QuantumCircuit {
  /**
   * Holds if the call returns a QuantumCircuit
   */
  UDFQuantumCircuit() { this instanceof UDFCallReturningAQuantumCircuit }

  override int getNumberOfQubits() {
    exists(UDFFunctionDefReturningAQuantumCircuit fd | this = fd.getACall() |
      result = fd.getCircuitInLocalScope().getNumberOfQubits()
    )
  }

  override int getNumberOfClassicalBits() {
    exists(UDFFunctionDefReturningAQuantumCircuit fd | this = fd.getACall() |
      result = fd.getCircuitInLocalScope().getNumberOfClassicalBits()
    )
  }
}

/** A circuit returned by a compose API. */
class ComposedCircuit extends QuantumCircuit {
  ComposedCircuit() { this instanceof ComposeCall }

  override int getNumberOfQubits() {
    exists(QuantumCircuit parentCirc | this = parentCirc.getAnAttributeRead("compose").getACall() |
      result = parentCirc.getNumberOfQubits()
    )
  }

  override int getNumberOfClassicalBits() {
    exists(QuantumCircuit parentCirc | this = parentCirc.getAnAttributeRead("compose").getACall() |
      result = parentCirc.getNumberOfClassicalBits()
    )
  }
}
