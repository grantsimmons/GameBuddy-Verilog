module register(
    input wire clk,
    input wire wr_en,
    input wire [7:0] data_in,
    output wire [7:0] data_out
    );

    reg [7:0] data;
    
    assign data_out = data;

    always @(posedge clk) begin
        if(wr_en)
            data <= data_in;
    end


endmodule
