import os,sys
#import qiskit
import json, re

def get_args(opt):
    left_flag = 0
    right_flag = 0
    args_string = ''
    for char in opt:
        if char == '(':
            left_flag += 1
        if char == ')':
            right_flag += 1
        if left_flag == right_flag and right_flag > 0:
            break
        if left_flag > right_flag:
            args_string = args_string + char
    return args_string[1:].split(',')

def get_values(args, var_list):
    values = []
    for arg in args:
        value = arg
        for assigns in var_list:
            if arg == assigns[0]:
                value = assigns[1]
                break
        values.append(value)
    return values

def get_keywords(args, values):
    new_args = []
    new_values = []
    for arg, value in zip(args, values):
        if '=' in arg:
            new_args.append(arg.split('=')[0])
            new_values.append(arg.split('=')[1])
        else:
            new_args.append(arg)
            new_values.append(value)
    return new_args, new_values

def checker_IIS(var_list, att_line_numbers, opt_list, opt_line_numbers):

    # check the init qubits numbers for the qasm_simulator beckend
    for opt, lineno in zip(opt_list, opt_line_numbers):
        if 'execute' in opt:
            args = get_args(opt)
            values = get_values(args, var_list)
            for value in values:
                if 'qasm_simulator' in value:
                    for value in values:
                        if 'get_circuit' in value:
                            qubits = get_args(value)
                            if int(qubits[0]) > 24:
                                return lineno

    # check the init qubits numbers for the TwoLocal operation
    for opt, lineno in zip(opt_list, opt_line_numbers):
        if 'TwoLocal' in opt:
            args = get_args(opt)
            values = get_values(args, var_list)
            qubits = values[0]
            logits = values[1]
            for logit in values:
                if logit in ['"cz"', '"cx"', '"cy"', '"crx"', '"cry"','"crz"']:
                    if int(qubits) <= 1:

                        return lineno

    # check the init qubits numbers for the TwoLocal operation
    for opt, lineno in zip(opt_list, opt_line_numbers):
        if 'QuantumCircuit' in opt or 'QuantumRegister' in opt or 'ClassicalRegister' in opt:
            args = get_args(opt)
            values = get_values(args, var_list)
            values= [int(i) for i in values if i.isdigit()]
            if len(values) == 0:
                continue
            threshold = min(values)
            for opt, lineno in zip(opt_list, opt_line_numbers):
                if 'measure' in opt:
                    args = get_args(opt)
                    values = get_values(args, var_list)
                    values = ''.join(values)
                    qubits = re.findall('[\d]', values)
                    qubits = [int(i) for i in qubits]
                    if len(qubits) > 0 and max(qubits) > threshold - 1:
                        return lineno

    return None

def checker_PE(var_list, att_line_numbers, opt_list, opt_line_numbers):

    # check wrong arguments of cx, ccx

    gate_list = ['ccx', 'mcx', 'rccx', 'rcccx', 'mcu1', 'cswap']
    for opt, lineno in zip(opt_list, opt_line_numbers):
        for gate in gate_list:
            if gate in opt:
               args = get_args(opt)
               values = get_values(args, var_list)
               args, values = get_keywords(args, values)
               if 'label' in args or 'Label' in args:
                    return lineno

    # check the usage of qr, is not callable
    for opt, lineno in zip(opt_list, opt_line_numbers):
        opt_name = opt[: opt.find('(')]
        for assign, lineno in zip(opt_list, att_line_numbers):
            if opt_name == assign[0]:
                if 'QuantumCircuit' in  assign[1] or 'QuantumRegister' in assign[1] or 'ClassicalRegister' in assign[1]:
                    return lineno

    # check if the same quantum gate are assigned to different gates
    for assign, lineno in zip(opt_list, att_line_numbers):
        if 'QuantumCircuit' in  assign[1] or 'QuantumRegister' in assign[1] or 'ClassicalRegister' in assign[1]:
            gate = assign[0]
            qubits = []
            for q_assign in var_list:
                if gate + '[' in q_assign[0]:
                    qubits.append(q_assign[1])

            if len(set(qubits)) < len(qubits):
                return lineno

    # check if the the third argument is correctly assigned
    for opt, lineno in zip(opt_list, opt_line_numbers):
        if 'execute' in  opt:
            args = get_args(opt)
            values = get_values(args, var_list)
            if len(values) > 2:
                if '=' in values[2]:
                    pass
                elif values[2].isdigit():
                    return lineno

    # check if the the third argument is correctly assigned
    for opt, lineno in zip(opt_list, opt_line_numbers):
        if 'execute' in  opt:
            args = get_args(opt)
            values = get_values(args, var_list)
            args, values = get_keywords(args, values)
            for arg, val in zip(args, values):
                if arg == 'backend':
                    if '"' in val:
                        return lineno

    return None

