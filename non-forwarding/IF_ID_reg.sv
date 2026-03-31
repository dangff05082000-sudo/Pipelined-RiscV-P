module IF_ID_reg (
    input  logic        i_clk,
    input  logic        i_reset,
    input  logic        i_stall, // Gi? l?nh c?
    input  logic        i_flush, // Xóa l?nh (?u tiên cao h?n Stall)
    
    input  logic [31:0] i_pc,
    input  logic [31:0] i_instr, // Input này ??n t? Output c?a Synchronous IMEM

    output logic [31:0] o_pc,
    output logic [31:0] o_instr
);

    // -------------------------------------------------------------------------
    // 1. X? LÝ INSTRUCTION (Combinational Logic)
    // -------------------------------------------------------------------------
    // Vì IMEM ?ã là Synchronous (có FF bên trong), d? li?u i_instr ?ã ?n ??nh
    // sau c?nh clock. Ta không latch l?i ?? tránh tr? thành 2 chu k?.
    // Tuy nhiên, ta c?n x? lý FLUSH: N?u Flush, ép l?nh thành NOP.
    // N?u Stall, i_instr t? IMEM s? t? gi? nguyên (do PC c?p cho IMEM không ??i).
    
    // NOP instruction for RISC-V is: addi x0, x0, 0 (0x00000013)
    assign o_instr = i_flush ? 32'h00000013 : i_instr;


    // -------------------------------------------------------------------------
    // 2. X? LÝ PC (Sequential Logic)
    // -------------------------------------------------------------------------
    // PC c?n ?i qua Flip-Flop ?? tr? l?i 1 nh?p, ??ng b? v?i ?? tr? c?a IMEM.
    
    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            o_pc <= 32'b0;
        end 
        else if (i_stall) begin
            // Khi Stall: Gi? nguyên giá tr? PC hi?n t?i ?? kh?p v?i l?nh ?ang b? Stall
            o_pc <= o_pc;
        end 
        else begin
            // Khi ho?t ??ng bình th??ng (ho?c Flush), PC trôi theo dòng ch?y pipeline
            // ?? kh?p v?i l?nh m?i s?p vào ID stage.
            o_pc <= i_pc;
        end
    end

endmodule
