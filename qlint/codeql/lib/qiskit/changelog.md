2023.02.20
- added is_subcircuit() method to Circuit class (by checking if it flows to the compose() or append() method of another circuit object)
- improved get_total_num_qubits() and get_total_num_bits() methods of Circuit class (by considering also the registers added add_register() method)
- in Circuit refactored get_num_qubits_with_integers() and get_num_bits_with_integers() methods to return the static size of the circuit (i.e. QuantumCircuit(2,2) or n = 7; m = 2, QuantumCircuit(n, m)).
- improved get_num_bits() and get_num_qubits() methods of Register class (by considering also local flows of integer variables, e.g. x = 5; QuantumRegister(x))