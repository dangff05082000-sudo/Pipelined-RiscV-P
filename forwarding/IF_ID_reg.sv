module IF_ID_reg (
    input  logic        i_clk,
    input  logic        i_reset,
    input  logic        i_stall, 
    input  logic        i_flush,
    
    input  logic [31:0] i_pc,
    input  logic [31:0] i_instr,

    output logic [31:0] o_pc,
    output logic [31:0] o_instr
);
    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            o_pc    <= 32'b0;
            o_instr <= 32'b0;
        end else if (i_flush) begin
            o_pc    <= 32'b0;
            o_instr <= 32'b0; // NOP
        end else if (!i_stall) begin
            o_pc    <= i_pc;
            o_instr <= i_instr;
        end
    end
endmodule
