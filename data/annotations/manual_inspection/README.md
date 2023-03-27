# Relevant Columns
Here we describe briefly the important columns of the manual inspection dataset.

- **url**: The URL of the code on GitHub
- **problem_id**: The unique id of the warning. This corresponds also to the name of the markdown issue file.
- **snippet**: some relevant part of the code to recall where the problem was, it is not intended to be precise, sometime it is arbitrarly summariezed.
- **unique_id**: the filename
- **experiment**: the experiment version that first generated the warning
- **detector_rule**: the detector rule that generated the warning
- **triage**: the triage status of the warning according to our manual inspection
- **intended_behavior**: the intended behavior of the code based on the context.
- **more_info**: additional info that either justify the triage or give more info on the specific use of the problematic construct/code.
- **problem_description**: the description of the problem (for true positives) or the reason why LintQ cannot correctly discern this case (for false positives).


