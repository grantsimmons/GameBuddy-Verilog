`timescale 1ns / 1ps

module top(
    input wire clk,
    input wire [2:0] op,
    //input wire [4:0] src_data,
    //input wire [4:0] dest_data,
    input wire [2:0] reg_sel_1,
    (* clock_buffer_type="none" *) input wire sel_en_1,
    input wire [2:0] reg_sel_2,
    input wire sel_en_2,
    input wire [3:0] data,
    (* clock_buffer_type="none" *) input wire rd_en,
    //input wire ext,
    //input wire misc,
    output wire [6:0] out,
    output wire [7:0] an
    );

    wire [15:0] res;

    reg [2:0] reg_sel;
    reg wr_en;

    wire [7:0] reg_out;

    reg [7:0] reg_1_data_copy;
    reg [7:0] reg_2_data_copy;


    always @(*) begin
        if (~rd_en) begin
            if(sel_en_1) begin
                reg_sel <= reg_sel_1;
                wr_en <= 1'b1;
            end
            if(sel_en_2) begin
                reg_sel <= reg_sel_2;
                wr_en <= 1'b1;
            end
            if(~(sel_en_1) & ~(sel_en_2))
                wr_en <= 1'b0;
            if(sel_en_1 & sel_en_2)
                wr_en <= 1'b0;
        end else begin
            if(sel_en_1)
                reg_1_data_copy <= reg_out;
            if(sel_en_2)
                reg_2_data_copy <= reg_out;
        end
    end


    register_file r1(.clk(clk), .reg_sel(reg_sel), .data_in(data), .wr_en(wr_en), .rd_en(rd_en), .data_out(reg_out));
    //alu a1(.op(op), .src_data(src_data), .dest_data(dest_data), .ext(ext), .misc(misc), .res(res));
    alu a1(.op(op), .src_data(reg_1_data_copy), .dest_data(reg_2_data_copy), .res(res));
    testing t1(.clk(clk), .data(res), .out(out), .an(an));

endmodule
