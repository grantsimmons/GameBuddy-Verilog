module decode(
    //Inputs
    input wire clk,
    input wire rst,
    input wire [7:0] op,
    //Outputs
    //Control Signals
    output reg reg_rd_en,
    output reg reg_wr_en,
    output reg [2:0] reg_rd_addr,
    output reg [2:0] reg_wr_addr,
    output reg [1:0] reg_src_sel

    );

    wire prefix;
    assign prefix = op[7:6];

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
        case(prefix)
            00: begin
                reg_wr_addr <= op[5:3]; //Destination
                reg_wr_en = 1'b1; //Might need to be synced with clock?
                reg_src_sel = DEBUG;
            end
            01: begin
                if(op[5:3] != 3'b110) begin
                    //Load to reg
                    reg_rd_addr <= op[2:0]; //Source
                    reg_wr_addr <= op[5:3]; //Destination
                    reg_wr_en = 1'b1; //Might need to be synced with clock?
                    reg_rd_en = 1'b1;
                    reg_src_sel = SBUS;
                end
                else if(op[2:0] != 3'b110) begin
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
            end
        endcase
    end
endmodule
