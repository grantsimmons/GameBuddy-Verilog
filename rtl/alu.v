module alu(
	input wire [1:0]	t_cycle,
    input wire [2:0]    op,   //ALU Operation
	input wire			alu_begin,
    input wire [7:0]    src_data,
    input wire [7:0]    dest_data,
	input wire [7:0]	flags_in,
    //input wire          size, //0 = 8-bit; 1 = 16-bit
    input wire          ext,  //CB Extension instructions
    input wire          misc, //Non-arithmetic/logic instructions
    output reg [7:0]    res,  //7:0 for 8-bit instructions
    output reg [7:0]    flags_res, //Flag results > Flag register
	output reg			wr_en_flags
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
    localparam RLCA = 3'b000;
    localparam RRCA = 3'b001;
    localparam RLA  = 3'b010;
    localparam RRA  = 3'b011;
    localparam DAA  = 3'b100; //Decimal Adjust
    localparam CPL  = 3'b101; //Accumulator Complement (Aka NOT)
    localparam SCF  = 3'b110; //Set Carry Flag
    localparam CCF  = 3'b111; //Complement Carry Flag

    //EXT+MISC Instructions
    localparam XXX  = 2'b00; //Unused
    localparam BIT  = 2'b01;
    localparam RES  = 2'b10;
    localparam SET  = 2'b11;

    //Flag Register Masks
    //localparam F_ZERO  = 4'b1000;
    //localparam F_SUB   = 4'b0100;
    //localparam F_HALF  = 4'b0010;
    //localparam F_CARRY = 4'b0001;

	//Flag Register Indeces
    localparam F_CARRY = 4; //Indicates Carry from most recent 8-bit operation
    localparam F_HALF  = 5; //Indicates Carry from previos "4-bit operation"
    localparam F_SUB   = 6; //Indicates Add/Subtract
    localparam F_ZERO  = 7; //Indicates 0 result

	reg[3:0] half_res;

	always @(t_cycle) begin
		if(t_cycle == 2'b00) begin
			wr_en_flags = 1'b0;
			flags_res <= flags_in;
		end
	end

    always @(posedge alu_begin) begin
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
						res = {src_data[6:0], src_data[7]};
						flags_res[F_CARRY] = src_data[7];
						flags_res[F_ZERO] = res == 8'b0 ? 1'b1 : 1'b0;
						flags_res[F_SUB:F_HALF] = 2'b00;
					end

					RRC: begin
						res = {src_data[0], src_data[7:1]};
						flags_res[F_CARRY] = src_data[0];
						flags_res[F_ZERO] = res == 8'b0 ? 1'b1 : 1'b0;
						flags_res[F_SUB:F_HALF] = 2'b00;
					end

					RL: begin
						{flags_res[F_CARRY], res} = {src_data[7:0], flags_in[F_CARRY]};
						flags_res[F_ZERO] = res == 8'b0 ? 1'b1 : 1'b0;
						flags_res[F_SUB:F_HALF] = 2'b00;
					end

					RR: begin
						{res, flags_res[F_CARRY]} = {flags_in[F_CARRY], src_data[7:0]};
						flags_res[F_ZERO] = res == 8'b0 ? 1'b1 : 1'b0;
						flags_res[F_SUB:F_HALF] = 2'b00;
					end

					SLA: begin
						{flags_res[F_CARRY], res} = {res, 1'b0};
						flags_res[F_ZERO] = res == 8'b0 ? 1'b1 : 1'b0;
						flags_res[F_SUB:F_HALF] = 2'b00;
					end

					SRA: begin
						{res, flags_res[F_CARRY]} = {src_data[7], src_data[7:0]};
						flags_res[F_ZERO] = res == 8'b0 ? 1'b1 : 1'b0;
						flags_res[F_SUB:F_HALF] = 2'b00;
					end

					SWAP: begin
						res = {src_data[3:0], src_data[7:4]};
						flags_res[F_ZERO] = res == 8'b0 ? 1'b1 : 1'b0;
						flags_res[F_SUB:F_CARRY] = 3'b000;
					end

					SRL: begin
						{res, flags_res[F_CARRY]} = {1'b0, src_data[7:0]};
						flags_res[F_ZERO] = res == 8'b0 ? 1'b1 : 1'b0;
						flags_res[F_SUB:F_HALF] = 2'b00;
					end
				endcase
			end
		end else begin //BASE instructions
			if(misc) begin //BASE Misc instructions
				//op   = instruction[4:3]
				//src  = F register?
				//dest = F register?
				case(op)
					RLCA: begin
						res = {dest_data[6:0], dest_data[7]};
						flags_res[F_CARRY] = dest_data[7];
						flags_res[F_ZERO:F_HALF] = 3'b000;
					end

					RRCA: begin
						res = {dest_data[0], dest_data[7:1]};
						flags_res[F_CARRY] = dest_data[0];
						flags_res[F_ZERO:F_HALF] = 3'b000;
					end

					RLA: begin
						{flags_res[F_CARRY], res} = {dest_data[7:0], flags_in[F_CARRY]};
						flags_res[F_ZERO:F_HALF] = 3'b000;
					end

					RRA: begin
						{res, flags_res[F_CARRY]} = {flags_in[F_CARRY], dest_data[7:0]};
						flags_res[F_ZERO:F_HALF] = 3'b000;
					end

					DAA: begin
					end

					CPL: begin
						res = ~dest_data;
						flags_res[F_SUB:F_HALF] = 2'b11;
					end
					
					SCF: begin
						flags_res[F_SUB:F_CARRY] = 3'b001;
					end

					CCF: begin
						flags_res[F_SUB:F_CARRY] = {2'b00, ~flags_in[F_CARRY]};
					end
				endcase
			end else begin //BASE Non-misc instructions
				//op   = instruction[5:3]
				//src  = instruction[2:0] (register index)
				//dest = 3'b111 (A register)
				case(op)
					ADD: begin
						{flags_res[F_CARRY], res} = src_data + dest_data; //Blocking assignments for res?
						flags_res[F_HALF] = (src_data[3:0] + dest_data[3:0]) & 5'h10 ? 1'b1 : 1'b0; //FIXME: Ditto
						flags_res[F_ZERO] = res == 8'b0 ? 1'b1 : 1'b0; //FIXME: Make continuous assignment?
						flags_res[F_SUB] = 1'b0;
					end

					ADC: begin
						{flags_res[F_CARRY], res} = src_data + dest_data + flags_in[F_CARRY];
						flags_res[F_ZERO] = res == 8'b0 ? 1'b1 : 1'b0;
						flags_res[F_HALF] = (src_data[3:0] + dest_data[3:0] + flags_in[F_CARRY]) & 5'h10 ? 1'b1 : 1'b0; //FIXME: Ditto
						flags_res[F_SUB] = 1'b0;
					end

					SUB: begin
					end

					SBC: begin
					end

					AND: begin
						res = src_data & dest_data;
						flags_res[F_ZERO] = res == 8'b0 ? 1'b1 : 1'b0;
						flags_res[F_SUB:F_CARRY] = 3'b010;
					end

					XOR: begin
						res = src_data ^ dest_data;
						flags_res[F_ZERO] = res == 8'b0 ? 1'b1 : 1'b0;
						flags_res[F_SUB:F_CARRY] = 3'b000;
					end

					OR: begin
						res = src_data | dest_data;
						flags_res[F_ZERO] = res == 8'b0 ? 1'b1 : 1'b0;
						flags_res[F_SUB:F_CARRY] = 3'b000;
					end

					CP: begin
					end
				endcase
			end
		end
		wr_en_flags = 1'b1;
    end
endmodule 
