# https://github.com/Z-928/Bugs4Q-Framework/blob/master/qiskit/22/buggy_22.py
from qiskit.circuit.library import ZZFeatureMap
zz = ZZFeatureMap(2, entanglement="full", reps=2)
zz.draw("mpl")
