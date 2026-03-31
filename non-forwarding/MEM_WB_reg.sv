module MEM_WB_reg (
    input  logic        i_clk,
    input  logic        i_reset,
    
    // Control Signals
    input  logic        i_reg_wren,
    input  logic [1:0]  i_wb_sel,
    input  logic [2:0]  i_funct3, // <--- M?I: Input funct3 t? t?ng MEM

    // Data
    input  logic [31:0] i_alu_result,
    input  logic [31:0] i_ld_data,  
    input  logic [31:0] i_pc_four,
    input  logic [4:0]  i_rd_addr,

    // Output
    output logic        o_reg_wren,
    output logic [1:0]  o_wb_sel,
    output logic [2:0]  o_funct3, // <--- M?I: Output funct3 xu?ng t?ng WB
    output logic [31:0] o_alu_result,
    output logic [31:0] o_ld_data,
    output logic [31:0] o_pc_four,
    output logic [4:0]  o_rd_addr
);

    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            o_reg_wren   <= 0;
            o_wb_sel     <= 2'b00;
            o_funct3     <= 3'b0;   // <--- Reset funct3 v? 0
            
            o_alu_result <= 32'b0;
            o_ld_data    <= 32'b0;
            o_pc_four    <= 32'b0;
            o_rd_addr    <= 5'b0;
        end else begin
            o_reg_wren   <= i_reg_wren;
            o_wb_sel     <= i_wb_sel;
            o_funct3     <= i_funct3; // <--- C?p nh?t giá tr? funct3
            
            o_alu_result <= i_alu_result;
            o_ld_data    <= i_ld_data;
            o_pc_four    <= i_pc_four;
            o_rd_addr    <= i_rd_addr;
        end
    end
endmodule
