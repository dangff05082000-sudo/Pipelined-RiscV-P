module EX_MEM_reg (
    input  logic        i_clk,
    input  logic        i_reset,
    // EX/MEM th??ng không c?n stall, ch? c?n flush n?u branch sai
    input  logic        i_flush, 

    // Control Signals (WB và MEM control ?i ti?p)
    input  logic        i_mem_wren,
    input  logic        i_mem_rden,
    input  logic        i_reg_wren,
    input  logic [1:0]  i_wb_sel,
    input  logic [2:0]  i_funct3,

    // Data
    input  logic [31:0] i_alu_result,
    input  logic [31:0] i_rs2_data, // Store data
    input  logic [31:0] i_pc_four,  // Cho JAL/JALR (PC+4)
    input  logic [4:0]  i_rd_addr,

    // Output
    output logic        o_mem_wren,
    output logic        o_mem_rden,
    output logic        o_reg_wren,
    output logic [1:0]  o_wb_sel,
    output logic [2:0]  o_funct3,

    output logic [31:0] o_alu_result,
    output logic [31:0] o_rs2_data,
    output logic [31:0] o_pc_four,
    output logic [4:0]  o_rd_addr
);
    always_ff @(posedge i_clk or negedge i_reset) begin
    if (!i_reset || i_flush) begin
        o_mem_wren   <= 0;
        o_mem_rden   <= 0;
        o_reg_wren   <= 0;
        o_wb_sel     <= 2'b00; // Reset v? 0
        o_funct3     <= 3'b0;  // Reset v? 0
        o_alu_result <= 32'b0;
        o_rs2_data   <= 32'b0;
        o_pc_four    <= 32'b0;
        o_rd_addr    <= 5'b0;
        end else begin
            o_mem_wren   <= i_mem_wren;
            o_mem_rden   <= i_mem_rden;
            o_reg_wren   <= i_reg_wren;
            o_wb_sel     <= i_wb_sel;
            o_funct3     <= i_funct3;
            
            o_alu_result <= i_alu_result;
            o_rs2_data   <= i_rs2_data;
            o_pc_four    <= i_pc_four;
            o_rd_addr    <= i_rd_addr;
        end
    end
endmodule
