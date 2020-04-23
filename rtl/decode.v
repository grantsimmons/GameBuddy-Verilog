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
    output reg [1:0]    reg_src_sel, //Controls register file data source mux
    output wire          reg_writeback,
        //SBUS = 2'b00;
        //ALU = 2'b01;
        //MEM = 2'b10;
        //DEBUG = 2'b11;
    output reg          alu_begin,
    output reg [2:0]    alu_op,
    output reg [7:0]    alu_src_data,
    output reg [7:0]    alu_dest_data,
    output reg          ext,
    output reg          misc,
    output reg          hold, //Zeroes counters until next valid clock cycle
    output reg          rd,
    output wire         m1t1, //Indicates M-Cycle 1, T-Cycle 1; rising edge triggers instruction pipe
    output wire [3:0]   m_cycle,
    output wire [1:0]   t_cycle

    );

    //Instruction Register
    reg [7:0] instruction; //The all-important instruction register

    //Timing Controls
    reg [4:0] cycle, next_cycle; //3 for Max M-Cycle count, 2 for T-Cycle count
    wire [5:0] next_cycle_high; //Next cycle count rounded up, if upper bits match m_count, next cycle is masked with 0x3
    
    //Timing assignments
    assign next_cycle_high = {1'b0, cycle} + 1'b1;
    assign m_cycle = cycle[4:2];
    assign t_cycle = cycle[1:0];
    
    assign m1t1 = cycle == 0 ? 1'b1 : 1'b0;
    assign reg_writeback = t_cycle == 2'b11 ? 1'b1 : 1'b0; //Register writeback clock (T3)

    //FETCH
    always @(posedge m1t1) begin
        instruction <= data_bus_in; //Fetch next instruction from memory buffer
    end

    reg [4:0] m_count; //The number of M-Cycles in current instruction

    //Timing Loop and Reset Values
    always @(posedge clk or negedge rst) begin
        if(~rst) begin
            //reset values
            m_count = 1'b1;
            cycle = 5'b0;
            next_cycle = 5'b0;
            hold = 1'b1;
            rd = 1'b0;
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
    always @(t_cycle) begin //Make combinational?
        case(t_cycle)
            2'b00: begin //T-Cycle 1
                rd = 1'b0;
                alu_begin <= 1'b0;
            end
            2'b01: begin //T-Cycle 2
                if(next_cycle[4:2] == 3'b000) begin
                    //Put program counter on address bus if next M-cycle is a M1 cycle
                end
            end
            2'b10: begin //T-Cycle 3
                if(next_cycle[4:2] == 3'b000) begin
                    //Put next instruction on memory buffer line if next m-cycle is a M1 Cycle
                    rd = 1'b1;
                end
            end
            2'b11: begin //T-Cycle 4
                if(hold) begin
                    hold <= 1'b0;
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
            next_cycle <= next_cycle_high & 2'b11;
        end else begin
            next_cycle <= next_cycle_high;
        end

        //Set Default Control Values
        reg_wr_en = 1'b0;
        reg_rd_en = 1'b0;
        misc = 1'b0;

        case(prefix)
            2'b00: begin
                m_count = 1'b1;
                case(instruction[2:0])
                    3'b000: begin //MISC
                    end

                    3'b001: begin //16-Bit Add, 16-bit LD from Memory
                    end

                    3'b010: begin //Misc Memory access
                    end

                    3'b011: begin //16-bit Inc/Dec
                    end

                    3'b100: begin //8-bit Increment
                    end

                    3'b101: begin //8-bit Decrement
                    end

                    3'b110: begin //8-bit Immediate Load
                    end

                    3'b111: begin //Accumulator Rotates, Misc. ALU operations
                        m_count = 2'd1;
                        begin_alu(instruction[5:3], instruction[2:0], instruction[5], 1'b0);
                            //misc = instruction[5]; //Misc ALU instructions
                            //reg_rd_addr = instruction[2:0]; //Doesn't matter in this scenario. Will matter for extension rotates
                            //reg_rd_en = 1'b1; //Not for SCF/CCF

                        if(instruction[5:4] != 2'b11) begin
                            write(3'b111); //Rotates, NOT, and DAA writeback to A
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
                    reg_src_sel = SBUS;
                    reg_rd_en = 1'b1;
                    write(instruction[5:3]);
                end
                else if(instruction[5:3] == 3'b110) begin
                    //Load to memory
                    m_count = 2'd2;
                    //M-Cycle 1:
                    reg_rd_addr = instruction[2:0]; //Source
                    reg_rd_en = 1'b1;
                    //Place value on d_bus
                    //Place HL on addr
                    //mem_WE = 1'b1;
                    //M-Cycle 2:
                    //Write d_bus to mem
                    
                end
                else if(instruction[2:0] == 3'b110) begin //instruction[5:3] == 3'b110
                    //Load to memory bus (HL)
                    m_count = 2'd2;
                    //M-Cycle 1:
                    
                    //M-Cycle 2:
                    //reg_wr_addr = instruction[5:3];
                    write(instruction[5:3]);
                end
                else begin
                    //Halt
                end
            end

            2'b10: begin
                //8-bit Accumulator Arithmetic and logic
                //op[5:3] = operation
                //op[2:0] = reg select
                m_count = 2'd1;
                begin_alu(instruction[5:3], instruction[2:0], 1'b0, 1'b1);
                write(3'b111);

            end

            2'b11: begin
                //Memory Operations
                //Flow Control
                write(instruction[5:3]);
                reg_src_sel = DEBUG;
            end
        endcase
    end

    task write; //Enables Register Write-back, synced to register file writeback clock
        input [2:0] task_wr_addr;
        reg_wr_addr = task_wr_addr;
        reg_wr_en = t_cycle > 2'b01 ? 1'b1 : 1'b0;
    endtask

    task begin_alu; //begin_alu(alu_op, reg_rd_addr, misc, reg_rd_en);
        input [2:0] op;
        input [2:0] task_rd_addr;
        input task_misc;
        input task_rd_en;
        alu_op = op;
        misc = task_misc; //Misc ALU instructions
        reg_rd_addr = task_rd_addr; //Only really necessary for the Rotates
        reg_rd_en = task_rd_en;

        reg_src_sel = ALU;
        alu_begin = t_cycle > 2'b01 ? 1'b1 : 1'b0; //Generates ALU begin signal
    endtask
endmodule
