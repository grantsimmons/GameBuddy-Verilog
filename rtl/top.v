`timescale 1ns / 1ns

module top(
    //Inputs
    input wire          clk,
    input wire          rst,
    //input wire [7:0]    d_bus,
    input wire [7:0]    testing_data,
    //Outputs
    output wire [15:0]  addr_bus,
    output wire [7:0]   data_out,
    output wire         rd,
    output wire         m1t1
    );

    wire [1:0] reg_src_sel; //Register File Mux Select
        //0: Register File Output
        //1: ALU
        //2: Memory Bus
        //3: Debug
    reg [7:0] reg_data_in;  //Register File Mux. Muxes Data Bus, Register File Output, ALU, and Testbench
    wire [7:0] reg_data_out; //Register File Output

    reg mem_ctrl_sel; //Selects address select for memory address mux
        //0: CPU
        //1: DMA
    reg [15:0] addr_bus_buf; //Address Bus Buffer
    reg [15:0] mem_addr_muxed; //Muxes DMA Address Bus and Address Bus Buffer
    wire [7:0] mem_data_out; //External Memory Output
    reg [7:0] mem_data_in; //External Memory Input
    reg mem_wr_en;
    reg [7:0] int_data_in; //Internal Data Input. Buffers mem_data_out
    reg [7:0] int_data_out; //Internal Data Output. Buffered by mem_data_in

    wire [7:0] alu_res;

    assign data_out = mem_data_out; //Stops testbench

    //Decode Timing Information
    wire [3:0] m_cycle;
    wire [1:0] t_cycle;

    decode              d1( .clk(clk), 
                            .rst(rst), 
                            .data_bus_in(int_data_in),
                            .reg_rd_en(r1.rd_en), 
                            .reg_wr_en(r1.wr_en), 
                            .reg_rd_addr(r1.rd_sel), 
                            .reg_wr_addr(r1.wr_sel), 
                            .reg_src_sel(reg_src_sel), 
                            //.addr_bus(addr_bus), 
                            .rd(rd), 
                            .m1t1(m1t1),
                            .m_cycle(m_cycle),
                            .t_cycle(t_cycle)
                        );

    //dma dma(.data_in(mem_data_out), .addr(dma_addr_bus)); //Should
    //technically go outside of top file

    register_file_new   r1( .clk(clk), 
                            .m1t1(m1t1), 
                            .writeback(d1.reg_writeback),
                            .rst(rst), 
                            .wr_sel(d1.reg_wr_addr), 
                            .rd_sel(d1.reg_rd_addr), 
                            .drive_addr(d1.reg_drive_addr),
                            .wr_en(d1.reg_wr_en), 
                            .wr_en_flags(a1.wr_en_flags),
                            .rd_en(d1.reg_rd_en), 
                            .data_in(reg_data_in), 
                            .alu_flags_in(a1.flags_res),
                            .inc_pc(d1.reg_inc_pc),
                            .data_out(reg_data_out), 
                            .addr_bus(addr_bus)
                        );

    alu                 a1( .t_cycle(t_cycle),
                            .op(d1.alu_op),
                            .alu_begin(d1.alu_begin),
                            .src_data(r1.data_out),
                            .dest_data(r1.a.data_out),
                            .flags_in(r1.flags_out),
                            .ext(d1.ext),
                            .misc(d1.misc),
                            .res(alu_res)
                        );

    memory              mem(.addr_bus(mem_addr_muxed), 
                            .data_in(mem_data_in), 
                            .wr_en(mem_wr_en), 
                            .rd_en(rd), 
                            .data_out(mem_data_out)
                        );

    //TODO: Put gates on buffers?
    //CPU Address Buffer
    always @(t_cycle or addr_bus) begin
        if(t_cycle == 2'b10 && ~d1.hold)
            addr_bus_buf = addr_bus;
    end

    //CPU Data Buffer
    //always @(posedge clk) begin
    always @(t_cycle) begin
        if(t_cycle == 2'b00) begin
            //CPU samples external data bus on T1
            int_data_in <= mem_data_out;
        end
        //TODO: Find out when this actually happens
        mem_data_in <= int_data_out;
    end

    //Memory Address Mux
    always @(*) begin
        mem_wr_en <= 1'b0;
        case(mem_ctrl_sel)
            1'b0: mem_addr_muxed <= addr_bus_buf;
            //1'b1: mem_addr_muxed <= dma_addr_bus;
            default: mem_addr_muxed <= addr_bus_buf;
        endcase
    end

    //Register File Data Source Mux
    always @(*) begin
        case(reg_src_sel)
            2'b00: begin
                reg_data_in = reg_data_out; //Register bus
            end
            2'b01: begin
                reg_data_in = alu_res; //ALU result
            end
            2'b10: begin
                reg_data_in = int_data_in; //Memory Data Bus
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
