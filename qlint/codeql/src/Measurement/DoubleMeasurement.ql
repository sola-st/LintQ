/**
 * @name Double measurement on the same qubit.
 * @description two consecutive measurements on the same qubit of a given circuit.
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision high
 * @id QL102-DoubleMeasurement
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs


from
    ControlFlowNode firstMeasure,
    ControlFlowNode secondMeasure,
    Expr firstMeasureCallExpr,
    Expr secondMeasureCallExpr,
    DataFlow::CallCfgNode quantumCirc,
    ExprStmt firstMeasureStmt,
    ExprStmt secondMeasureStmt,
    CallNode firstMeasureCall,
    CallNode secondMeasureCall,
    IntegerLiteral firstMeasuredBit,
    IntegerLiteral secondMeasuredBit
    // CallNode firstRegisterAccessCall,
    // CallNode secondRegisterAccessCall
where
    // make sure the two measure come one after the other
    //firstMeasure.getASuccessor() = secondMeasure
    firstMeasure.strictlyReaches(secondMeasure)
    // make sure that we have two distinct statements (not completely correct)
    // improvment point: consider also when we have a for loop with two measurements
    //and not firstMeasureStmt = secondMeasureStmt
    // make sure they are both measruement statements
    and quantumCirc = API::moduleImport("qiskit").getMember("QuantumCircuit").getACall()
    // make sure that the the circuit and the two statemetns happen in the same context,
    // this might become outdated
    and firstMeasure.getScope() = quantumCirc.getScope()
    // the measure statements must be the same of the control flow
    // and firstMeasureStmt.getAFlowNode() = firstMeasure
    // and secondMeasureStmt.getAFlowNode() = secondMeasure
    and firstMeasureStmt.contains(firstMeasure.getNode())
    and secondMeasureStmt.contains(secondMeasure.getNode())
    // the measure statement must also contain the measure usage
    and firstMeasureCallExpr = quantumCirc.getAnAttributeRead("measure").getACall().asExpr()
    and firstMeasureStmt.contains(firstMeasureCallExpr)
    and secondMeasureCallExpr = quantumCirc.getAnAttributeRead("measure").getACall().asExpr()
    and secondMeasureStmt.contains(secondMeasureCallExpr)
    // connect the measures and the control flow nodes
    and firstMeasure.getNode() = firstMeasureCallExpr
    and secondMeasure.getNode() = secondMeasureCallExpr
    // filter and keep only the measrue calls
    and firstMeasure instanceof CallNode
    and secondMeasure instanceof CallNode
    // they measure the same qubit
    and firstMeasureStmt.contains(firstMeasureCall.getNode())
    and secondMeasureStmt.contains(secondMeasureCall.getNode())
    //too strict only working in loops
    // and firstMeasureCall.getArg(0) = secondMeasureCall.getArg(0)



    // OPTION 1: we have constants
    // qc.measure(qreg[0], creg[2])
    // qc.measure(qreg[0], creg[4])

    // they use the same register
    and
    (
       exists(
            DataFlow::CallCfgNode quantumReg,
            DataFlow::ExprNode firstRegisterAccess,
            DataFlow::ExprNode secondRegisterAccess,
            SubscriptNode positionAccessFirstMeasurement,
            SubscriptNode positionAccessSecondMeasurement |
                firstMeasureCall.getArg(0).getAChild() = firstRegisterAccess.getNode()
                and secondMeasureCall.getArg(0).getAChild() = secondRegisterAccess.getNode()
                and quantumReg = API::moduleImport("qiskit").getMember("QuantumRegister").getACall()
                and quantumReg.(DataFlow::LocalSourceNode).flowsTo(firstRegisterAccess)
                and quantumReg.(DataFlow::LocalSourceNode).flowsTo(secondRegisterAccess)
                // connect ast call and dataflow of the register access
                and firstMeasureCall.getArg(0) = positionAccessFirstMeasurement
                and secondMeasureCall.getArg(0) = positionAccessSecondMeasurement
                and positionAccessFirstMeasurement.getNode().getIndex() = firstMeasuredBit
                and positionAccessSecondMeasurement.getNode().getIndex() = secondMeasuredBit
                and firstMeasuredBit.getValue() = secondMeasuredBit.getValue()
        )

        // OPTION 2: we have constants
        // qc.measure(0, 2)
        // qc.measure(0, 4)
        or

        (
            firstMeasureCall.getArg(0).isLiteral()
            and secondMeasureCall.getArg(0).isLiteral()
            and firstMeasureCall.getArg(0).getNode() = firstMeasuredBit
            and secondMeasureCall.getArg(0).getNode() = secondMeasuredBit
            and firstMeasuredBit.getValue() = secondMeasuredBit.getValue()
        )

    )

select
    quantumCirc, "consecutive measurements on the same circuit",
    firstMeasure, "First measurement",
    secondMeasure, "Second measurement",
    firstMeasureCall, "First call to measure",
    secondMeasureCall, "second call to measure",
    // positionAccessFirstMeasurement, "pos 1",
    // positionAccessSecondMeasurement, "pos 2",
    firstMeasuredBit.getValue(), "index first reg measured",
    secondMeasuredBit.getValue(), "second first reg measured"
    // positionAccessFirstMeasurement, "first superscript parent node"

// IMPROVEMENT POINTS:

// - avoid  cases like this with parametric stuff.
//    for i in range(3):
//        qc.measure(qr[i], cr[i])
