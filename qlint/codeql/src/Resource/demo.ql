
import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.register

// given a quantum register,
// returns all the locations where the qubits of that register are accessed

// from
//     SubscriptNode subscript,
// select
//     subscript.getNode(),
//     subscript.getObject(),
//     subscript.getObject().getNode(),
//     subscript.getIndex()


from
    // general syntactinc node
    DataFlow::Node node,

    // AstNode astNode,
    Subscript subscript,

    //DataFlow::CallCfgNode
    QuantumRegister qntReg,

    DataFlow::ExprNode targetSubscript,
    IntegerLiteral qubit
where
    qntReg.flowsTo(node) and
    node.asExpr() = targetSubscript.asExpr() and
    targetSubscript.asExpr() = subscript.getObject() and
    subscript.getIndex() = qubit
select
    node, qntReg, targetSubscript, qubit.getValue()