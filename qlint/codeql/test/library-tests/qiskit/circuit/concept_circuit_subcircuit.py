from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister

# create the subcircuit
qreg = QuantumRegister(3)
creg = ClassicalRegister(3)
qc_subcircuit = QuantumCircuit(qreg, creg)

# create the main circuit
q = QuantumRegister(10)
c = ClassicalRegister(8)
qc_macro = QuantumCircuit()
qc_macro.add_register(q)
qc_macro.add_register(c)
qc_macro.h(1, 3, 5, 7)

# copy
qc_clone = qc_macro.copy()

# compose the two with the compose method
qc_composed = qc_macro.compose(qc_subcircuit, qubits=q, clbits=c)

# inplace composition
qc_clone.compose(qc_subcircuit, inplace=True, front=True)


def create_subcircuit():
    """
    Implicitly: what is defined in a function without a classical register
    is a subcircuit.
    """
    qreg = QuantumRegister(3)
    qc = QuantumCircuit(qreg)
    qc.h(qreg[0])
    qc.cx(qreg[0], qreg[1])
    qc.cx(qreg[1], qreg[2])
    return qc


def crete_subcircuit_via_compose():
    """
    It is subcircuit even if there is a compose call in the return statement.
    """
    qreg = QuantumRegister(3)
    qc = QuantumCircuit(qreg)
    qc.h(qreg[0])
    qc.cx(qreg[0], qreg[1])
    qc.cx(qreg[1], qreg[2])
    qc_second = QuantumCircuit(qreg)
    qc_second.ccx(0, 1, 2)
    return qc.compose(qc_second, inplace=False)


qc_subcircuit_via_subroutine = create_subcircuit()


qc_subcircuit_via_compose = crete_subcircuit_via_compose()


# when a circuit is converted to a gate or instruction, it stays a subcircuit
# conceptually because it is then used as part of larger circuits.
qc_subcircuit_via_gate = qc_subcircuit_via_subroutine.to_gate()
qc_subcircuit_via_instruction = qc_macro.to_instruction()


# when a circuit is appended to another circuit, it becomes a subcircuit
qc_clone.append(qc_macro, qargs=[1, 3, 4, 7])
qc_clone.append(qc_subcircuit_via_subroutine, qargs=[q[0], q[1], q[2]])
