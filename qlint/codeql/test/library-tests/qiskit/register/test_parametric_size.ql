import python
import qiskit.register

from ClassicalRegister creg
where creg.get_num_bits() = 4
select creg, "Classical register '" + creg + "' has 4 bits"
