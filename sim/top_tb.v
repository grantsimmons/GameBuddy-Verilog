`timescale 1ns / 1ns
module tb;
    reg clk;
	reg rst;

    localparam DATA_SIZE = 8;
    localparam ADDR_SIZE = 16;
    localparam MEM_DEPTH = 1 << ADDR_SIZE;
    localparam OP_SIZE = 8;
    localparam RES_SIZE = 8 * 8;

    reg [OP_SIZE - 1:0] vector_op, vector_op_next;
    reg [DATA_SIZE - 1:0] src_data;
    reg [DATA_SIZE - 1:0] dest_data;
    reg ext;
    reg misc;
    wire [RES_SIZE - 1:0] res; //Circuit output
    reg [RES_SIZE - 1:0] vector_res_expected, vector_res_expected_next; //Expected output

    reg [31:0] vectornum, vectornum_last, errors; //Bookkeeping

    reg [OP_SIZE + RES_SIZE - 1:0] testvectors[0:MEM_DEPTH - 1]; //Test vector array

	wire [15:0] addr_bus; //Simulated Memory control
	wire [7:0] d_bus; //Eventually wire for inout
	wire rd;

	//top dut(.clk(clk), .rst(rst), .testing_data(dest_data), .op_next(op), .rd(rd), .d_bus(d_bus), .addr_bus(addr_bus));
	top dut(.clk(clk), .rst(rst), .testing_data(dest_data), .data_out(d_bus), .rd(rd), .addr_bus(addr_bus));

	assign res =   {dut.r1.a.data_out,
					dut.r1.b.data_out,
					dut.r1.c.data_out,
					dut.r1.d.data_out,
					dut.r1.e.data_out,
					dut.r1.h.data_out,
					dut.r1.l.data_out,
                    dut.r1.f.data_out};

    integer i = 0;
    integer j = 0;
    integer l = 0;
    initial begin //Setup
        $readmemb("sim/stim.tv", testvectors); //Load test vectors
        for(l = 0; l < $size(dut.mem.mem); l = l + 1)
            dut.mem.mem[l] = 8'b0;
        $readmemb("scripts/stim.txt", dut.mem.mem); //Load program
        //for(l = 0; l < $size(dut.mem.mem); l = l + 1)
        //    $display("%h: %h", l, dut.mem.mem[l]);
        clk = 0;
        vector_op = 0;
        src_data = 0;
        dest_data = 0;
        ext = 0;
        misc = 0;
        vectornum = 0;
        vectornum_last = 0;
        vector_op_next = 0;
        errors = 0;
		rst = 0; #2; rst = 1;
        dest_data = 1;
    end

	initial begin //Clock
        while(1) begin
            #5; clk = ~clk;
        end
	end

    reg running; //Indicates that testbench should continue

    always @(posedge dut.m1t1) begin
        if(d_bus !== 8'b00010000) begin
            running <= 1'b1;
        end
        if(~dut.d1.hold) begin
            #1; {vector_op_next, vector_res_expected_next} <= testvectors[vectornum];
            vectornum_last <= vectornum; //Because of pipeline, Last op is tested, so we use vectornum_last
            vectornum = vectornum + 1;
            {vector_op, vector_res_expected} = {vector_op_next, vector_res_expected_next};
        end
        if(running && d_bus === 8'b00010000) begin
            $display("%d tests completed with %d errors", vectornum_last, errors);
            $finish;
        end
    end

    
    reg [7:0] char_arr [0:7];
    initial begin
        char_arr[7] = "A";
        char_arr[6] = "B";
        char_arr[5] = "C";
        char_arr[4] = "D";
        char_arr[3] = "E";
        char_arr[2] = "H";
        char_arr[1] = "L";
        char_arr[0] = "F";
    end
    integer k = 7;

    always @(negedge clk) begin
        if(dut.d1.t_cycle == 2'b11 && dut.d1.m_count - dut.d1.m_cycle == 1 && vector_res_expected !== 64'bx) begin
            //Compare test vector with register values on falling edge of clock on last T-Cycle of each isntruction
            $display("\nVector number: %d (%h)", vectornum_last, vectornum_last);
            $display(" Vector: %b", {vector_op, vector_res_expected});
            $display("Vector Op Code: %b (%h)\n  Result: %b\nExpected: %b", vector_op, vector_op, res, vector_res_expected);
            if (res !== vector_res_expected) begin
                $display("Error:\nInstruction: %h\nExt: %b, Misc: %b\n\nRegister:   Value:    Expected: Difference:", dut.d1.instruction, ext, misc);
                for(k = 8; k > 0; k = k - 1) begin
                    $display("%c:          %b  %b  %b", char_arr[k - 1], res[(k * DATA_SIZE)-1-:DATA_SIZE], vector_res_expected[(k * DATA_SIZE)-1-:DATA_SIZE], res[(k * DATA_SIZE)-1-:DATA_SIZE] ^ vector_res_expected[(k * DATA_SIZE)-1-:DATA_SIZE]); //%h for hex
                end
                $display("");
                errors = errors + 1;
            end
        end
    end

    initial begin
        $dumpfile("data/dumpfile.vcd");
        $dumpvars(0, tb);
    end
endmodule
