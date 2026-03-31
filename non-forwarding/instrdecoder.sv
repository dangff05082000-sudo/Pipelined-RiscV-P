module instrdecoder(
	input logic  [31:0] instr,  
    	output logic [4:0]  i_rs1_addr,          
    	output logic [4:0]  i_rs2_addr,          
    	output logic [4:0]  i_rd_addr,           
    	output logic [2:0]  funct3,       
    	output logic [6:0]  funct7,       
    	output logic [6:0]  opcode       
);

	assign 	opcode 		= instr[6:0]; 
	assign 	i_rd_addr    	= instr[11:7]; 
    	assign 	funct3 		= instr[14:12];
	assign 	i_rs1_addr   	= instr[19:15];  
    	assign 	i_rs2_addr   	= instr[24:20];  
    	assign 	funct7 		= instr[31:25];

endmodule
