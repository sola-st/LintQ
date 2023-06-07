import argparse, re
import ast
import os,sys
from competitors.qchecker_parallel.ast_operations import Ast_parser
from competitors.qchecker_parallel.ast_operations import get_attributes, get_operations
#from circuit_attribute import Attributes
#from circuit_operation import Operations

from competitors.qchecker_parallel.qchecker import Qchecker



def read_file(file_name):
    with open(file_name, 'r') as f:
        file_text = f.read()
    return file_text

def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--file_name", type=str, default="instances/DO/case1.py")
    return parser.parse_args()

if __name__ == '__main__':
    ARGS=get_args()
    file_text = read_file(ARGS.file_name)
    file_lins = file_text.split('\n')
    astparser = Ast_parser()
    root = astparser.parser(file_text)

    # print(ast.dump(root, indent=4))
    assign_list = astparser.extract_variable_assign()
    call_list = astparser.extract_function_calls()


    attributes, att_line_numbers = get_attributes(assign_list)
    operations, opt_line_numbers = get_operations(call_list)

    print('\n')
    print("QP_Attributes:")
    print('==========================================')
    print(attributes)
    print('\n')

    print("QP_Operations:")
    print('==========================================')
    print(operations)
    print('\n')


    qc = Qchecker()
    qc.check(attributes, att_line_numbers, operations, opt_line_numbers, file_lins)
    qc.get_report()




