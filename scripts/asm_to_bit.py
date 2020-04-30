import sys
import argparse
#from random import randrange
import random
from datetime import datetime
import time

parser = argparse.ArgumentParser()
parser.add_argument('-f', '--file', default=None)
parser.add_argument('-b', '--binary', action='store_true')
parser.add_argument('-t', '--text', action='store_true')
parser.add_argument('-o', '--output', default=None)
parser.add_argument('-n', '--number', type=int, default=8)
parser.add_argument('-r', '--generate_random', action='store_true')
parser.add_argument('-s', '--seed', type=int, default=None)
parser.add_argument('-i', '--identifier', default=None)
args = parser.parse_args()

if args.generate_random:
    seed = args.seed if args.seed else int(time.time())
    random.seed(seed)
    print(seed)
    with open("../alias/supported.alias", 'r') as alias:
        op_mnem_arr = []
        op_alias = {}
        version = 0
        for op_line in alias:
            if op_line[0] == '#':
                version = op_line.split(' ')[1].strip()
                continue
            (bin_rep, curr_op) = op_line.split(' ')
            op_alias[curr_op.strip()]= int(bin_rep, 2) #Instruction Mnemonic = Key, Op Code = Value
            op_mnem_arr.append(curr_op.strip())
        with open("rand_stim_{}_v{}_s{}{}.bin".format(seed, version, args.number, '_{}'.format(args.identifier) if args.identifier else ''), 'w+b') as binfile:
            with open("rand_stim_{}_v{}_s{}{}.asm".format(seed, version, args.number, '_{}'.format(args.identifier) if args.identifier else ''), 'w') as asmfile:
                with open("rand_stim_{}_v{}_s{}{}.txt".format(seed, version, args.number, '_{}'.format(args.identifier) if args.identifier else ''), 'w') as txtfile:
                    for i in range(args.number):
                        randnum = random.randint(0,len(op_mnem_arr)-1)
                        binfile.write(op_alias[op_mnem_arr[randnum]].to_bytes(1, 'little')) #Write ASCII binary
                        asmfile.write(op_mnem_arr[randnum] + '\n')
                        txtfile.write(bin(op_alias[op_mnem_arr[randnum]]).split('b')[1].zfill(8) + '\n')
                    binfile.write(int('00010000', 2).to_bytes(1, 'little'))
                    txtfile.write('00010000')
                    asmfile.write('STOP')
    sys.exit("Random file generated with seed {:d} using Version {} of supported alias".format(seed, version))

with open("../alias/ops.alias", 'r') as alias:
    op_alias = {} #OP hash table
    for op_line in alias:
        (bin_rep, curr_op) = op_line.split(' ')
        op_alias[curr_op.strip()] = int(bin_rep, 2) #Instruction Mnemonic = Key, Op Code = Value
    if args.file:
        with open(args.file, 'r') as asmfile:
            with open("{}".format(str(args.file.split('.')[0] + '.bin') if not args.output else args.output), 'w+b') as binfile:
                with open("{}".format(str(args.file.split('.')[0] + '.txt') if not args.output else args.output), 'w') as txtfile:
                    for line in asmfile:
                        op = line.strip() #Get stimulus instruction (ASM)
                        binfile.write(op_alias.get(op, 'NOP').to_bytes(1, 'little')) #Write ASCII binary
                        if op != 'STOP':
                            txtfile.write(bin(op_alias.get(op, 'NOP')).split('b')[1].zfill(8) + '\n')
    else:
        sys.exit("Please specify a file to convert using -f")
