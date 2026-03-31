module pcadder(
	input 	logic [31:0] pc,
	output 	logic [31:0] pc_four
);

	assign pc_four = pc + 4;

endmodule
