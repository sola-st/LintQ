import python
import qiskit.Circuit
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
// import Variables.Definition
import semmle.python.dataflow.new.TaintTracking

// /**
//  * DEPRECATED - use RegisterV2 instead.
//  *
//  * Classical and quantum register identified by their allocation site as dataflow.
//  */
// abstract deprecated class RegisterSeed extends DataFlow::CallCfgNode {
//   // the register object can be accessed by the name of the variable
//   // and an index. For example: reg[0] or reg[x]
//   // we want to a general node representing one of this accesses
//   int getSize() {
//     exists(IntegerLiteral size, DataFlow::LocalSourceNode source |
//       source.flowsTo(this.getArg(0)) and
//       source.asExpr() = size
//     |
//       result = size.getValue()
//     )
//   }
//   // TODO rename hasKnownSize
//   //* Holds if the circuit has integer parameter. */
//   predicate hasIntegerParameter() {
//     exists(DataFlow::LocalSourceNode source | source.flowsTo(this.getArg(0)) |
//       source.asExpr() instanceof IntegerLiteral
//     )
//   }
//   // int getAnAccessedPosition() {
//   //   exists(
//   //     DataFlow::Node nd, DataFlow::ExprNode targetSubscript, Subscript subscript,
//   //     IntegerLiteral position
//   //   |
//   //     this.flowsTo(nd) and
//   //     nd.asExpr() = targetSubscript.asExpr() and
//   //     targetSubscript.asExpr() = subscript.getObject() and
//   //     position = subscript.getIndex()
//   //   |
//   //     result = position.getValue()
//   //   )
//   // }
//   // Variable getVar() {
//   //   // get the left side of the assignment
//   //   // e.g. reg = QuantumRegister(2)
//   //   // reg is the name of the register
//   //   exists(Variable var, AssignStmt assignStmt |
//   //     // ,
//   //     // Scope same_scope
//   //     //var.getAStore() = this.asExpr()
//   //     //and
//   //     assignStmt.getValue() = this.asExpr() and
//   //     // and this.getScope() = same_scope
//   //     // and var.getScope() = same_scope
//   //     // and assignStmt.getScope() = same_scope
//   //     assignStmt.getATarget() = var.getAStore()
//   //   |
//   //     // return the left side of the assignment, namely the reference
//   //     // to the NameNode
//   //     result = var
//   //   )
//   // }
//   // /** Gets a index/position available in this register as int.*/
//   // int getAQubitIndex() {
//   //     exists(
//   //         int i
//   //         |
//   //         i = [0 .. this.getSize() - 1]
//   //         |
//   //         result = i
//   //     )
//   // }
// }
// /**
//  * DEPRECATED - use QuantumRegisterV2 instead.
//  */
// class ClassicalRegisterSeed extends RegisterSeed {
//   ClassicalRegisterSeed() {
//     this = API::moduleImport("qiskit").getMember("ClassicalRegister").getACall()
//   }
// }
// /**
//  * DEPRECATED - use ClassicalRegisterV2 instead.
//  */
// class QuantumRegisterSeed extends RegisterSeed {
//   QuantumRegisterSeed() { this = API::moduleImport("qiskit").getMember("QuantumRegister").getACall() }
// }
// REGISTER
/** Classical and quantum register identified by their allocation site as dataflow. */
abstract class RegisterV2 extends DataFlow::CallCfgNode {
  /** Returns the size of the register. */
  int getSize() {
    // register = QuantumRegister(size=2)
    // >> 2
    result =
      this.(API::CallNode)
          .getParameter(0, "size")
          .getAValueReachingSink()
          .asExpr()
          .(IntegerLiteral)
          .getValue()
  }

  /** Returns true if the size of the register is known. */
  predicate hasKnownSize() {
    // register = QuantumRegister(size=2)
    // >> true
    // x = external_call()
    // register = QuantumRegister(size=x)
    // >> false
    exists(int size | this.getSize() = size)
  }

  /** Returns the name of the identifier of the register. */
  string getName() {
    exists(AssignStmt a |
      a.contains(this.getNode().getNode()) and
      result = a.getATarget().(Name).getId()
    )
  }

