`timescale 1ns / 1ns
module tb;
    reg clk;

    localparam DATA_SIZE = 5;
    localparam OP_SIZE = 3;
    localparam RES_SIZE = 16;
    reg [OP_SIZE - 1:0] op;
    reg [DATA_SIZE - 1:0] src_data;
    reg [DATA_SIZE - 1:0] dest_data;
    reg ext;
    reg misc;
    wire [RES_SIZE - 1:0] res;

    wire [ 2 * DATA_SIZE + OP_SIZE + RES_SIZE - 1:0] res_vector;

    always @(*) begin
        assign res_vector = {op, src_data, dest_data, res};
    end
    
    alu alu1(.op(op), .src_data(src_data), .dest_data(dest_data), .ext(ext), .misc(misc), .res(res));

    integer i;
    integer j;
    integer k;
    initial begin
        j = 0;
        k = 0;
        clk = 0;
        op = 0;
        src_data = 0;
        dest_data = 0;
        ext = 0;
        misc = 0;
        while(op < 7) begin
            #5; clk = ~clk;
        end
    end

    always @(posedge clk) begin
        j = (j == 16) ? 0 : j + 1;
        src_data <= j;
        k = (j == 0) ? k + 1 : k;
        if(k == 16) begin
            k = 0;
            op <= op + 1;
        end
        dest_data <= k;
        $display("src_data=%d, dest_data=%d, res=%d", src_data, dest_data, res);
    end

    initial begin
        $dumpfile("data/dumpfile.vcd");
        $dumpvars(0, tb);
    end
endmodule
