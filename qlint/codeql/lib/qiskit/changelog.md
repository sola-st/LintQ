2023.03.07
- fix missing gates `crx` and `cry` in the `Gate` class
- improved the `isAppliedAfter` in the `Gate` class to remove false positives when the circuit is re-initialized during the path connecting the two gates.

2023.03.07
- added the getVar() function to the register class to get the variable name of the register.
- added the QubitUsed abstraction to keep track of each access to a qubit, considering also the register it belongs to.

2023.03.03
- refactoring model: java style method calls
- refactoring of register to share part of it.
- removed GateQuantumOperation, substituted with a predicate isMeasurement() on a general gate.

2023.02.28
- refactoring of the Gate class. Remove the tracking of the for loop.

2023.02.21
- improve the efficiency of get_a_target_qubit() of the gate class (remove extra QuantumCircuit variable)
- improved the precision of get_a_target_qubit() of the gate class to account also for qubits which are operated on in a loop (e.g. qc.h(i)).


2023.02.20
- added is_subcircuit() method to Circuit class (by checking if it flows to the compose() or append() method of another circuit object)
- improved get_total_num_qubits() and get_total_num_bits() methods of Circuit class (by considering also the registers added add_register() method)
- in Circuit refactored get_num_qubits_with_integers() and get_num_bits_with_integers() methods to return the static size of the circuit (i.e. QuantumCircuit(2,2) or n = 7; m = 2, QuantumCircuit(n, m)).
- improved get_num_bits() and get_num_qubits() methods of Register class (by considering also local flows of integer variables, e.g. x = 5; QuantumRegister(x))