module register_file_new(
    //Inputs
    input wire          clk,
    input wire          rst,
    input wire [2:0]    wr_sel,
    input wire [2:0]    rd_sel,
    input wire          wr_en,
    input wire          rd_en,
    input wire [7:0]    data_in,
    //Outputs
    output reg [7:0]    data_out
    );
    
    localparam REG_A = 3'b111;
    localparam REG_B = 3'b000;
    localparam REG_C = 3'b001;
    localparam REG_D = 3'b010;
    localparam REG_E = 3'b011;
    localparam REG_H = 3'b100;
    localparam REG_L = 3'b101;
    //110 = data bus

    reg [7:0]  demux_data_a,
               demux_data_b,
               demux_data_c,
               demux_data_d,
               demux_data_e,
               demux_data_h,
               demux_data_l;

    wire [7:0] rdmux_data_out_a,
               rdmux_data_out_b,
               rdmux_data_out_c,
               rdmux_data_out_d,
               rdmux_data_out_e,
               rdmux_data_out_h,
               rdmux_data_out_l;

    reg        demux_wr_en_a,
               demux_wr_en_b,
               demux_wr_en_c,
               demux_wr_en_d,
               demux_wr_en_e,
               demux_wr_en_h,
               demux_wr_en_l;

    register a(.clk(clk), .rst(rst), .wr_en(demux_wr_en_a), .data_in(demux_data_a), .data_out(rdmux_data_out_a));
    register b(.clk(clk), .rst(rst), .wr_en(demux_wr_en_b), .data_in(demux_data_b), .data_out(rdmux_data_out_b));
    register c(.clk(clk), .rst(rst), .wr_en(demux_wr_en_c), .data_in(demux_data_c), .data_out(rdmux_data_out_c));
    register d(.clk(clk), .rst(rst), .wr_en(demux_wr_en_d), .data_in(demux_data_d), .data_out(rdmux_data_out_d));
    register e(.clk(clk), .rst(rst), .wr_en(demux_wr_en_e), .data_in(demux_data_e), .data_out(rdmux_data_out_e));
    register h(.clk(clk), .rst(rst), .wr_en(demux_wr_en_h), .data_in(demux_data_h), .data_out(rdmux_data_out_h));
    register l(.clk(clk), .rst(rst), .wr_en(demux_wr_en_l), .data_in(demux_data_l), .data_out(rdmux_data_out_l));

    always @(*) begin
        //DEMUX
        case(wr_sel)
            REG_A: begin
                demux_data_a = data_in;
                demux_data_b = 0;
                demux_data_c = 0;
                demux_data_d = 0;
                demux_data_e = 0;
                demux_data_h = 0;
                demux_data_l = 0;
                demux_wr_en_a = wr_en;
                demux_wr_en_b = 0;
                demux_wr_en_c = 0;
                demux_wr_en_d = 0;
                demux_wr_en_e = 0;
                demux_wr_en_h = 0;
                demux_wr_en_l = 0;
            end
            REG_B: begin
                demux_data_a = 0;
                demux_data_b = data_in;
                demux_data_c = 0;
                demux_data_d = 0;
                demux_data_e = 0;
                demux_data_h = 0;
                demux_data_l = 0;
                demux_wr_en_a = 0;
                demux_wr_en_b = wr_en;
                demux_wr_en_c = 0;
                demux_wr_en_d = 0;
                demux_wr_en_e = 0;
                demux_wr_en_h = 0;
                demux_wr_en_l = 0;
            end
            REG_C: begin
                demux_data_a = 0;
                demux_data_b = 0;
                demux_data_c = data_in;
                demux_data_d = 0;
                demux_data_e = 0;
                demux_data_h = 0;
                demux_data_l = 0;
                demux_wr_en_a = 0;
                demux_wr_en_b = 0;
                demux_wr_en_c = wr_en;
                demux_wr_en_d = 0;
                demux_wr_en_e = 0;
                demux_wr_en_h = 0;
                demux_wr_en_l = 0;
            end
            REG_D: begin
                demux_data_a = 0;
                demux_data_b = 0;
                demux_data_c = 0;
                demux_data_d = data_in;
                demux_data_e = 0;
                demux_data_h = 0;
                demux_data_l = 0;
                demux_wr_en_a = 0;
                demux_wr_en_b = 0;
                demux_wr_en_c = 0;
                demux_wr_en_d = wr_en;
                demux_wr_en_e = 0;
                demux_wr_en_h = 0;
                demux_wr_en_l = 0;
            end
            REG_E: begin
                demux_data_a = 0;
                demux_data_b = 0;
                demux_data_c = 0;
                demux_data_d = 0;
                demux_data_e = data_in;
                demux_data_h = 0;
                demux_data_l = 0;
                demux_wr_en_a = 0;
                demux_wr_en_b = 0;
                demux_wr_en_c = 0;
                demux_wr_en_d = 0;
                demux_wr_en_e = wr_en;
                demux_wr_en_h = 0;
                demux_wr_en_l = 0;
            end
            REG_H: begin
                demux_data_a = 0;
                demux_data_b = 0;
                demux_data_c = 0;
                demux_data_d = 0;
                demux_data_e = 0;
                demux_data_h = data_in;
                demux_data_l = 0;
                demux_wr_en_a = 0;
                demux_wr_en_b = 0;
                demux_wr_en_c = 0;
                demux_wr_en_d = 0;
                demux_wr_en_e = 0;
                demux_wr_en_h = wr_en;
                demux_wr_en_l = 0;
            end
            REG_L: begin
                demux_data_a = 0;
                demux_data_b = 0;
                demux_data_c = 0;
                demux_data_d = 0;
                demux_data_e = 0;
                demux_data_h = 0;
                demux_data_l = data_in;
                demux_wr_en_a = 0;
                demux_wr_en_b = 0;
                demux_wr_en_c = 0;
                demux_wr_en_d = 0;
                demux_wr_en_e = 0;
                demux_wr_en_h = 0;
                demux_wr_en_l = wr_en;
            end
            default: begin
                demux_data_a = 0;
                demux_data_b = 0;
                demux_data_c = 0;
                demux_data_d = 0;
                demux_data_e = 0;
                demux_data_h = 0;
                demux_data_l = 0;
                demux_wr_en_a = 0;
                demux_wr_en_b = 0;
                demux_wr_en_c = 0;
                demux_wr_en_d = 0;
                demux_wr_en_e = 0;
                demux_wr_en_h = 0;
                demux_wr_en_l = 0;
            end
        endcase

        //MUX
        if(rd_en) begin
            case(rd_sel)
                REG_A: begin
                    data_out = rdmux_data_out_a;
                end
                REG_B: begin
                    data_out = rdmux_data_out_b;
                end
                REG_C: begin
                    data_out = rdmux_data_out_c;
                end
                REG_D: begin
                    data_out = rdmux_data_out_d;
                end
                REG_E: begin
                    data_out = rdmux_data_out_e;
                end
                REG_H: begin
                    data_out = rdmux_data_out_h;
                end
                REG_L: begin
                    data_out = rdmux_data_out_l;
                end 
                default: begin
                    data_out = 0;
                end
            endcase
        end else begin
            data_out = 7'bz;
        end
    end
endmodule