def checker_CE(var_list, att_line_numbers, opt_list, opt_line_numbers):

    # check the wrong usage of ProcessTomography.preparation_basis
    for opt, lineno in zip(opt_list, opt_line_numbers):
        if 'ProcessTomography' in opt:
            args = get_args(opt)
            values = get_values(args, var_list)
            args, values = get_keywords(args, values)
            for arg, value in zip(args, values):
                if 'preparation_basis' == arg:
                    if 'PauliMeasurementBasis()' == value:

                        return lineno

    # check the wrong usage of compile on QuantumCircuit objects
    for opt, lineno in zip(opt_list, opt_line_numbers):
        if 'compile' in opt:
            args = get_args(opt)
            values = get_values(args, var_list)
            args, values = get_keywords(args, values)
            for value in values:
                if 'QuantumCircuit' in value:
                    return lineno

    # check the non-definition of backend
    for opt, lineno in zip(opt_list, opt_line_numbers):
        if 'backend' in opt:
            args = get_args(opt)
            values = get_values(args, var_list)
            args, values = get_keywords(args, values)
            for arg, value in zip(args, values):
                if 'backend' == arg:
                    if 'backend' == value:
                        return lineno

    # check the backend.run get transpiled object
    for opt, lineno in zip(opt_list, opt_line_numbers):
        if 'backend.run' in opt:
            args = get_args(opt)
            values = get_values(args, var_list)
            for assign, lineno in zip(opt_list, att_line_numbers):
                if assign[0] == args[0]:
                    if 'transpile' in assign[1]:

                        return None

            return lineno

    # check the qubits numbers for the qasm_simulator
    for assign, lineno in zip(opt_list, att_line_numbers):
        if 'qasm_simulator' in assign[1]:
            for opt, lineno in zip(opt_list, opt_line_numbers):
                if assign[0] in opt:
                  args = get_args(opt)
                  values = get_values(args, var_list)
                  for value in values:
                    if 'QuantumCircuit' in value:
                        init_args = get_args(value)
                        init_values = get_values(init_args, var_list)
                        init_values = ','.join(init_values)
                        qubits = re.findall('[\d]+', init_values)
                        qubits = [int(i) for i in qubits]
                        if len(qubits) > 0 and max(qubits) > 30:
                            return lineno

    return None

def checker_CM(var_list, att_line_numbers, opt_list, opt_line_numbers):

    # check if the QuantumCircuit object has 'to_gate()' operation when it is appended into another QuantumCircuit pbject
    for assign, lineno in zip(opt_list, att_line_numbers):
        var = assign[0]
        value = assign[1]
        if 'QuantumCircuit' in value:
            for opt, lineno in zip(opt_list, opt_line_numbers):
                if var + '.append' in opt:
                    args = get_args(opt)
                    values = get_values(args, var_list)
                    if '.control' in args[0] or '.control' in values[0]:
                        pass
                    elif '.to_gate' in args[0] or '.to_gate' in values[0]:
                        pass
                    elif '.decompose' in args[0] or '.decompose' in values[0]:
                        pass
                    else:
                        return lineno

    # check if the the usage of shift_phase function is right
    for opt, lineno in zip(opt_list, opt_line_numbers):
        if 'pulse.shiftphase' in opt:
            return lineno


    return None

