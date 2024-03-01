/**
 * @name Deprecated Circuit Method
 * @description Check if the method call on the circuit is deprecated
 * @kind problem
 * @tags correctness
 *       reliability
 *       qiskit
 * @problem.severity error
 * @precision high
 * @id ql-deprecated-circuit-method
 */

import python
import semmle.python.dataflow.new.DataFlow
import semmle.python.ApiGraphs
import qiskit.Circuit
import qiskit.Gate
import qiskit.QuantumDataFlow
import qiskit.Backend

// from QuantumCircuit qc, DataFlow::CallCfgNode idenCall
// where
//   qc.getAnAttributeRead("iden").getACall() = idenCall
// select idenCall, "The deprecated iden() API is called."

// MORE GENERAL: getting any attribute that is not a QuantumOperation
from QuantumCircuit qc, DataFlow::CallCfgNode illegalGateCall
where
  qc.getAnAttributeRead().getACall() = illegalGateCall and
  // not illegalGateCall instanceof QuantumOperator and
  // avoid matching other well known API calls
  not exists(string functionName
    |
      functionName in [
        "add_bits", "add_calibration", "add_register", "append", "assign_parameters", "barrier", "bind_parameters", "break_loop", "cast", "cbit_argument_conversion", "ccx", "ccz", "ch", "clear", "cls_instances", "cls_prefix", "cnot", "compose", "continue_loop", "control", "copy", "copy_empty_like", "count_ops", "cp", "crx", "cry", "crz", "cs", "csdg", "cswap", "csx", "cu", "cx", "cy", "cz", "dcx", "decompose", "delay", "depth", "diagonal", "draw", "ecr", "find_bit", "for_loop", "fredkin", "from_instructions", "from_qasm_file", "from_qasm_str", "get_instructions", "h", "hamiltonian", "has_calibration_for", "has_register", "i", "id", "if_else", "if_test", "initialize", "inverse", "iso", "isometry", "iswap", "mcp", "mcrx", "mcry", "mcrz", "mct", "mcx", "measure", "measure_active", "measure_all", "ms", "num_connected_components", "num_nonlocal_gates", "num_tensor_factors", "num_unitary_factors", "p", "pauli", "power", "prepare_state", "qasm", "qbit_argument_conversion", "qubit_duration", "qubit_start_time", "qubit_stop_time", "r", "rcccx", "rccx", "remove_final_measurements", "repeat", "reset", "reverse_bits", "reverse_ops", "rv", "rx", "rxx", "ry", "ryy", "rz", "rzx", "rzz", "s", "save_amplitudes", "save_amplitudes_squared", "save_clifford", "save_density_matrix", "save_expectation_value", "save_expectation_value_variance", "save_matrix_product_state", "save_probabilities", "save_probabilities_dict", "save_stabilizer", "save_state", "save_statevector", "save_statevector_dict", "save_superop", "save_unitary", "sdg", "set_density_matrix", "set_matrix_product_state", "set_stabilizer", "set_statevector", "set_superop", "set_unitary", "size", "snapshot", "squ", "swap", "sx", "sxdg", "t", "tdg", "tensor", "to_gate", "to_instruction", "toffoli", "u", "uc", "ucrx", "ucry", "ucrz", "unitary", "while_loop", "width", "x", "y", "z"]
    |
        qc.getAnAttributeRead(functionName).getACall() = illegalGateCall
    )
select illegalGateCall, "This API does not correspond to any currently available gate, it might be deprecated."
