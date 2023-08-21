from qiskit import QuantumCircuit


qc_instr = QuantumCircuit(3)

qc_instr.rx(0.1, 0)
qc_instr.ry(0.2, 1)
qc_instr.rz(0.3, 2)

qc_instr.h(0)
qc_to_append = qc_instr.to_instruction()



qc_maj = QuantumCircuit(3, name="MAJ")
qc_maj.cx(0, 1)
qc_maj.cx(0, 2)
qc_maj.ccx(2, 1, 0)
maj_gate = qc_maj.to_gate()


main_qc = QuantumCircuit(3, 3)

main_qc.append(qc_to_append, [0, 1, 2])
main_qc.compose(maj_gate, [0, 1, 2], inplace=True)