module decode(
    //Inputs
    input wire          clk,
    input wire          rst,
    input wire [7:0]    data_bus_in,
    //Outputs
    //Control Signals
    output reg          reg_rd_en,
    output reg          reg_wr_en,
    output reg [2:0]    reg_rd_addr,
    output reg [2:0]    reg_wr_addr,
    output reg [2:0]    reg_mem_addr_sel,
    output reg          reg_drive_addr,
    output reg [1:0]    reg_src_sel, //Controls register file data source mux
        //SBUS = 2'b00;
        //ALU = 2'b01;
        //MEM = 2'b10;
        //DEBUG = 2'b11;
    output wire         reg_writeback,
    output wire         reg_pc_wr_en,
    output reg          alu_begin,
    output reg [2:0]    alu_op,
    output reg [7:0]    alu_src_data,
    output reg          alu_src_sel,
    output reg [7:0]    alu_dest_data,
    output reg [2:0]    alu_bit_index,
    output reg          alu_incdec,
    output reg          ext,
    output reg          misc,
    output reg          hold, //Zeroes counters until next valid clock cycle
    output reg          rd,
    output reg          wr,
    output wire         m1t1, //Indicates M-Cycle 1, T-Cycle 1; rising edge triggers instruction pipe
    output wire [3:0]   m_cycle,
    output wire [1:0]   t_cycle

    );

    //Instruction Register
    reg [7:0] instruction; //The all-important instruction register
    wire [8:0] instruction_alias;
    assign instruction_alias = {ext, instruction};

    //Timing Controls
    reg [4:0] m_count; //The number of M-Cycles in current instruction
    reg [4:0] cycle, next_cycle; //3 bits for Max M-Cycle count, 2 bits for T-Cycle count
    wire [5:0] next_cycle_high; //Next cycle count rounded up, if upper bits match m_count, next cycle is masked with 0x3

    //Timing assignments
    assign next_cycle_high = {1'b0, cycle} + 1'b1;
    assign m_cycle = cycle[4:2];
    assign t_cycle = cycle[1:0];
    
    assign m1t1 = cycle == 0 ? 1'b1 : 1'b0;
    assign reg_writeback = t_cycle == 2'b11 ? 1'b1 : 1'b0; //Register writeback clock (T3)

	//PC Sticky Wr_En
	reg m1_next_cycle;
	reg reg_inc_pc;

	always @(t_cycle or m_count or m_cycle) begin
		if(t_cycle == 2'b11 && (m_count - m_cycle == 1'b1) && ~hold) begin
			m1_next_cycle = 1'b1;
		end
		if(t_cycle == 2'b01) begin
			m1_next_cycle = 1'b0;
		end
	end

	assign reg_pc_wr_en = m1_next_cycle | reg_inc_pc;

    //FETCH
    always @(m1t1 or data_bus_in) begin
        if(m1t1) begin
            instruction <= data_bus_in; //Fetch next instruction from memory buffer
            misc = 1'b0;
            ext = 1'b0;
            alu_src_sel = 1'b0; //Default to register source
        end
    end

    always @(m_cycle or t_cycle or ext) begin
        if(ext && t_cycle == 2'b00 && m_cycle == 2'b01) begin
            instruction = data_bus_in; //Fetch extension instruction from memory buffer
        end
    end

    //Timing Loop and Reset Values
    always @(posedge clk or negedge rst) begin
        if(~rst) begin
            //reset values
            m_count = 1'b1;
            cycle = 5'b0;
            next_cycle = 5'b0;
            hold = 1'b1;
            rd = 1'b0;
            wr = 1'b0;
            instruction = 8'b0;
            reg_wr_en = 1'b0;
            reg_rd_en = 1'b0;
            reg_rd_addr = 0;
            reg_wr_addr = 0;
            reg_src_sel = 0;
        end
        else begin
            cycle <= next_cycle;
        end
    end

    //Decode FSM
    always @(t_cycle or clk) begin //Make combinational?
        case(t_cycle)
            2'b00: begin //T-Cycle 1
                rd = 1'b0;
                alu_begin = 1'b0;
            end
            2'b01: begin //T-Cycle 2
                reg_inc_pc = 1'b0;
                if(next_cycle[4:2] == 3'b000) begin
                    //Put program counter on address bus if next M-cycle is a M1 cycle
                end
            end
            2'b10: begin //T-Cycle 3
                //if(next_cycle[4:2] == 3'b000) begin
                //    //Put next instruction on memory buffer line if next m-cycle is a M1 Cycle
                //    rd = 1'b1;
                //end
                if(m_count - 1'b1 == m_cycle) begin
                    rd = 1'b1;
                end
            end
            2'b11: begin //T-Cycle 4
                if(~clk) begin
                    hold <= 1'b0;
                    wr <= 1'b0; //Memory write latched on T4 falling
                end
            end
        endcase
    end

    wire [1:0] prefix;
    assign prefix = instruction[7:6];

    //FIXME: Make localparams global
    //Register Encodings
    localparam REG_A = 3'b111;
    localparam REG_B = 3'b000;
    localparam REG_C = 3'b001;
    localparam REG_D = 3'b010;
    localparam REG_E = 3'b011;
    localparam REG_H = 3'b100;
    localparam REG_L = 3'b101;
    localparam MEM_HL = 3'b110;

    //DBUS Mux select
    localparam SBUS = 2'b00;
    localparam ALU = 2'b01;
    localparam MEM = 2'b10;
    localparam DEBUG = 2'b11;

    //DECODE
    always @(*) begin
        if(next_cycle_high[4:2] == m_count) begin
            next_cycle = next_cycle_high & 2'b11; //Go to next instruction if next M-Cycle = number of M-Cycles for current instruction
        end else begin
            next_cycle = next_cycle_high; //Go to next T-Cycle
        end

        //Set Default Control Values
        reg_wr_en = 1'b0;
        reg_rd_en = 1'b0;
        reg_drive_addr = 1'b0; //Drive PC by default
        alu_incdec = 1'b0;

        if(ext == 1'b0) begin
            case(prefix)
                2'b00: begin
                    m_count = 1'b1;
                    case(instruction[2:0])
                        3'b000: begin //MISC
                        end

                        3'b001: begin //16-Bit Add, 16-bit LD from Memory
                            if(instruction[3]) begin
                                //16-Bit Add
                            end
                            else begin
                                m_count = 2'd3;
                                case(instruction[5:4]) //FIXME: is there a way to make this more efficient?
                                    //TODO: Make 16-bit state machine
                                    2'b00: begin //LDBCnn
                                        case(m_cycle)
                                            2'b00: begin //M1
                                                read_mem(2'b000); //Read first byte (LSB)
                                                if(t_cycle == 2'b11) reg_inc_pc = 1'b1;
                                            end
                                            2'b01: begin //M2
                                                read_mem(2'b000); //Read second byte (MSB)
                                                write(3'b001, MEM);
                                                if(t_cycle == 2'b11) reg_inc_pc = 1'b1;
                                            end
                                            2'b10: begin //M3
                                                write(3'b000, MEM);
                                            end
                                        endcase
                                    end
                                    2'b01: begin //LDDEnn
                                        case(m_cycle)
                                            2'b00: begin //M1
                                                read_mem(2'b000); //Read first byte (LSB)
                                                if(t_cycle == 2'b11) reg_inc_pc = 1'b1;
                                            end
                                            2'b01: begin //M2
                                                read_mem(2'b000); //Read second byte (MSB)
                                                write(3'b011, MEM);
                                                if(t_cycle == 2'b11) reg_inc_pc = 1'b1;
                                            end
                                            2'b10: begin //M3
                                                write(3'b010, MEM);
                                            end
                                        endcase
                                    end
                                    2'b10: begin //LDHLnn
                                        case(m_cycle)
                                            2'b00: begin //M1
                                                read_mem(2'b000); //Read first byte (LSB)
                                                if(t_cycle == 2'b11) reg_inc_pc = 1'b1;
                                            end
                                            2'b01: begin //M2
                                                read_mem(2'b000); //Read second byte (MSB)
                                                write(3'b101, MEM);
                                                if(t_cycle == 2'b11) reg_inc_pc = 1'b1;
                                            end
                                            2'b10: begin //M3
                                                write(3'b100, MEM);
                                            end
                                        endcase
                                    end
                                    2'b11: begin //SP
                                    end
                                endcase
                            end

                        end

                        3'b010: begin //Misc Memory access
                            m_count = 2'd2;
                            if(instruction[5]) begin
                            end
                            else begin //(BC), (DE) access
                                if(instruction[3]) begin
                                    //Read to accumulator
                                    //LDAmXX
                                    case(m_cycle)
                                        1'b00: read_mem({1'b1, instruction[5:4]});
                                        1'b01: write(3'b111, MEM);
                                    endcase
                                end
                                else begin
                                    //Write to memory from accumulator
                                    //LDmXXA
                                    case(m_cycle)
                                        1'b00: write_mem(3'b111, 1'b1, {1'b1, instruction[5:4]}, SBUS);
                                        1'b01: begin
                                        end
                                    endcase
                                end
                            end
                        end

                        3'b011: begin //16-bit Inc/Dec
                        end

                        3'b100: begin //8-bit Increment
                            //TODO: Pull INC/DEC out of ALU?
                            if(instruction[5:3] != 3'b110) begin
                                m_count = 2'd1;
                                alu_incdec = 1'b1;
                                begin_alu(instruction[2:0], instruction[5:3], 1'b1, 1'b1, 1'b0);
                                write(instruction[5:3], ALU);
                            end
                        end

                        3'b101: begin //8-bit Decrement
                            if(instruction[5:3] != 3'b110) begin
                                m_count = 2'd1; //FIXME: Same format as INC. Condense?
                                alu_incdec = 1'b1;
                                begin_alu(instruction[2:0], instruction[5:3], 1'b1, 1'b1, 1'b0);
                                write(instruction[5:3], ALU);
                            end
                        end

                        3'b110: begin //8-bit Immediate Load
                            m_count = 2'd2;
                            case(m_cycle)
                                2'b00: begin
                                    read_mem(3'b000); //PC
                                    //Increment PC
                                    if(t_cycle == 2'b11) reg_inc_pc = 1'b1;
                                end
                                2'b01: begin
                                    write(instruction[5:3], MEM);
                                end
                            endcase
                        end

                        3'b111: begin //Accumulator Rotates, Misc. ALU operations
                            m_count = 2'd1;
                            begin_alu(instruction[5:3], instruction[2:0], 1'b1, 1'b0, 1'b0);
                                //misc = instruction[5]; //Misc ALU instructions
                                //reg_rd_addr = instruction[2:0]; //Doesn't matter in this scenario. Will matter for extension rotates
                                //reg_rd_en = 1'b1; //Not for SCF/CCF

                            if(instruction[5:4] != 2'b11) begin
                                write(3'b111, ALU); //Rotates, NOT, and DAA writeback to A
                            end
                        end
                    endcase
                end

                2'b01: begin
                    //LD: 01(3:dest)(3:src)
                    if(instruction[5:3] != 3'b110 && instruction[2:0] != 3'b110) begin
                        //Load to reg
                        m_count = 1'd1;
                        reg_rd_addr = instruction[2:0]; //Source
                        //reg_src_sel = SBUS;
                        reg_rd_en = 1'b1;
                        write(instruction[5:3], SBUS);
                    end
                    else if(instruction[5:3] == 3'b110) begin
                        //Load to memory
                        m_count = 2'd2;
                        case(m_cycle)
                            2'b00: write_mem(instruction[2:0], 1'b1, instruction[5:3], SBUS);
                            2'b01: begin
                            end
                        endcase
                    end
                    else if(instruction[2:0] == 3'b110) begin
                        //Load from memory bus (HL)
                        m_count = 2'd2;
                        case(m_cycle)
                            2'b00: begin
                                read_mem(instruction[2:0]);
                            end
                            2'b01: begin
                                write(instruction[5:3], MEM);
                            end
                        endcase
                    end
                    else begin
                        //Halt
                    end
                end

                2'b10: begin
                    //8-bit Accumulator Arithmetic and logic
                    //op[5:3] = operation
                    //op[2:0] = reg select
                    if(instruction[2:0] != 3'b110) begin
                        m_count = 2'd1;
                        begin_alu(instruction[5:3], instruction[2:0], 1'b0, 1'b1, 1'b0);
                        write(3'b111, ALU);
                    end
                    else begin
                        m_count = 2'd2;
                        case(m_cycle)
                            2'b00: begin
                                read_mem(instruction[2:0]);
                            end
                            2'b01: begin
                                begin_alu(instruction[5:3], instruction[2:0], 1'b0, 1'b1, 1'b1);
                                write(3'b111, ALU);
                            end
                        endcase
                    end

                end

                2'b11: begin
                    //Memory Operations
                    //Flow Control
                    case(instruction[2:0])
                        3'b011: begin
                            if(instruction[5:3] == 3'b001) begin
                                m_count = 2'd2;
                                case(m_cycle)
									2'b00: begin
										read_mem(3'b000); //Read next program byte
                                        if(t_cycle == 2'b11) reg_inc_pc = 1'b1; //Increment PC
									end
                                    2'b01: begin
                                        ext <= 1'b1; //Enter CB Extension mode
                                    end
                                endcase
                            end
                        end
                        3'b110: begin //8-bit Immediate Arithmetic
                            m_count = 2'd2;
                            case(m_cycle)
                                2'b00: begin
                                    read_mem(3'b000); //Read next instruction byte
                                    if(t_cycle == 2'b11) reg_inc_pc = 1'b1;
                                end
                                2'b01: begin
                                    begin_alu(instruction[5:3], 3'b111, 1'b0, 1'b0, 1'b1);
                                    write(3'b111, ALU); //Write to accumulator from memory bus
                                end
                            endcase
                        end
                    endcase
                end
            endcase
        end
        else begin //CB Extension instructions
            case(prefix)
                2'b00: begin //Register Arithmetic
                    if(instruction[2:0] !== 3'b110) begin
                        m_count = 2'd2;
                        begin_alu(instruction[5:3], instruction[2:0], 1'b0, 1'b1, 1'b0);
                        write(instruction[2:0], ALU);
                    end
                    else begin //mHL Arithmetic
                        m_count = 3'd4;
                        case(m_cycle)
                            //Read
                            2'b01: read_mem(instruction[2:0]);
                            2'b10: begin
                                //Execute
                                begin_alu(instruction[5:3], instruction[2:0], 1'b0, 1'b1, 1'b1);
                                //Commit
                                write_mem(3'b111, 1'b0, instruction[2:0], ALU);
                            end
                            2'b11: begin 
                                //Fetch next instruction
                            end
                        endcase
                    end
                end
                2'b01: begin //Bit Evaluate
                    if(instruction[2:0] !== 3'b110) begin
                        m_count = 2'd2;
                        begin_alu({1'b0, instruction[7:6]}, instruction[2:0], 1'b1, 1'b1, 1'b0);
                    end
                    else begin // mHL
                        m_count = 2'd3;
                        case(m_cycle)
                            2'b01: begin
                                read_mem(instruction[2:0]);
                            end
                            2'b10: begin
                                begin_alu({1'b0, instruction[7:6]}, instruction[2:0], 1'b1, 1'b1, 1'b1);
                            end
                        endcase
                    end
                    alu_bit_index = instruction[5:3];
                end
                2'b10: begin //Bit Reset
                    if(instruction[2:0] !== 3'b110) begin
                        m_count = 2'd2;
                        begin_alu({1'b0, instruction[7:6]}, instruction[2:0], 1'b1, 1'b1, 1'b0);
                        write(instruction[2:0], ALU);
                    end
                    else begin //mHL Reset
                        m_count = 3'd4;
                        case(m_cycle)
                            //Read
                            2'b01: read_mem(instruction[2:0]);
                            2'b10: begin
                                //Execute
                                begin_alu({1'b0, instruction[7:6]}, instruction[2:0], 1'b1, 1'b1, 1'b1);
                                //Commit
                                write_mem(3'b111, 1'b0, instruction[2:0], ALU);
                            end
                            2'b11: begin 
                                //Fetch next instruction
                            end
                        endcase
                    end
                    alu_bit_index = instruction[5:3];
                end
                2'b11: begin //Bit Set
                    if(instruction[2:0] !== 3'b110) begin
                        m_count = 2'd2;
                        begin_alu({1'b0, instruction[7:6]}, instruction[2:0], 1'b1, 1'b1, 1'b0);
                        write(instruction[2:0], ALU);
                    end
                    else begin //mHL Set
                        m_count = 3'd4;
                        case(m_cycle)
                            //Read
                            2'b01: read_mem(instruction[2:0]);
                            2'b10: begin
                                //Execute
                                begin_alu({1'b0, instruction[7:6]}, instruction[2:0], 1'b1, 1'b1, 1'b1);
                                //Commit
                                write_mem(3'b111, 1'b0, instruction[2:0], ALU);
                            end
                            2'b11: begin 
                                //Fetch next instruction
                            end
                        endcase
                    end
                    alu_bit_index = instruction[5:3];
                end
            endcase
        end
    end

    task write; //Enables Register Write-back, synced to register file writeback clock
        input [2:0] task_wr_addr; //Register address
        input [1:0] task_src_sel; //Register input select
        reg_src_sel = task_src_sel;
        reg_wr_addr = task_wr_addr;
        reg_wr_en = t_cycle > 2'b01 ? 1'b1 : 1'b0;
    endtask

    task begin_alu; //begin_alu(alu_op, reg_rd_addr, misc, reg_rd_en, alu_src_sel);
        input [2:0] op;
        input [2:0] task_rd_addr;
        input task_misc;
        input task_rd_en;
        input task_alu_src_sel;
        alu_op = op;
        misc = task_misc; //Misc ALU instructions
        reg_rd_addr = task_rd_addr; //Only really necessary for the Rotates
        reg_rd_en = task_rd_en;
        alu_src_sel = task_alu_src_sel;

        //reg_src_sel = ALU;
        if(t_cycle == 2'b10) alu_begin = 1'b1; //Set at T2, Reset at next T1
    endtask

    task read_mem;
        //Send reg16 address to reg file to put on read bus -> address bus
        //Read From
        input [2:0] task_rd_addr;
        reg_drive_addr = 1'b1;
        reg_mem_addr_sel = task_rd_addr;
        //PC = 000
        //TP = 001
        //FF+n/FF+C?
        //BC = 100
        //DE = 101
        //HL = 110
        //SP = 111
        if(t_cycle == 2'b10) begin
            rd = 1'b1;
        end

    endtask

    task write_mem; //write_mem(reg_rd_addr, reg_rd_en, reg_mem_addr_sel, reg_src_sel)
        input [2:0] task_rd_addr; //Register address to 8-bit Data Register
        input       task_rd_en; //Enable register file output to loopback
        input [2:0] task_mem_addr_sel; //Register address to 16-bit Address in Regfile
        input [1:0] task_src_sel;
        reg_drive_addr = 1'b1;
        reg_mem_addr_sel = task_mem_addr_sel;
        reg_wr_addr <= 3'b110;

        reg_rd_addr = task_rd_addr;
        reg_rd_en <= task_rd_en;
        reg_src_sel = task_src_sel; //Set mem_data_out source to register output
        //wr_enable handled by top level
        if(t_cycle == 2'b10) begin
            wr = 1'b1;
        end
    endtask
endmodule
