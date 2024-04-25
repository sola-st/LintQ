# https://github.com/Z-928/Bugs4Q-Framework/blob/master/qiskit/2/buggy_2.py
from qiskit_machine_learning.datasets import ad_hoc_data



feature_dim=2
training_dataset_size=20
testing_dataset_size=10
random_seed=10598
shots=10000

sample_Total,training_input,test_input,class_labels = ad_hoc_data(training_size=training_dataset_size,
                                                               test_size=testing_dataset_size,
                                                               gap=0.3,
                                                               n=feature_dim,
                                                               plot_data=True)
