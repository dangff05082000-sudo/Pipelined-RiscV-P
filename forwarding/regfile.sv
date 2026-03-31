module regfile(
    input   logic       i_clk,
    input   logic       i_reset, 
    input   logic       i_rd_wren,
    input   logic [4:0] i_rs1_addr,
    input   logic [4:0] i_rs2_addr,
    input   logic [4:0] i_rd_addr,
    input   logic [31:0] i_rd_data,

    output  logic [31:0] o_rs1_data,
    output  logic [31:0] o_rs2_data
);
    // M?ng thanh ghi 32x32-bit
    logic [31:0] regfile [31:0];
    
    // ----------------------------------------------------------------------
    // 1. SEQUENTIAL WRITE (Ghi tu?n t? theo c?nh lên clock)
    // ----------------------------------------------------------------------
    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            // Reset t?t c? thanh ghi v? 0
            for (int i = 0; i < 32; i++) begin
                regfile[i] <= 32'b0;
            end
        end else begin
            // Ghi d? li?u n?u Write Enable b?t và ??a ch? ?ích khác 0 (x0 luôn = 0)
            if (i_rd_wren && (i_rd_addr != 5'b0)) begin
                regfile[i_rd_addr] <= i_rd_data;
            end
        end
    end

    // ----------------------------------------------------------------------
    // 2. COMBINATIONAL READ WITH INTERNAL FORWARDING (??c t? h?p có Bypass)
    // ----------------------------------------------------------------------
    always_comb begin
        // --- Logic ??c cho RS1 ---
        if (i_rs1_addr == 5'b0) begin
            o_rs1_data = 32'b0; // x0 luôn là 0
        end 
        // Internal Forwarding: Ki?m tra xung ??t Ghi-??c ngay t?i chu k? này
        else if ((i_rs1_addr == i_rd_addr) && i_rd_wren) begin
            o_rs1_data = i_rd_data; // Bypass: L?y d? li?u ?ang ???c ghi
        end 
        else begin
            o_rs1_data = regfile[i_rs1_addr]; // Normal Read: L?y t? m?ng
        end

        // --- Logic ??c cho RS2 ---
        if (i_rs2_addr == 5'b0) begin
            o_rs2_data = 32'b0; // x0 luôn là 0
        end 
        // Internal Forwarding
        else if ((i_rs2_addr == i_rd_addr) && i_rd_wren) begin
            o_rs2_data = i_rd_data; // Bypass
        end 
        else begin
            o_rs2_data = regfile[i_rs2_addr]; // Normal Read
        end
    end

endmodule
