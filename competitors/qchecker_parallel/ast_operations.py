#import qiskit
import os,sys
import ast

class Ast_parser:
    def __init__(self) -> None:
        self.file_name = None
        self.file_text = None
        self.root = None
        self.assign_list = []
        self.call_list = []

    def parser(self, file_text):
        self.file_text = file_text
        self.root = ast.parse(file_text)
        return self.root

    def extract_variable_assign(self):
        for node in ast.walk(self.root):
            if isinstance(node, ast.Assign):
                self.assign_list.append(node)
        return self.assign_list


    def extract_function_calls(self):
        for node in ast.walk(self.root):
            if isinstance(node, ast.Call):
                self.call_list.append(node)
        return self.call_list


def process_constant(node):
    if isinstance(node.value, int):
        return str(node.value)
    elif isinstance(node.value, str):
        return '"' + node.value +  '"'
    else:
        return str(node.value)

def process_args(args):
    result = []
    for arg in args:
        if isinstance(arg, ast.Constant):
            result.append(process_constant(arg))
        elif isinstance(arg, ast.Name):
            result.append(process_name(arg))
        elif isinstance(arg, ast.Call):
            result.append(process_call(arg))
        elif isinstance(arg, ast.Attribute):
            result.append(process_attribute(arg))
        elif isinstance(arg, ast.Subscript):
            result.append(process_subscript(arg))
        elif isinstance(arg, ast.List):
            result.append(process_list(arg))
        elif isinstance(arg, ast.keyword):
            result.append(process_keyword(arg))
    return ','.join(result)

def process_keyword(node):
    label = node.arg
    if isinstance(node.value, ast.Constant):
        value = process_constant(node.value)
    if isinstance(node.value, ast.Name):
        value = process_name(node.value)
    if isinstance(node.value, ast.Call):
        value = process_call(node.value)
    if isinstance(node.value, ast.Attribute):
        value = process_attribute(node.value)
    if isinstance(node.value, ast.Subscript):
        value = process_subscript(node.value)
    if isinstance(node.value, ast.List):
        value = process_list(node.value)
    return label + '=' + value

def process_list(node):
    result = []
    for arg in node.elts:
        if isinstance(arg, ast.Constant):
            result.append(process_constant(arg))
        elif isinstance(arg, ast.Name):
            result.append(process_name(arg))
        elif isinstance(arg, ast.Call):
            result.append(process_call(arg))
        elif isinstance(arg, ast.Attribute):
            result.append(process_attribute(arg))
        elif isinstance(arg, ast.Subscript):
            result.append(process_subscript(arg))
        elif isinstance(arg, ast.List):
            result.append(process_list(arg))
    return '[' + ','.join(result) + ']'

def process_index(node):

    if isinstance(node, ast.Constant):
        return process_constant(node)
    elif isinstance(node, ast.Name):
        return process_name(node)
    elif isinstance(node, ast.Call):
        return process_call(node)
    elif isinstance(node, ast.Attribute):
        return process_attribute(node)
    elif isinstance(node, ast.Subscript):
        return process_subscript(node)
    else:
        return ''

def process_subscript(node):
    label = '[' + process_index(node.slice) + ']'
    if isinstance(node.value, ast.Name):
         label = process_name(node.value) + label
    return label

def process_name(node):
    return str(node.id)

def process_attribute(node):
    label = '.' + node.attr
    if isinstance(node.value, ast.Call):
         label = process_call(node.value) + label
    elif isinstance(node.value, ast.Attribute):
        label = process_attribute(node.value) + label
    elif isinstance(node.value, ast.Name):
        label = process_name(node.value) + label

    return label

def process_call(node):
    args = node.args + node.keywords
    label = '(' + process_args(args) + ')'
    if isinstance(node.func, ast.Call):
        label = process_call(node.func) + label
    elif isinstance(node.func, ast.Attribute):
        label = process_attribute(node.func) + label
    elif isinstance(node.func, ast.Name):
        label = process_name(node.func) + label
    return label


def process_dict(node):

    results = []
    assign_list = []
    for key, value in zip(node.keys, node.values):
        k_label = ''
        v_label = ''

        if isinstance(key, ast.Constant):
            k_label = process_constant(key)
        elif isinstance(key, ast.Name):
            k_label = process_name(key)
        elif isinstance(key, ast.Subscript):
            k_label = process_subscript(key)



        if isinstance(value, ast.Constant):
            v_label = process_constant(value)
        elif isinstance(value, ast.Name):
            v_label = process_name(value)
        elif isinstance(value, ast.Call):
            v_label = process_call(value)
        elif isinstance(value, ast.Attribute):
            v_label = process_attribute(value)
        elif isinstance(value, ast.Subscript):
            v_label = process_subscript(value)
        elif isinstance(value, ast.Dict):
            v_label = process_dict(value)

        results.append((k_label + ':' + v_label))
        assign_list.append((k_label, v_label))
    return "{" + ','.join(results) + "}", assign_list


def get_attributes(assign_list):
    attributes = []
    dict_assign = None
    line_numbers = []
    for assign in assign_list:
        if isinstance(assign.targets[0], ast.Tuple):
            name = ','.join([var.id  for var in assign.targets[0].elts])
        else:
            name = assign.targets[0].id
        if isinstance(assign.value, ast.Constant):
            value = assign.value.value
        elif isinstance(assign.value, ast.Call):
            node = assign.value
            value = process_call(node)
        elif isinstance(assign.value, ast.Attribute):
            node = assign.value
            value = process_attribute(node)
        elif isinstance(assign.value, ast.Dict):
            node = assign.value
            value, dict_assign = process_dict(node)
        value = str(value)
        attributes.append((name, value))
        line_numbers.append(assign.lineno)
    if dict_assign:
        attributes = attributes + dict_assign
    return attributes, line_numbers

def get_operations(call_list):
    operations = []
    line_numbers = []
    for call in call_list:
        detail = process_call(call)
        operations.append(detail)
        line_numbers.append(call.lineno)
    return operations, line_numbers