  /** Returns the identifier of the register. */
  Variable getVar() {
    // get the left side of the assignment
    // reg = QuantumRegister(2)
    // >> reg
    exists(Variable var, AssignStmt assignStmt |
      assignStmt.getValue() = this.asExpr() and
      assignStmt.getATarget() = var.getAStore()
    |
      result = var
    )
  }

  /** Returns the circuit in which the register is added. */
  QuantumCircuit getACircuit() {
    // reg = QuantumRegister(2)
    // qc.add_register(reg)
    // >> qc
    // qc2 = QuantumCircuit(reg)
    // >> qc2
    exists(QuantumCircuit qc, int i | this.flowsTo(qc.getArg(i)) | result = qc)
    or
    // there is a this.add_register() call
    exists(QuantumCircuit qc, DataFlow::CallCfgNode addRegisterCall |
      addRegisterCall = qc.getAnAttributeRead("add_register").getACall() and
      this.flowsTo(addRegisterCall.getArg(0))
    |
      result = qc
    )
  }

  /** Resolves slices of registers. */
  int resolveSlice(Slice slice) {
    exists(int i, int startValue, int endValue, int maxRegSize |
      // bound the size of the register
      maxRegSize = this.getSize() and
      (
        // case:
        // qreg[0:2]
        // >> [0, 1]
        exists(
          DataFlow::LocalSourceNode sourceStart, DataFlow::Node sinkStart,
          DataFlow::LocalSourceNode sourceEnd, DataFlow::Node sinkEnd
        |
          // START
          sourceStart.asExpr() = slice.getStart() and
          sourceStart.flowsTo(sinkStart) and
          // END
          sourceEnd.asExpr() = slice.getStop() and
          sourceEnd.flowsTo(sinkEnd) and
          // BOTH PART OF THE TWO SIDES OF THE EXPRESSION
          slice.getStart() = sinkStart.asExpr() and
          slice.getStop() = sinkEnd.asExpr() and
          // START
          startValue = sourceStart.asExpr().(IntegerLiteral).getValue() and
          // END
          endValue = sourceEnd.asExpr().(IntegerLiteral).getValue()
        )
        or
        // case:
        // qreg[:4]
        // >> [0, 1, 2, 3]
        exists(DataFlow::LocalSourceNode sourceEnd, DataFlow::Node sinkEnd |
          // END
          sourceEnd.asExpr() = slice.getStop() and
          sourceEnd.flowsTo(sinkEnd) and
          // END
          slice.getStop() = sinkEnd.asExpr() and
          // END
          endValue = sourceEnd.asExpr().(IntegerLiteral).getValue() and
          // implicit
          not exists(Expr start | start = slice.getStart()) and
          startValue = 0
        )
        or
        // case:
        // qreg[2:] (with qreg of size 7)
        // >> [2, 3, 4, 5, 6]
        exists(DataFlow::LocalSourceNode sourceStart, DataFlow::Node sinkStart |
          // START
          sourceStart.asExpr() = slice.getStart() and
          sourceStart.flowsTo(sinkStart) and
          // START
          slice.getStart() = sinkStart.asExpr() and
          // START
          startValue = sourceStart.asExpr().(IntegerLiteral).getValue() and
          // implicit
          not exists(Expr end | end = slice.getStop()) and
          endValue = maxRegSize
        )
        or
        // case:
        // qreg[:]
        // >> [0, 1, 2, 3, 4, 5, 6]
        not exists(Expr start | start = slice.getStart()) and
        not exists(Expr end | end = slice.getStop()) and
        startValue = 0 and
        endValue = maxRegSize
      ) and
      i in [startValue .. endValue - 1] and
      result = i
    )
  }
}

/** Qubits generated by QuantumRegister(). */
class QuantumRegisterV2 extends RegisterV2 {
  QuantumRegisterV2() {
    this = API::moduleImport("qiskit").getMember("QuantumRegister").getACall()
    or
    this = API::moduleImport("qiskit").getMember("circuit").getMember("QuantumRegister").getACall()
  }
}

/** Clbits generated by ClassicalRegister(). */
class ClassicalRegisterV2 extends RegisterV2 {
  ClassicalRegisterV2() {
    this = API::moduleImport("qiskit").getMember("ClassicalRegister").getACall()
    or
    this =
      API::moduleImport("qiskit").getMember("circuit").getMember("ClassicalRegister").getACall()
  }
}
