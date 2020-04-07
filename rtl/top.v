`timescale 1ns / 1ps

module top(
    input wire clk,
    input wire rst,
    input wire [7:0] op_next,
    input wire [7:0] testing_data
    );

    reg [7:0] op;

    wire [1:0] src_sel;
    decode d1(.clk(clk), .rst(rst), .curr_op(op), .reg_rd_en(r1.rd_en), .reg_wr_en(r1.wr_en), .reg_rd_addr(r1.rd_sel), .reg_wr_addr(r1.wr_sel), .reg_src_sel(src_sel));
    reg [7:0] reg_data_in;
    wire [7:0] reg_data_out;
    register_file_new r1(.clk(clk), .rst(rst), .wr_sel(d1.reg_wr_addr), .rd_sel(d1.reg_rd_addr), .wr_en(d1.reg_wr_en), .rd_en(d1.reg_rd_en), .data_in(reg_data_in), .data_out(reg_data_out));

    always @(posedge clk or negedge rst) begin
        if(~rst) begin
            op <= 8'b0;
        end
        else begin
            op <= op_next;
        end
    end

    always @(*) begin
        case(src_sel)
            2'b00: begin
                reg_data_in = reg_data_out;
            end
            2'b11: begin //Testbench input
                reg_data_in = testing_data[7:0];
            end
            default: begin
                reg_data_in = reg_data_out;
            end
        endcase
    end
endmodule
