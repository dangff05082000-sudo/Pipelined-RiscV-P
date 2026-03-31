module alu(
	input  	wire 	[31:0] i_op_a,
    	input  	wire 	[31:0] i_op_b,
    	input  	wire 	[3:0]  i_alu_op, 
    	output 	logic 	[31:0] o_alu_data
);
    	localparam ALU_ADD  	= 4'b0000;
    	localparam ALU_SUB  	= 4'b0001;
    	localparam ALU_SLL  	= 4'b0010;
    	localparam ALU_SLT  	= 4'b0011;
    	localparam ALU_SLTU 	= 4'b0100;
    	localparam ALU_XOR  	= 4'b0101;
    	localparam ALU_SRL  	= 4'b0110;
    	localparam ALU_SRA  	= 4'b0111;
    	localparam ALU_OR   	= 4'b1000;
    	localparam ALU_AND  	= 4'b1001;
    	localparam ALU_COPY_B 	= 4'b1010;
    	localparam ALU_XXX  	= 4'b1111;

    	// ADD, SUB
    	wire [31:0] op_b_inv 	= ~i_op_b;
    	wire [32:0] sum 	= {1'b0, i_op_a} + {1'b0, op_b_inv} + 33'd1;
    	wire [31:0] sub_result 	= sum[31:0];
    	wire [31:0] add_result 	= i_op_a + i_op_b;

    	// SLT, SLTU
    	wire	a_sign 		= i_op_a[31];
    	wire 	b_sign 		= i_op_b[31];
    	wire 	sub_sign 	= sub_result[31];
    	wire 	overflow 	= (!a_sign & b_sign & sub_sign) | (a_sign & !b_sign & !sub_sign);
    	wire 	slt_logic 	= sub_sign ^ overflow;

    	wire [31:0] slt_result 	= {31'b0, slt_logic};
    	wire [31:0] sltu_result = {31'b0, !sum[32]};

    	// XOR
    	wire [31:0] xor_result 	= i_op_a ^ i_op_b;

	// OR
    	wire [31:0] or_result  	= i_op_a | i_op_b;

	// AND
    	wire [31:0] and_result 	= i_op_a & i_op_b;

    	wire [4:0] shamt 	= i_op_b[4:0];
	// SLL
    	wire [31:0] sll_1  	= (shamt[0]) ? {i_op_a[30:0], 1'b0} : i_op_a;
    	wire [31:0] sll_2  	= (shamt[1]) ? {sll_1[29:0],  2'b0} : sll_1;
    	wire [31:0] sll_4  	= (shamt[2]) ? {sll_2[27:0],  4'b0} : sll_2;
    	wire [31:0] sll_8  	= (shamt[3]) ? {sll_4[23:0],  8'b0} : sll_4;
    	wire [31:0] sll_16 	= (shamt[4]) ? {sll_8[15:0], 16'b0} : sll_8;
    	wire [31:0] sll_result 	= sll_16;

	// SRL
    	wire [31:0] srl_1  	= (shamt[0]) ? {1'b0, i_op_a[31:1]} : i_op_a;
    	wire [31:0] srl_2  	= (shamt[1]) ? {2'b0, srl_1[31:2]}  : srl_1;
    	wire [31:0] srl_4  	= (shamt[2]) ? {4'b0, srl_2[31:4]}  : srl_2;
    	wire [31:0] srl_8  	= (shamt[3]) ? {8'b0, srl_4[31:8]}  : srl_4;
    	wire [31:0] srl_16 	= (shamt[4]) ? {16'b0, srl_8[31:16]} : srl_8;
    	wire [31:0] srl_result 	= srl_16;

	// SRA
    	wire [31:0] sra_1  	= (shamt[0]) ? {{1{i_op_a[31]}}, i_op_a[31:1]} : i_op_a;
    	wire [31:0] sra_2  	= (shamt[1]) ? {{2{sra_1[31]}},  sra_1[31:2]}  : sra_1;
    	wire [31:0] sra_4  	= (shamt[2]) ? {{4{sra_2[31]}},  sra_2[31:4]}  : sra_2;
    	wire [31:0] sra_8  	= (shamt[3]) ? {{8{sra_4[31]}},  sra_4[31:8]}  : sra_4;
    	wire [31:0] sra_16 	= (shamt[4]) ? {{16{sra_8[31]}}, sra_8[31:16]} : sra_8;
    	wire [31:0] sra_result 	= sra_16;

    	always_comb begin
        case (i_alu_op)
         ALU_ADD:    o_alu_data = add_result;
         ALU_SUB:    o_alu_data = sub_result;
         ALU_SLL:    o_alu_data = sll_result;
         ALU_SLT:    o_alu_data = slt_result;
         ALU_SLTU:   o_alu_data = sltu_result;
         ALU_XOR:    o_alu_data = xor_result;
         ALU_SRL:    o_alu_data = srl_result;
         ALU_SRA:    o_alu_data = sra_result;
         ALU_OR:     o_alu_data = or_result;
         ALU_AND:    o_alu_data = and_result;
         ALU_COPY_B: o_alu_data = i_op_b;
         default:    o_alu_data = 32'hdeadbeef;
        endcase
    	end

endmodule
