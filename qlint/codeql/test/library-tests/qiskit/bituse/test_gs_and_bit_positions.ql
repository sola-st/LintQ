import python
import qiskit.BitUse
import qiskit.Circuit

from GateSpecification gs
select gs,
  "gate specification: " + gs.getName() + " - name qubit: " + gs.getAnArgumentNameOfQubit() +
    " - index qubit: " + gs.getAnArgumentIndexOfQubit()
// + " - name param : " + gs.getAnArgumentNameOfParam() + " - index param: " + gs.getAnArgumentIndexOfParam() + " "
