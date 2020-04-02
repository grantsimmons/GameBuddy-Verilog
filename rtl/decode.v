module decode(
    //Inputs
    input wire [7:0] op
    //Outputs
    );
    wire prefix;
    assign prefix = op[7:6];

    //Register Encodings
    localparam REG_A = 3'b111;
    localparam REG_B = 3'b000;
    localparam REG_C = 3'b001;
    localparam REG_D = 3'b010;
    localparam REG_E = 3'b011;
    localparam REG_H = 3'b100;
    localparam REG_L = 3'b101;
    localparam MEM_HL = 3'b110;

    always @(*) begin
        case(prefix)
            00: begin
                //
            end
            01: begin
                //Load to reg
                //Load to memory bus (HL)
                //Halt
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
