module register(
    input wire clk,
	input wire rst,
    input wire wr_en,
    input wire [7:0] data_in,
    output wire [7:0] data_out
    );

    reg [7:0] data;
    
    assign data_out = data;

    always @(posedge clk or negedge rst) begin
		if(~rst) begin
			data <= 0;
		end
		if(wr_en) begin
            data <= data_in;
		end
    end


endmodule
