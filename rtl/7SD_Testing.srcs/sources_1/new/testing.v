`timescale 1ns / 1ps

module testing(
    input wire clk,
    input wire [31:0] data,
    output wire [6:0] out,
    output wire [7:0] an
    );

    localparam WORD_SIZE = 8;
    localparam DATA_SIZE = WORD_SIZE * 8;

    reg [15:0] divider;
    reg [2:0] anode_counter;
    reg [63:0] scroll_counter;
    reg [31:0] scroll;

    reg [DATA_SIZE - 1:0] data2 = 120'h313233343536373839414243444546;
    //reg [31:0] data2 = 32'h01234567;
    reg [WORD_SIZE * 8 - 1:0] out_buffer;

    //anode select
    assign an = ~anode_decode(anode_counter);
    //assign out = ~ascii_decode(out_buffer[(anode_counter * WORD_SIZE + (WORD_SIZE - 1)) -: WORD_SIZE]);
    assign out = ~ascii_decode(out_buffer[(anode_counter * WORD_SIZE + (WORD_SIZE - 1)) -: WORD_SIZE]);

    function [7:0] anode_decode;
        input [2:0] code;
        begin
            case(code)
                3'b100: anode_decode = 8'b00001000;
                3'b101: anode_decode = 8'b00000100;
                3'b110: anode_decode = 8'b00000010;
                3'b111: anode_decode = 8'b00000001;
                3'b000: anode_decode = 8'b10000000;
                3'b001: anode_decode = 8'b01000000;
                3'b010: anode_decode = 8'b00100000;
                3'b011: anode_decode = 8'b00010000;
            endcase
        end
    endfunction

    function [6:0] ascii_decode;
        input [7:0] data;
        begin
            case(data)
                8'b00100000: ascii_decode = 7'b0000000;
                8'b00100001: ascii_decode = 7'b0100000;
                8'b00100010: ascii_decode = 7'b0100010;
                8'b00100011: ascii_decode = 7'b0110110;
                8'b00100100: ascii_decode = 7'b1001011;
                8'b00100101: ascii_decode = 7'b1011010;
                8'b00100110: ascii_decode = 7'b1101111;
                8'b00100111: ascii_decode = 7'b0000010;
                8'b00101000: ascii_decode = 7'b1001110;
                8'b00101001: ascii_decode = 7'b1111000;
                8'b00101010: ascii_decode = 7'b1100011;
                8'b00101011: ascii_decode = 7'b0000111;
                8'b00101100: ascii_decode = 7'b0011000;
                8'b00101101: ascii_decode = 7'b0000001;
                8'b00101110: ascii_decode = 7'b0000000;
                8'b00101111: ascii_decode = 7'b0100101;
                8'b00110000: ascii_decode = 7'b1111110;
                8'b00110001: ascii_decode = 7'b0110000;
                8'b00110010: ascii_decode = 7'b1101101;
                8'b00110011: ascii_decode = 7'b1111001;
                8'b00110100: ascii_decode = 7'b0110011;
                8'b00110101: ascii_decode = 7'b1011011;
                8'b00110110: ascii_decode = 7'b1011111;
                8'b00110111: ascii_decode = 7'b1110000;
                8'b00111000: ascii_decode = 7'b1111111;
                8'b00111001: ascii_decode = 7'b1111011;
                8'b00111010: ascii_decode = 7'b0001001;
                8'b00111011: ascii_decode = 7'b0011001;
                8'b00111100: ascii_decode = 7'b1000011;
                8'b00111101: ascii_decode = 7'b1000001;
                8'b00111110: ascii_decode = 7'b1100001;
                8'b00111111: ascii_decode = 7'b1100101;
                8'b01000000: ascii_decode = 7'b1111101;
                8'b01000001: ascii_decode = 7'b1110111;
                8'b01000010: ascii_decode = 7'b0011111;
                8'b01000011: ascii_decode = 7'b1001110;
                8'b01000100: ascii_decode = 7'b0111101;
                8'b01000101: ascii_decode = 7'b1001111;
                8'b01000110: ascii_decode = 7'b1000111;
                8'b01000111: ascii_decode = 7'b1011110;
                8'b01001000: ascii_decode = 7'b0010111;
                8'b01001001: ascii_decode = 7'b0000110;
                8'b01001010: ascii_decode = 7'b0111100;
                8'b01001011: ascii_decode = 7'b1010111;
                8'b01001100: ascii_decode = 7'b0001110;
                8'b01001101: ascii_decode = 7'b1010100;
                8'b01001110: ascii_decode = 7'b1110110;
                8'b01001111: ascii_decode = 7'b1111110;
                8'b01010000: ascii_decode = 7'b1100111;
                8'b01010001: ascii_decode = 7'b1110011;
                8'b01010010: ascii_decode = 7'b1100110;
                8'b01010011: ascii_decode = 7'b1011011;
                8'b01010100: ascii_decode = 7'b0001111;
                8'b01010101: ascii_decode = 7'b0111110;
                8'b01010110: ascii_decode = 7'b0111010;
                8'b01010111: ascii_decode = 7'b0101010;
                8'b01011000: ascii_decode = 7'b0110111;
                8'b01011001: ascii_decode = 7'b0111011;
                8'b01011010: ascii_decode = 7'b1101101;
                8'b01011011: ascii_decode = 7'b1001110;
                8'b01011100: ascii_decode = 7'b0010011;
                8'b01011101: ascii_decode = 7'b1111000;
                8'b01011110: ascii_decode = 7'b1100010;
                8'b01011111: ascii_decode = 7'b0001000;
                default:     ascii_decode = 7'b0000001;
            endcase
        end
    endfunction
    
    function [6:0] hex_decode;
        input [3:0] data;
        begin
            case(data)
                4'b0000: hex_decode = 7'b1111110;
                4'b0001: hex_decode = 7'b0110000;
                4'b0010: hex_decode = 7'b1101101;
                4'b0011: hex_decode = 7'b1111001;
                4'b0100: hex_decode = 7'b0110011;
                4'b0101: hex_decode = 7'b1011011;
                4'b0110: hex_decode = 7'b1011111;
                4'b0111: hex_decode = 7'b1110000;
                4'b1000: hex_decode = 7'b1111111;
                4'b1001: hex_decode = 7'b1110011;
                4'b1010: hex_decode = 7'b1110111;
                4'b1011: hex_decode = 7'b0011111;
                4'b1100: hex_decode = 7'b1001110;
                4'b1101: hex_decode = 7'b0111101;
                4'b1110: hex_decode = 7'b1001111;
                4'b1111: hex_decode = 7'b1000111;
            endcase
        end
    endfunction

    //Behavior
    initial begin
        divider <= 0;
        anode_counter <= 0;
        scroll_counter <= 0;
        scroll <= 0;
    end

    always @(posedge clk) begin
        divider <= (divider == 16'hFFFF) ? 0 : divider + 1;
        if(divider == 16'hFFFF) begin
            anode_counter <= (anode_counter == 7) ? 0 : anode_counter + 1; //Iterate through displays
            scroll_counter <= (scroll_counter == 16'h03FF) ? 0: scroll_counter + 1;
            if(scroll_counter == 16'h03FF) begin
                scroll <= (scroll == (DATA_SIZE / WORD_SIZE) - 1) ? 0 : scroll + 1;
            end
        end
        //nibble select
        out_buffer <= data2[DATA_SIZE + (scroll * WORD_SIZE) - 1 -: 8 * WORD_SIZE];
        //out_buffer <= data;
        //out_buffer <= ~ascii_decode(data2[(anode_counter - scroll) * WORD_SIZE + (WORD_SIZE - 1) -: WORD_SIZE]);
    end

endmodule
