module alu(
    input wire [2:0]    op,   //ALU Operation
    input wire [4:0]    src_data,
    input wire [4:0]    dest_data,
    //input wire          ext,  //CB Extension instructions
    //input wire          misc, //Non-arithmetic/logic instructions
    output reg [15:0]   res  //7:0 for 8-bit instructions
    );

    //Base instructions
    localparam ADD  = 3'b000;
    localparam ADC  = 3'b001;
    localparam SUB  = 3'b010;
    localparam SBC  = 3'b011;
    localparam AND  = 3'b100;
    localparam XOR  = 3'b101;
    localparam OR   = 3'b110;
    localparam CP   = 3'b111;

    //Extensions
    localparam RLC  = 3'b000;
    localparam RRC  = 3'b001;
    localparam RL   = 3'b010;
    localparam RR   = 3'b011;
    localparam SLA  = 3'b100;
    localparam SRA  = 3'b101;
    localparam SWAP = 3'b110;
    localparam SRL  = 3'b111;

    //MISC Instructions
    localparam DAA  = 2'b00;
    localparam CPL  = 2'b01;
    localparam SCF  = 2'b10;
    localparam CCF  = 2'b11;

    //EXT+MISC Instructions
    localparam XXX  = 2'b00; //Unused
    localparam BIT  = 2'b01;
    localparam RES  = 2'b10;
    localparam SET  = 2'b11;

    //Flag Register Masks
    localparam F_ZERO  = 4'b1000;
    localparam F_SUB   = 4'b0100;
    localparam F_HALF  = 4'b0010;
    localparam F_CARRY = 4'b0001;

    always @(*) begin
        if(ext) begin //EXT instructions
            if(misc) begin //EXT+MISC instructions
                //op   = instruction[7:6]
                //src  = instruction[5:3] (encoded bit number)
                //dest = instruction[2:0] (register index)
                case(op)
                    BIT: begin
                    end

                    RES: begin
                    end

                    SET: begin
                    end
                endcase
            end else begin //EXT Arithmetic instructions
                //op   = instruction[5:3]
                //src  = instruction[2:0]
                //dest = instruction[2:0]
                case(op)
                    RLC: begin
                        res = {dest_data << src_data, dest_data[4]};
                    end

                    RRC: begin
                        res = {dest_data[0], (dest_data >> src_data)};
                    end

                    RL: begin
                        res = {(dest_data << src_data), dest_data[4]};
                    end

                    RR: begin
                        res = {dest_data[0], (dest_data >> src_data)};
                    end

                    SLA: begin
                        res = {(dest_data << src_data), 1'b1};
                    end

                    SRA: begin
                        res = {dest_data[4], (dest_data >> src_data)};
                    end

                    SWAP: begin
                    end

                    SRL: begin
                        res = {1'b0, (dest_data >> src_data)};
                    end
                endcase
            end
        end else begin //BASE instructions
            if(misc) begin //BASE Misc instructions
                //op   = instruction[4:3]
                //src  = F register?
                //dest = F register?
                case(op)
                    DAA: begin
                    end

                    CPL: begin
                    end
                    
                    SCF: begin
                    end

                    CCF: begin
                    end
                endcase
            end else begin //BASE Non-misc instructions
                //op   = instruction[5:3]
                //src  = instruction[2:0] (register index)
                //dest = 3'b111 (A register)
                case(op)
                    ADD: begin
                        res = src_data + dest_data;
                    end

                    ADC: begin
                        res = src_data + dest_data;
                    end

                    SUB: begin
                        res = src_data - dest_data;
                    end

                    SBC: begin
                        res = src_data - dest_data;
                    end

                    AND: begin
                        res = src_data & dest_data;
                    end

                    XOR: begin
                        res = src_data ^ dest_data;
                    end

                    OR: begin
                        res = src_data | dest_data;
                    end

                    CP: begin
                    end
                endcase
            end
        end
    end
endmodule 
