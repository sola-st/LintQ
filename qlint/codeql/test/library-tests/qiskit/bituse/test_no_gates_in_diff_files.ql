import python
import qiskit.Circuit
import qiskit.Qubit
import qiskit.QuantumDataFlow

// a qubit use can have multiple gates (e.g. when it is a QuantumRegister used in multiple gates qc.h(qreg) and qc.x(qreg))
// But it is HIGHLY unlikely that the same qreg object is used across different files.
// This led to a bug with the library code __get_item__ of the register.py class of the Qiskit library.
// This case was fixed and this query should return the empty set.


from QubitUse qbu, QuantumOperator g1, QuantumOperator g2
where
  g1 != g2 and
  g1 = qbu.getAGate() and
  g2 = qbu.getAGate() and
  g1.getLocation().getFile() != g2.getLocation().getFile()
select
  qbu, g1, g2, g1.getLocation().getFile(), g2.getLocation().getFile()