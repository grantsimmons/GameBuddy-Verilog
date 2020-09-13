#!/usr/bin/python3
import sys
import os
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
parser.add_argument('-e', '--extended', action='store_true')
args = parser.parse_args()


if args.generate_random and not args.extended:
    seed = args.seed if args.seed else int(time.time())
    random.seed(seed)
    with open("alias/supported.alias", 'r') as alias: #FIXME: Make this an environment variable
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
        stimpath = "sim/stim/" #FIXME: Make this a environment variable
        filename = "rand_stim_{}_v{}_s{}{}".format(seed, version, args.number, '_{}'.format(args.identifier) if args.identifier else '')
        dirname = stimpath + filename
        os.mkdir(dirname)
        os.chdir(dirname)
        os.unlink('../latest')
        os.symlink(filename, '../latest')
        with open(filename + ".bin", 'w+b') as binfile:
            with open(filename + ".asm", 'w') as asmfile:
                with open(filename + ".txt", 'w') as txtfile:
                    for i in range(args.number):
                        randnum = random.randint(0,len(op_mnem_arr)-1)
                        binfile.write(op_alias[op_mnem_arr[randnum]].to_bytes(1, 'little')) #Write ASCII binary
                        asmfile.write(op_mnem_arr[randnum] + '\n')
                        txtfile.write(bin(op_alias[op_mnem_arr[randnum]]).split('b')[1].zfill(8) + '\n')
                    binfile.write(int('00010000', 2).to_bytes(1, 'little'))
                    txtfile.write('00010000')
                    asmfile.write('STOP')
    print("Random file generated with seed {:d} using Version {} of supported alias".format(seed, version))
    sys.exit(0)

if args.generate_random and args.extended:
    seed = args.seed if args.seed else int(time.time())
    random.seed(seed)
    with open("alias/ops_full_supported.alias", 'r') as alias:
        op_mnem_arr = []
        op_mnem_arr_ext = []
        op_alias = {}
        op_ext_alias = {}
        version = 0
        for op_line in alias:
            if op_line[0] == '#':
                version = op_line.split(' ')[1].strip()
                continue
            (bin_rep, curr_op) = op_line.split(' ')
            op_alias[curr_op.strip()]= int(bin_rep[1:], 2) #Instruction Mnemonic = Key, Op Code = Value
            if int(bin_rep, 2) < 256:
                op_mnem_arr.append(curr_op.strip())
            else:
                op_mnem_arr_ext.append(curr_op.strip())
        stimpath = "sim/stim/" #FIXME: Make this a environment variable
        filename = "rand_stim_{}_v{}_s{}{}".format(seed, version, args.number, '_{}'.format(args.identifier) if args.identifier else '')
        dirname = stimpath + filename
        os.mkdir(dirname)
        os.chdir(dirname)
        os.unlink('../latest')
        os.symlink(filename, '../latest')
        with open(filename + ".bin", 'w+b') as binfile:
            with open(filename + ".asm", 'w') as asmfile:
                with open(filename + ".txt", 'w') as txtfile:
                    for i in range(args.number):
                        randnum = random.randint(0,1)
                        if randnum == 0: #Base instructions
                            index = random.randint(0,len(op_mnem_arr)-1) #Random base instruction
                            binfile.write((op_alias[op_mnem_arr[index]] & 0xFF).to_bytes(1, 'little')) #Write ASCII binary
                            asmfile.write(op_mnem_arr[index] + '\n')
                            txtfile.write(bin(op_alias[op_mnem_arr[index]]).split('b')[1].zfill(8) + '\n')
                            if 'nn' in op_mnem_arr[index]:
                                randop = random.randint(0,255)
                                binfile.write(randop.to_bytes(1, 'little'))
                                asmfile.write("{:2x}".format(randop) + '\n')
                                txtfile.write(bin(randop).split('b')[1].zfill(8) + '\n')
                                randop = random.randint(0,255)
                                binfile.write(randop.to_bytes(1, 'little'))
                                asmfile.write("{:2x}".format(randop) + '\n')
                                txtfile.write(bin(randop).split('b')[1].zfill(8) + '\n')
                                continue
                            elif 'n' in op_mnem_arr[index]:
                                randop = random.randint(0,255)
                                binfile.write(randop.to_bytes(1, 'little'))
                                asmfile.write("{:2x}".format(randop) + '\n')
                                txtfile.write(bin(randop).split('b')[1].zfill(8) + '\n')
                                continue
                        else: #Extensions
                            index = random.randint(0,len(op_mnem_arr_ext)-1)
                            binfile.write(int('11001011', 2).to_bytes(1, 'little'))
                            binfile.write((op_alias[op_mnem_arr_ext[index]] & 0xFF).to_bytes(1, 'little')) #Write ASCII binary
                            asmfile.write(op_mnem_arr_ext[index] + '\n')
                            txtfile.write('11001011\n')
                            txtfile.write(bin(op_alias[op_mnem_arr_ext[index]]).split('b')[1].zfill(8) + '\n')
                    binfile.write(int('00010000', 2).to_bytes(1, 'little'))
                    txtfile.write('00010000')
                    asmfile.write('STOP')
    print("Random file generated with seed {:d} using Version {} of supported alias".format(seed, version))
    sys.exit(0)

if args.extended:
    print("Using experimental extension system")
    with open("alias/ops_full.alias", 'r') as alias:
        op_alias = {} #OP dictionary
        op_ext_alias = {} #EXTOP dictionary
        for op_line in alias:
            (bin_rep, curr_op) = op_line.split(' ')
            if bin_rep[0] == '0': #Check for CB extension
                op_alias[curr_op.strip()] = int(bin_rep[1:], 2) #Instruction Mnemonic = Key, Op Code = Value
            else:
                op_ext_alias[curr_op.strip()] = int(bin_rep[1:], 2)
        if args.file:
            with open(args.file, 'r') as asmfile:
                with open("{}".format(str(args.file.split('.')[0] + '.bin') if not args.output else args.output), 'w+b') as binfile:
                    with open("{}".format(str(args.file.split('.')[0] + '.txt') if not args.output else args.output), 'w') as txtfile:
                        for line in asmfile:
                            op = line.strip() #Get stimulus instruction (ASM)
                            if op in op_alias:
                                binfile.write(op_alias[op].to_bytes(1, 'little')) #Write ASCII binary
                                txtfile.write(bin(op_alias[op]).split('b')[1].zfill(8) + '\n')
                            elif op in op_ext_alias:
                                binfile.write(int('11001011', 2).to_bytes(1, 'little')) #CB prefix
                                binfile.write(op_ext_alias[op].to_bytes(1, 'little')) #Write ASCII binary
                                txtfile.write('11001011' + '\n')
                                txtfile.write(bin(op_ext_alias[op]).split('b')[1].zfill(8) + '\n')
        else:
            sys.exit("Please specify a file to convert using -f")


else:
    with open("alias/ops.alias", 'r') as alias:
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
                            txtfile.write(bin(op_alias.get(op, 'NOP')).split('b')[1].zfill(8) + '\n')
        else:
            sys.exit("Please specify a file to convert using -f")
