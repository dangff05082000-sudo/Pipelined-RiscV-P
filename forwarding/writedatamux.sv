module writedatamux(
    	input   logic [31:0] pc_four,
    	input   logic [31:0] o_alu_data,
    	input   logic [31:0] o_ld_data,
    	input   logic [1:0]  wb_sel,
    	output  logic [31:0] wb_data
);

	assign wb_data = (wb_sel == 2'b00) ? o_alu_data :  
                 (wb_sel == 2'b01) ? o_ld_data :   
                 (wb_sel == 2'b10) ? pc_four :     
                                     32'hdeadbeef; 

endmodule
