module immgen(
	input 		[31:0] instr,
	output 	logic 	[31:0] imm 
);
	logic	[6:0] opcode;

	assign opcode = instr[6:0];

	always_comb begin
   	case (opcode)

	// I-opcode 
	7'b0010011 : begin
	if (instr[14:12] == 3'b001 || instr[14:12] == 3'b101) begin 
        // SLLI, SRLI, SRAI
	imm[31:5]  = 27'b0;
	imm[4:0]   = instr[24:20]; 
	end else begin
        // I-type con lai
	imm[31:12] = {20{instr[31]}};
	imm[11:0]  = instr[31:20];
        end
	end 

	// L-opcode 
   	7'b0000011 : begin
	imm[31:12] = {20{instr[31]}};
	imm[11:0]  = instr[31:20];
	end

	// JALR-opcode
	7'b1100111 : begin
	imm[31:12] = {20{instr[31]}};
	imm[11:0]  = instr[31:20];
	end

	// S-opcode 
	7'b0100011 : begin 
	imm[31:12] = {20{instr[31]}};
	imm[11:5]  = instr[31:25];
	imm[4:0]   = instr[11:7];
	end

	// B-opcode 
	7'b1100011 : begin
	imm[0]     = 1'b0;
	imm[4:1]   = instr[11:8];
	imm[10:5]  = instr[30:25];
	imm[11]    = instr[7];
	imm[12]    = instr[31]; 
	imm[31:13] = {19{instr[31]}}; // Sign extend
	end

	// U-opcode 
	7'b0110111 : begin
	imm[31:12] = instr[31:12];
	imm[11:0]  = 12'b0;
	end
	7'b0010111 : begin
        imm[31:12] = instr[31:12];
	imm[11:0]  = 12'b0;						 
	end

	// J-opcode 
   	7'b1101111 : begin
	imm[0] 	   = 1'b0;
	imm[10:1]  = instr[30:21];
	imm[11]    = instr[20];
	imm[19:12] = instr[19:12];
	imm[20]    = instr[31];
	imm[31:21] = {11{instr[31]}}; // Sign extend
        end	

   	default: imm[31:0]  = 32'b0;
	endcase
end

endmodule
