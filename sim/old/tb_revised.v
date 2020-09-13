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
    wire [RES_SIZE - 1:0] res; //Circuit output
    reg [RES_SIZE - 1:0] res_expected; //Expected output

    reg [31:0] vectornum, errors; //Bookkeeping

    reg [ 2 * DATA_SIZE + OP_SIZE + RES_SIZE + 2 - 1:0] testvectors[1:0]; //Test vector array

    alu alu1(.op(op), .src_data(src_data), .dest_data(dest_data), .ext(ext), .misc(misc), .res(res));

    integer i;
    integer j;
    integer k;

    initial begin
        $readmemb("sim/testing.tv", testvectors); //readmemh reads hex
        j = 0;
        k = 0;
        clk = 0;
        op = 0;
        src_data = 0;
        dest_data = 0;
        ext = 0;
        misc = 0;
        vectornum = 0;
        errors = 0;
        while(1) begin
            #5; clk = ~clk;
        end
    end

    always @(posedge clk) begin
        $display("Vector number: %d", vectornum);
        $display("  Vector: %b", testvectors[vectornum]);
        #1; {op, ext, misc, src_data, dest_data, res_expected} = testvectors[vectornum];
    end

    always @(negedge clk) begin
        $display("op=%b, src_data=%d, dest_data=%d, res=%d, res(binary)=%b res_expected=%b", op, src_data, dest_data, res, res, res_expected);
        if (res !== res_expected) begin
            $display("Error: inputs: %b", {op, ext, misc, src_data, dest_data});
            $display("  outputs: %b (%b exp)", res, res_expected); //%h for hex
            errors = errors + 1;
        end
        vectornum = vectornum + 1;
        if (testvectors[vectornum] === 31'bx) begin
            $display("%d tests completed with %d errors", vectornum, errors);
            $finish;
        end
    end

    initial begin
        $dumpfile("data/dumpfile.vcd");
        $dumpvars(0, tb);
    end
endmodule
