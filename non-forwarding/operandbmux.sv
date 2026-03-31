module operandbmux(
	input 	logic [31:0] o_immgen,
	input 	logic [31:0] o_rs2_data,
	input 	logic 	     opb_sel,
	output	logic [31:0] i_op_b
);
	assign i_op_b = (opb_sel) ? o_immgen : o_rs2_data;

endmodule
