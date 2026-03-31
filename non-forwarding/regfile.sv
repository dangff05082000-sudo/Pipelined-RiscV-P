module regfile(
    input   logic       i_clk,
    input   logic       i_reset,
    input   logic       i_rd_wren,
    input   logic [4:0] i_rs1_addr,
    input   logic [4:0] i_rs2_addr,
    input   logic [4:0] i_rd_addr,  // Ðây là ??a ch? ghi t? WB
    input   logic [31:0] i_rd_data, // Ðây là d? li?u ghi t? WB

    output  logic [31:0] o_rs1_data,
    output  logic [31:0] o_rs2_data
);
    logic [31:0] regfile [31:0];

    // Logic Ghi (Gi? nguyên)
    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            for (int i=0; i<32; i++) regfile[i] <= 32'b0;
        end else if (i_rd_wren && (i_rd_addr != 5'b0)) begin
            regfile[i_rd_addr] <= i_rd_data;
        end
    end

    // Logic Ð?c (S?a ?? h? tr? Internal Forwarding)
    // N?u ?ang ghi trùng v?i ??a ch? ??c -> L?y luôn d? li?u ?ang ghi (Bypass)
    always_comb begin
        // RS1
        if (i_rs1_addr == 5'b0) 
            o_rs1_data = 32'b0;
        else if ((i_rs1_addr == i_rd_addr) && i_rd_wren) // Internal Forwarding
            o_rs1_data = i_rd_data;
        else 
            o_rs1_data = regfile[i_rs1_addr];

        // RS2
        if (i_rs2_addr == 5'b0) 
            o_rs2_data = 32'b0;
        else if ((i_rs2_addr == i_rd_addr) && i_rd_wren) // Internal Forwarding
            o_rs2_data = i_rd_data;
        else 
            o_rs2_data = regfile[i_rs2_addr];
    end

endmodule
