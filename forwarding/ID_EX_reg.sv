module ID_EX_reg (
    input  logic        i_clk,
    input  logic        i_reset,
    input  logic        i_stall,
    input  logic        i_flush,

    // Control Signals (Input)
    input  logic        i_mem_wren,
    input  logic        i_mem_rden,
    input  logic        i_reg_wren,
    input  logic [1:0]  i_wb_sel,
    input  logic [3:0]  i_alu_op,
    input  logic        i_op_a_sel,
    input  logic        i_op_b_sel,
    input  logic        i_br_un,
    input  logic [2:0]  i_funct3,
    input  logic [1:0]  i_pc_sel, // <--- THÊM DÒNG NÀY (Input t? Control Unit)

    // Data (Input)
    input  logic [31:0] i_pc,
    input  logic [31:0] i_rs1_data,
    input  logic [31:0] i_rs2_data,
    input  logic [31:0] i_imm,
    input  logic [4:0]  i_rs1_addr,
    input  logic [4:0]  i_rs2_addr,
    input  logic [4:0]  i_rd_addr,

    // Control Signals (Output)
    output logic        o_mem_wren,
    output logic        o_mem_rden,
    output logic        o_reg_wren,
    output logic [1:0]  o_wb_sel,
    output logic [3:0]  o_alu_op,
    output logic        o_op_a_sel,
    output logic        o_op_b_sel,
    output logic        o_br_un,
    output logic [2:0]  o_funct3,
    output logic [1:0]  o_pc_sel, // <--- THÊM DÒNG NÀY (Output sang t?ng EX)

    // Data (Output)
    output logic [31:0] o_pc,
    output logic [31:0] o_rs1_data,
    output logic [31:0] o_rs2_data,
    output logic [31:0] o_imm,
    output logic [4:0]  o_rs1_addr,
    output logic [4:0]  o_rs2_addr,
    output logic [4:0]  o_rd_addr
);

    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset || i_flush) begin
            o_mem_wren  <= 0;
            o_mem_rden  <= 0;
            o_reg_wren  <= 0;
            o_wb_sel    <= 0;
            o_alu_op    <= 0;
            o_pc_sel    <= 0; // <--- RESET V? 0
            o_pc        <= 0;
            // ... reset các bi?n khác ...
        end else if (!i_stall) begin
            o_mem_wren  <= i_mem_wren;
            o_mem_rden  <= i_mem_rden;
            o_reg_wren  <= i_reg_wren;
            o_wb_sel    <= i_wb_sel;
            o_alu_op    <= i_alu_op;
            o_op_a_sel  <= i_op_a_sel;
            o_op_b_sel  <= i_op_b_sel;
            o_br_un     <= i_br_un;
            o_funct3    <= i_funct3;
            o_pc_sel    <= i_pc_sel; // <--- TRUY?N TÍN HI?U
            
            o_pc        <= i_pc;
            o_rs1_data  <= i_rs1_data;
            o_rs2_data  <= i_rs2_data;
            o_imm       <= i_imm;
            o_rs1_addr  <= i_rs1_addr;
            o_rs2_addr  <= i_rs2_addr;
            o_rd_addr   <= i_rd_addr;
        end
    end
endmodule
