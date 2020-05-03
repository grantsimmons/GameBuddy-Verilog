module register_file_new(
    //Inputs
    input wire          clk,
    input wire          m1t1,
    input wire          writeback,
    input wire          rst,
    input wire [2:0]    wr_sel, //Internal 3-bit register address
    input wire [2:0]    rd_sel, //Internal 3-bit register address
    input wire [2:0]    mem_addr_sel,
    input wire          drive_addr, //Drive address bus this cycle
    input wire          wr_en,
    input wire          wr_en_flags,
    input wire          rd_en,
    input wire [7:0]    data_in,
    input wire [7:0]    alu_flags_in,
    input wire          inc_pc,
    //Outputs
    output reg [7:0]    data_out,
    output reg [7:0]    mem_data_out,
    output wire [7:0]   flags_out,
    //output reg [7:0]    data_out_8,
    //output reg [15:0]    data_out_16,
    output reg [15:0]  addr_bus
    );
    
    localparam REG_A = 3'b111;
    localparam REG_B = 3'b000;
    localparam REG_C = 3'b001;
    localparam REG_D = 3'b010;
    localparam REG_E = 3'b011;
    localparam REG_H = 3'b100;
    localparam REG_L = 3'b101;
    localparam MEM   = 3'b110;
    //110 = data bus //Double as F?

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

    register #(8) a(.clk(writeback), .rst(rst), .wr_en(demux_wr_en_a), .data_in(demux_data_a), .data_out(rdmux_data_out_a));
    register #(8) b(.clk(writeback), .rst(rst), .wr_en(demux_wr_en_b), .data_in(demux_data_b), .data_out(rdmux_data_out_b));
    register #(8) c(.clk(writeback), .rst(rst), .wr_en(demux_wr_en_c), .data_in(demux_data_c), .data_out(rdmux_data_out_c));
    register #(8) d(.clk(writeback), .rst(rst), .wr_en(demux_wr_en_d), .data_in(demux_data_d), .data_out(rdmux_data_out_d));
    register #(8) e(.clk(writeback), .rst(rst), .wr_en(demux_wr_en_e), .data_in(demux_data_e), .data_out(rdmux_data_out_e));
    register #(8) h(.clk(writeback), .rst(rst), .wr_en(demux_wr_en_h), .data_in(demux_data_h), .data_out(rdmux_data_out_h));
    register #(8) l(.clk(writeback), .rst(rst), .wr_en(demux_wr_en_l), .data_in(demux_data_l), .data_out(rdmux_data_out_l));

    register #(8) f(.clk(writeback), .rst(rst), .wr_en(wr_en_flags), .data_in(alu_flags_in), .data_out(flags_out)); //FIXME: Need arbitrary write for POPAF and SCF/CCF
    //register #(8) temp_lsb(.clk(writeback), .rst(rst), .wr_en(), .data_in(), .data_out());
    //register #(8) temp_msb(.clk(writeback), .rst(rst), .wr_en(), .data_in(), .data_out());

    reg pc_wr_en;
    reg [15:0] pc_data_in;
    wire [15:0] pc_next;
    wire pc_write;
    assign pc_write = m1t1 | inc_pc;
    assign pc_next = pc_data_in + 1'b1;
    //wire [15:0] test;
    register #(16) pc(.clk(pc_write), .rst(rst), .data_in(pc_data_in), .wr_en(pc_wr_en));
    //assign addr_bus = pc.data_out;
    //register #(16) sp(.clk(clk), .rst(rst), .data_out(addr_bus));

    //PC Auto-increment for testing
    always @(posedge pc_write or negedge rst) begin
        if(~rst) begin
            pc_data_in = 0;
            pc_wr_en = 0;
        end
        else begin
            pc_data_in <= pc_next;
            pc_wr_en = 1'b1;
        end
    end

    always @(*) begin
        if(drive_addr) begin
            //case(rd_sel) //TODO: Keep an eye out for this. May encounter issues if you do ALU operation and memory operation at the same time
            case(mem_addr_sel)
                3'b000: addr_bus = pc.data_out;
                //3'b001: addr_bus = {temp_msb.data_out, temp_lsb.data_out};
                3'b100: addr_bus = {b.data_out, c.data_out};
                3'b101: addr_bus = {d.data_out, e.data_out};
                3'b110: addr_bus = {h.data_out, l.data_out};
                //3'b111: addr_bus = sp.data_out;
                default: addr_bus = 8'bx;
            endcase
        end
        else begin
            addr_bus = pc.data_out;
        end




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
            MEM: begin
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
                mem_data_out = data_in; //Source mux must be Data Bus
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
                //MEM: begin //Data bus passthrough
                //    data_out = data_in;
                //end
                default: begin
                    data_out = 0;
                end
            endcase
        end else begin
            data_out = 8'bx; //Not Synthesizable?
        end
    end
endmodule
