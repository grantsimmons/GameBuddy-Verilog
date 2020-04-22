module register #(parameter DATA_WIDTH = 8) (
    input wire clk,
	input wire rst,
    input wire wr_en,
    input wire [DATA_WIDTH - 1:0] data_in,
    output reg [DATA_WIDTH - 1:0] data_out
    );

    always @(posedge clk or negedge rst) begin
		if(~rst) begin
			data_out = 8'b0;
		end
		else begin
			if(wr_en) begin
				data_out <= data_in;
			end
		end
    end
endmodule
