module decode(
    //Inputs
    input wire          clk,
    input wire          rst,
    input wire [7:0]    curr_op,
    //Outputs
    //Control Signals
    output reg          reg_rd_en,
    output reg          reg_wr_en,
    output reg [2:0]    reg_rd_addr,
    output reg [2:0]    reg_wr_addr,
    output reg [1:0]    reg_src_sel,
    output wire         m1t1 //Indicates M-Cycle 1, T-Cycle 1; rising edge triggers instruction pipe

    );

    reg [4:0] cycle, next_cycle; //3 for Max M-Cycle count, 2 for T-Cycle count
    wire [5:0] next_cycle_high; //Next cycle count rounded up, if upper bits match m_count, next cycle is masked with 0x3
    wire [3:0] m_cycle;
    wire [1:0] t_cycle;
    reg hold; //Zeroes counters until next valid clock cycle
    
    assign next_cycle_high = {1'b0, cycle} + 1'b1;
    assign m_cycle = cycle[4:2];
    assign t_cycle = cycle[1:0];
    
    assign m1t1 = cycle == 0 ? 1'b1 : 1'b0;

    reg [4:0] m_count; //The number of M-Cycles in current instruction

    always @(posedge clk or negedge rst) begin
        if(~rst) begin
            //reset values
            m_count = 1'b0;
            cycle = 5'b0;
            next_cycle = 5'b0;
            hold = 1'b1;
        end
        else begin
            if(hold) begin
                hold <= 1'b0;
            end
            else begin
                cycle <= next_cycle;
            end
        end
    end

    wire prefix;
    assign prefix = curr_op[7:6];

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


    always @(*) begin
        if(next_cycle_high[4:2] == m_count) begin
            next_cycle <= next_cycle_high & 2'b11;
        end else begin
            next_cycle <= next_cycle_high;
        end

        //Set Default Control Values
        reg_wr_en = 1'b0;
        reg_rd_en = 1'b0;

        case(prefix)
            00: begin
                m_count <= 1'b1;
            end

            01: begin
                //LD: 01(3:dest)(3:src)
                if(curr_op[5:3] != 3'b110) begin
                    //Load to reg
                    m_count <= 1'd1;
                    reg_rd_addr <= curr_op[2:0]; //Source
                    reg_wr_addr <= curr_op[5:3]; //Destination
                    reg_wr_en = 1'b1; //Might need to be synced with clock?
                    reg_rd_en = 1'b1;
                    if(curr_op[2:0] != 3'b110) begin
                        reg_src_sel = SBUS;
                    end
                    else begin
                        reg_src_sel = MEM;
                    end
                end
                else if(curr_op[2:0] != 3'b110) begin
                    //Load to memory bus (HL)
                end
                else begin
                    //Halt
                end
            end

            10: begin
                //8-bit Accumulator Arithmetic and logic
                //op[5:3] = operation
                //op[2:0] = reg select
            end

            11: begin
                //Memory Operations
                //Flow Control
                reg_wr_addr <= curr_op[5:3]; //Destination
                reg_wr_en = 1'b1; //Might need to be synced with clock?
                reg_src_sel = DEBUG;
            end
        endcase
    end
endmodule
