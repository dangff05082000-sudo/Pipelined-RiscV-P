module ControlUnit(
    input  wire [6:0] i_opcode,
    input  wire [2:0] i_funct3,
    input  wire [6:0] i_funct7,

    output logic [3:0] o_alu_op,
    output logic       o_mem_wren,
    output logic       o_mem_rd_en,
    output logic [1:0] o_wb_sel,
    output logic       o_rd_wren,
    output logic       o_opa_sel,
    output logic       o_opb_sel,
    output logic       o_br_un,
    output logic [1:0] o_pc_sel,
    
    // --- TÍN HI?U M?I CHO TU?N 2 ---
    output logic       o_rs1_used, // Báo hi?u l?nh này có ??c RS1 không
    output logic       o_rs2_used  // Báo hi?u l?nh này có ??c RS2 không
);

    // ??nh ngh?a các h?ng s? (Gi? nguyên)
    localparam ALU_ADD    = 4'b0000;
    localparam ALU_SUB    = 4'b0001;
    localparam ALU_SLL    = 4'b0010;
    localparam ALU_SLT    = 4'b0011;
    localparam ALU_SLTU   = 4'b0100;
    localparam ALU_XOR    = 4'b0101;
    localparam ALU_SRL    = 4'b0110;
    localparam ALU_SRA    = 4'b0111;
    localparam ALU_OR     = 4'b1000;
    localparam ALU_AND    = 4'b1001;
    localparam ALU_COPY_B = 4'b1010;
    localparam ALU_XXX    = 4'b1111;

    localparam PC_NEXT    = 2'b00;
    localparam PC_BRC     = 2'b01;
    localparam PC_JALR    = 2'b10;
    localparam PC_JAL     = 2'b11;

    localparam WB_ALU     = 2'b00;
    localparam WB_MEM     = 2'b01;
    localparam WB_PC4     = 2'b10;

    always_comb begin
        // Gán m?c ??nh ?? tránh Latch
        o_alu_op    = ALU_ADD;
        o_mem_wren  = 1'b0;
        o_mem_rd_en = 1'b0;
        o_wb_sel    = WB_ALU;
        o_rd_wren   = 1'b0;
        o_opa_sel   = 1'b0;
        o_opb_sel   = 1'b0;
        o_br_un     = 1'b0;
        o_pc_sel    = PC_NEXT;
        
        // M?c ??nh không dùng thanh ghi ngu?n (cho an toàn)
        o_rs1_used  = 1'b0;
        o_rs2_used  = 1'b0;

        case (i_opcode)
            // R-TYPE (add, sub, xor...)
            7'h33: begin
                o_rd_wren  = 1'b1;
                o_rs1_used = 1'b1; // Dùng RS1
                o_rs2_used = 1'b1; // Dùng RS2
                
                case (i_funct3)
                    3'b000: o_alu_op = (i_funct7 == 7'h20) ? ALU_SUB : ALU_ADD;
                    3'b001: o_alu_op = ALU_SLL;
                    3'b010: o_alu_op = ALU_SLT;
                    3'b011: o_alu_op = ALU_SLTU;
                    3'b100: o_alu_op = ALU_XOR;
                    3'b101: o_alu_op = (i_funct7 == 7'h20) ? ALU_SRA : ALU_SRL;
                    3'b110: o_alu_op = ALU_OR;
                    3'b111: o_alu_op = ALU_AND;
                    default: o_alu_op = ALU_XXX;
                endcase
            end

            // I-TYPE (addi, ori...)
            7'h13: begin
                o_opb_sel  = 1'b1; // Ch?n Imm
                o_rd_wren  = 1'b1;
                o_rs1_used = 1'b1; // Dùng RS1
                o_rs2_used = 1'b0; // Không dùng RS2 (dùng Imm)

                case (i_funct3)
                    3'b000: o_alu_op = ALU_ADD;
                    3'b001: o_alu_op = ALU_SLL;
                    3'b010: o_alu_op = ALU_SLT;
                    3'b011: o_alu_op = ALU_SLTU;
                    3'b100: o_alu_op = ALU_XOR;
                    3'b101: o_alu_op = (i_funct7 == 7'h20) ? ALU_SRA : ALU_SRL;
                    3'b110: o_alu_op = ALU_OR;
                    3'b111: o_alu_op = ALU_AND;
                    default: o_alu_op = ALU_XXX;
                endcase
            end

            // LOAD (lw, lh...)
            7'h03: begin
                o_opb_sel   = 1'b1; // ALU tính Address = RS1 + Imm
                o_rd_wren   = 1'b1;
                o_mem_rd_en = 1'b1;
                o_wb_sel    = WB_MEM;
                o_rs1_used  = 1'b1; // Dùng RS1 ?? tính ??a ch?
                o_rs2_used  = 1'b0; // Không dùng RS2
            end

            // STORE (sw, sh...)
            7'h23: begin
                o_opb_sel   = 1'b1; // ALU tính Address = RS1 + Imm
                o_mem_wren  = 1'b1;
                o_rs1_used  = 1'b1; // Dùng RS1 tính ??a ch?
                o_rs2_used  = 1'b1; // Dùng RS2 ?? l?y d? li?u ghi vào Mem
            end

            // BRANCH (beq, bne...)
            7'h63: begin
                o_pc_sel   = PC_BRC;
                o_rs1_used = 1'b1; // So sánh RS1
                o_rs2_used = 1'b1; // So sánh RS2
                
                case (i_funct3)
                    3'b000: o_br_un = 1'b0; // BEQ
                    3'b001: o_br_un = 1'b0; // BNE
                    3'b100: o_br_un = 1'b0; // BLT
                    3'b101: o_br_un = 1'b0; // BGE
                    3'b110: o_br_un = 1'b1; // BLTU
                    3'b111: o_br_un = 1'b1; // BGEU
                    default: o_br_un = 1'b0;
                endcase
            end

            // JAL
            7'h6F: begin
                o_opb_sel  = 1'b1;
                o_rd_wren  = 1'b1;
                o_wb_sel   = WB_PC4;
                o_pc_sel   = PC_JAL;
                // Không dùng RS1, RS2
            end

            // JALR
            7'h67: begin
                o_opb_sel  = 1'b1;
                o_rd_wren  = 1'b1;
                o_wb_sel   = WB_PC4;
                o_pc_sel   = PC_JALR;
                o_rs1_used = 1'b1; // Dùng RS1 làm base address
                o_rs2_used = 1'b0;
            end

            // LUI
            7'h37: begin
                o_opb_sel  = 1'b1;
                o_alu_op   = ALU_COPY_B;
                o_rd_wren  = 1'b1;
                // Không dùng RS1, RS2
            end

            // AUIPC
            7'h17: begin
                o_opa_sel  = 1'b1; // PC
                o_opb_sel  = 1'b1; // Imm
                o_rd_wren  = 1'b1;
                // Không dùng RS1, RS2
            end

            default: begin
                o_alu_op = ALU_XXX;
            end
        endcase
    end

endmodule