def checker_IM(var_list, att_line_numbers, opt_list, opt_line_numbers):

    measure_bit = None
    for opt, lineno in zip(opt_list, opt_line_numbers):
        if 'measure' in opt:
            args = get_args(opt)
            values = get_values(args, var_list)
            measure_bit = values[0]

        if measure_bit:
            if 'cz' in opt or 'cx' in opt:
                args = get_args(opt)
                values = get_values(args, var_list)
                current_bit = values[0]
                if current_bit == measure_bit:
                    return lineno

    return None

def checker_QE(var_list, att_line_numbers, opt_list, opt_line_numbers):
    for opt, lineno in zip(opt_list, opt_line_numbers):
        if 'from_qasm_str' in opt:
            if 'QuantumCircuit.from_qasm_str' in opt:
                return None
            obj = opt.split('.')[0]
            for assign, lineno in zip(opt_list, att_line_numbers):
                if assign[0] == obj:
                    if assign[0] == 'QuantumCircuit' or assign[1] == 'QuantumCircuit':
                        return None
            return lineno

def checker_IG(var_list, att_line_numbers, opt_list, opt_line_numbers):

    for opt, lineno in zip(opt_list, opt_line_numbers):
        if 'Gate(' in opt:
            args = get_args(opt)
            values = get_values(args, var_list)
            for assign, lineno in zip(opt_list, att_line_numbers):
                if 'opaque ' + values[0] in assign[1]:
                    return None
            return lineno


    return None

def checker_DO(var_list, att_line_numbers, opt_list, opt_line_numbers):
    for opt, lineno in zip(opt_list, opt_line_numbers):
        if 'iden' in opt:
            return lineno


    return None

def checker_MI(var_list, att_line_numbers, opt_list, opt_line_numbers):
    return None



Rules = {
    'IIS' : checker_IIS,
    'PE' : checker_PE,
    'CE' : checker_CE,
    'CM' : checker_CM,
    'IM' : checker_IM,
    'QE' : checker_QE,
    'IG' : checker_IG,
    'DO' : checker_DO,
    'MI' : checker_MI,
    'IM' : checker_IM,

}

Descrition = {
    'IIS' : 'Incorrect initial state',
    'PE' : 'Parameters error',
    'CE' : 'Call error',
    'CM' : 'Command misuse',
    'QE' : 'QASM error',
    'IG' : 'Incorrect uses of quantum gates',
    'DO' : 'Discarded orders',
    'MI' : 'Measurement related issue',
    'IM' : 'Incorrect measurement'
}


Results = {
    'IIS' : False,
    'PE' : False,
    'CE' : False,
    'CM' : False,
    'QE' : False,
    'IG' : False,
    'DO' : False,
    'MI' : False,
    'IM' : False
}



class Qchecker:
    def __init__(self, rules=None, results=None):
        if rules is None:
            rules = Rules
        if results is None:
            results = Results
        self.rules = rules
        self.results = results
        self.report = None
        self.warnings = []

    def check(self, var_list, att_line_numbers, opt_list, opt_line_numbers, file_lines):
        for task in self.rules.keys():
            lineno = self.rules[task](var_list, att_line_numbers, opt_list, opt_line_numbers)
            if lineno:
                print('Successfully checked the rule {0}'.format(task) + ': ' + Descrition[task] + '.')
                print('Please refer to the code line {0}'.format(lineno) + ': ' + file_lines[int(lineno) - 1] + '.')
                self.warnings.append(
                    {
                        'checker': task,
                        'description': Descrition[task],
                        'line': lineno,
                        'message': file_lines[int(lineno) - 1]
                    }
                )
                #print(Descrition[task])

    def get_report(self):
        return self.warnings

