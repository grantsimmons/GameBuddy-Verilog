//Simulated, Asynchronous Memory, might need restructuring to synthesize as
//BRAM
module memory #(parameter ADDR_WIDTH = 16, DATA_WIDTH = 8) (
    input wire [ADDR_WIDTH - 1:0] addr_bus,
        //Requires more research. ADDR[15] of internal bus is likely
        //a chip select
        //Connects to external addr bus in top level which muxes CPU address
        //buffer with DMA address bus
    input wire [DATA_WIDTH - 1:0] data_in,
    input wire wr_en,
    input wire rd_en,

    output reg [DATA_WIDTH - 1:0] data_out
    );

    wire [7:0] test;
    assign test = mem[16'hE000];
    parameter RAM_DEPTH = 1 << ADDR_WIDTH;

    reg [DATA_WIDTH - 1:0] mem [0:RAM_DEPTH - 1];

    //Read
    always @(rd_en or wr_en or data_in or addr_bus) begin //Warning: Write capabilites synthesize as register list (Distributed RAM)
        //TODO: Invert enable polarities from CPU internal
        if(rd_en) begin
            if(addr_bus >= 16'hFF00 && addr_bus < 16'hFF40)
                data_out <= 8'b0;
            else
                data_out <= mem[addr_bus];
        end
        if(wr_en) begin
            if(addr_bus >= 16'h8000)
                mem[addr_bus] <= data_in;
        end
        //data_out <= 8'b0;
    end

    //Write
    //always @(wr_en) begin
    //    mem[addr_bus] <= data_in;
    //end

endmodule
