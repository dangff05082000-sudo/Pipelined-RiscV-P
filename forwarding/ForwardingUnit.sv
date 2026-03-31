module ForwardingUnit (
    // Inputs: ??a ch? thanh ghi ngu?n ?ang c?n dùng ? t?ng EX
    input  logic [4:0] ex_rs1_addr,
    input  logic [4:0] ex_rs2_addr,

    // Inputs: ??a ch? và tín hi?u ghi c?a l?nh ?i tr??c (?ang ? t?ng MEM)
    input  logic [4:0] mem_rd_addr,
    input  logic       mem_reg_wren,

    // Inputs: ??a ch? và tín hi?u ghi c?a l?nh ?i tr??c n?a (?ang ? t?ng WB)
    input  logic [4:0] wb_rd_addr,
    input  logic       wb_reg_wren,

    // Outputs: Tín hi?u ?i?u khi?n Mux Forwarding
    output logic [1:0] forward_a, // Cho Operand A (RS1)
    output logic [1:0] forward_b  // Cho Operand B (RS2)
);

    always_comb begin
        // ---------------------------------------------------------
        // 1. FORWARDING CHO OPERAND A (RS1)
        // ---------------------------------------------------------
        forward_a = 2'b00; // M?c ??nh: L?y t? ID/EX (RegFile c?)

        // ?u tiên 1: Forward t? MEM (D? li?u m?i nh?t, v?a tính xong ? EX tr??c ?ó)
        // ?i?u ki?n: L?nh ? MEM có ghi Reg, không ghi vào x0, và ??a ch? trùng v?i RS1
        if (mem_reg_wren && (mem_rd_addr != 5'b0) && (mem_rd_addr == ex_rs1_addr)) begin
            forward_a = 2'b10;
        end
        // ?u tiên 2: Forward t? WB (D? li?u c? h?n 1 chút, nh?ng v?n m?i h?n RegFile)
        // ?i?u ki?n: L?nh ? WB có ghi Reg, không ghi x0, trùng ??a ch? RS1, 
        // VÀ (QUAN TR?NG) không x?y ra xung ??t v?i MEM (vì MEM m?i h?n)
        else if (wb_reg_wren && (wb_rd_addr != 5'b0) && (wb_rd_addr == ex_rs1_addr)) begin
            forward_a = 2'b01;
        end

        // ---------------------------------------------------------
        // 2. FORWARDING CHO OPERAND B (RS2)
        // ---------------------------------------------------------
        forward_b = 2'b00; // M?c ??nh

        // ?u tiên 1: Forward t? MEM
        if (mem_reg_wren && (mem_rd_addr != 5'b0) && (mem_rd_addr == ex_rs2_addr)) begin
            forward_b = 2'b10;
        end
        // ?u tiên 2: Forward t? WB
        else if (wb_reg_wren && (wb_rd_addr != 5'b0) && (wb_rd_addr == ex_rs2_addr)) begin
            forward_b = 2'b01;
        end
    end

endmodule
