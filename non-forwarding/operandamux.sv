module operandamux(
	input 	logic [31:0] pc,
	input 	logic [31:0] o_rs1_data,
	input 	logic 	     opa_sel,
	output	logic [31:0] i_op_a
);
	assign i_op_a = (opa_sel) ? pc : o_rs1_data;

endmodule
