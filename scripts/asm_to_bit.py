import sys
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('-f', '--file', default=None)
parser.add_argument('-o', '--output', default=None)
args = parser.parse_args()

with open("../alias/ops.alias", 'r') as alias:
    op_alias = {} #OP hash table
    for op_line in alias:
        (bin_rep, curr_op) = op_line.split(' ')
        op_alias[curr_op.strip()] = int(bin_rep, 2) #Instruction Mnemonic = Key, Op Code = Value
    if args.file:
        with open(args.file, 'r') as asmfile:
            with open("{}.bin".format(args.file.split('.')[0]), 'w+b') as binfile:
                for line in asmfile:
                    op = line.strip() #Get stimulus instruction (ASM)
                    if op in op_alias:
                        binfile.write(op_alias.get(op, 'NOP').to_bytes(1, 'little')) #Write ASCII binary
    else:
        sys.exit("Please specify a file to convert using -f")
