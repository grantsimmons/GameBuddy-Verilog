with open("../alias/ops.alias", 'r') as alias:
    op_alias = {} #OP hash table
    for op_line in alias:
        (bin_rep, curr_op) = op_line.split(' ')
        op_alias[curr_op.strip()] = int(bin_rep, 2) #Instruction Mnemonic = Key, Op Code = Value
    with open("stim.asm", 'r') as asmfile:
        with open("stim.bin", 'w+b') as binfile:
            for line in asmfile:
                op = line.strip() #Get stimulus instruction (ASM)
                if op in op_alias:
                    binfile.write(op_alias.get(op, 'NOP').to_bytes(1, 'little')) #Write ASCII binary
