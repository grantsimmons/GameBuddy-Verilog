`timescale 1ns / 1ns
module tb;
    reg clk;
	reg rst;

    localparam DATA_SIZE = 8;
    localparam OP_SIZE = 8;
    localparam RES_SIZE = 8 * 7;
    reg [OP_SIZE - 1:0] op;
    reg [DATA_SIZE - 1:0] src_data;
    reg [DATA_SIZE - 1:0] dest_data;
    reg ext;
    reg misc;
    wire [RES_SIZE - 1:0] res; //Circuit output
    reg [RES_SIZE - 1:0] res_expected; //Expected output

    reg [31:0] vectornum, errors; //Bookkeeping

    reg [ OP_SIZE + RES_SIZE - 1:0] testvectors[6:0]; //Test vector array

	top dut(.clk(clk), .rst(rst), .testing_data(dest_data), .op_next(op));

	assign res =   {dut.r1.a.data,
					dut.r1.b.data,
					dut.r1.c.data,
					dut.r1.d.data,
					dut.r1.e.data,
					dut.r1.h.data,
					dut.r1.l.data};

    integer i;
    integer j;
    integer k;

    initial begin //Setup
        $readmemb("sim/testing_top.tv", testvectors); //readmemh reads hex
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
		rst = 0; #2; rst = 1;
        dest_data = 1;
    end

	initial begin //Clock
        while(1) begin
            #5; clk = ~clk;
        end
	end

    always @(posedge dut.m1t1) begin
        $display("Vector number: %d", vectornum);
        $display("  Vector: %b", testvectors[vectornum]);
		#1; {op, res_expected} = testvectors[vectornum];
        vectornum = vectornum + 1;
    end

    always @(negedge clk) begin
        $display("op=%b, res=%d, res(binary)=%b res_expected=%b", op, res, res, res_expected);
        if (res !== res_expected) begin
            $display("Error: inputs: %b", {op, ext, misc, src_data, dest_data});
            $display("  outputs: %b (%b exp)", res, res_expected); //%h for hex
            errors = errors + 1;
        end
        if (testvectors[vectornum] === 64'bx) begin
            $display("%d tests completed with %d errors", vectornum, errors);
            $finish;
        end
    end

    initial begin
        $dumpfile("data/dumpfile.vcd");
        $dumpvars(0, tb);
    end
endmodule
