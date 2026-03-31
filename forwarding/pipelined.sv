module pipelined (
    input  logic        i_clk,
    input  logic        i_reset,
    input  logic [31:0] i_io_sw,

    output logic [31:0] o_pc_debug,
    output logic        o_insn_vld,
    output logic [31:0] o_io_ledr,
    output logic [31:0] o_io_ledg,
    output logic [6:0]  o_io_hex0,
    output logic [6:0]  o_io_hex1,
    output logic [6:0]  o_io_hex2,
    output logic [6:0]  o_io_hex3,
    output logic [6:0]  o_io_hex4,
    output logic [6:0]  o_io_hex5,
    output logic [6:0]  o_io_hex6,
    output logic [6:0]  o_io_hex7,
    output logic [31:0] o_io_lcd,
    
    output logic        o_ctrl,
    output logic        o_mispred
);

    // ========================================================================
    // 1. SIGNAL DECLARATION
    // ========================================================================

    // --- Hazard & Forwarding Signals ---
    logic hazard_stall;
    logic hazard_flush_if_id;
    logic hazard_flush_id_ex;
    logic branch_taken;
    
    // Tín hi?u Forwarding
    logic [1:0] forward_a; // 00: ID/EX, 10: EX/MEM, 01: MEM/WB
    logic [1:0] forward_b;
    logic [31:0] forwarded_rs1_data; // D? li?u RS1 sau khi qua Mux Forwarding
    logic [31:0] forwarded_rs2_data; // D? li?u RS2 sau khi qua Mux Forwarding

    // --- IF Stage ---
    logic [31:0] if_pc, if_pc_next, if_pc_four, if_instr;
    logic [31:0] if_pc_input; 

    // --- IF/ID Outputs ---
    logic [31:0] id_pc, id_instr;

    // --- ID Stage ---
    logic [4:0]  id_rs1_addr, id_rs2_addr, id_rd_addr;
    logic [31:0] id_rs1_data, id_rs2_data, id_imm;
    logic [2:0]  id_funct3;
    logic [6:0]  id_funct7, id_opcode;
    
    // ID Control Signals
    logic [3:0]  id_alu_op;
    logic        id_mem_wren, id_mem_rden, id_reg_wren;
    logic [1:0]  id_wb_sel;
    logic        id_opa_sel, id_opb_sel, id_br_un;
    logic [1:0]  id_pc_sel;
    logic        id_rs1_used, id_rs2_used;

    // --- ID/EX Outputs ---
    logic [31:0] ex_pc, ex_rs1_data, ex_rs2_data, ex_imm;
    logic [4:0]  ex_rd_addr, ex_rs1_addr, ex_rs2_addr;
    logic [2:0]  ex_funct3;
    logic        ex_mem_wren, ex_mem_rden, ex_reg_wren;
    logic [1:0]  ex_wb_sel, ex_pc_sel;
    logic [3:0]  ex_alu_op;
    logic        ex_opa_sel, ex_opb_sel, ex_br_un;

    // --- EX Stage ---
    logic [31:0] ex_op_a, ex_op_b, ex_alu_result;
    logic        ex_br_less, ex_br_equal;
    logic [31:0] ex_pc_branch_target; 
    logic [31:0] final_branch_target;

    // --- EX/MEM Outputs ---
    logic [31:0] mem_alu_result, mem_rs2_data, mem_pc_four;
    logic [4:0]  mem_rd_addr;
    logic [2:0]  mem_funct3;
    logic        mem_mem_wren, mem_mem_rden, mem_reg_wren;
    logic [1:0]  mem_wb_sel;

    // --- MEM Stage ---
    logic [31:0] mem_dmem_rdata;
    logic [31:0] mem_ld_data;
    logic [3:0]  mem_byte_mask;
    logic [31:0] mem_wdata_shifted;
    logic        dmem_wren_valid;

    // --- MEM/WB Outputs ---
    logic [31:0] wb_alu_result, wb_ld_data, wb_pc_four;
    logic [4:0]  wb_rd_addr;
    logic        wb_reg_wren;
    logic [1:0]  wb_wb_sel;

    // --- WB Stage ---
    logic [31:0] wb_data;

    // ========================================================================
    // 2. HAZARD & FORWARDING UNIT INSTANTIATION
    // ========================================================================
    
    // --- Hazard Detection (Load-Use only for Model 2) ---
    HazardDetectionUnit u_hazard_unit (
        .id_rs1_addr(id_rs1_addr),
        .id_rs2_addr(id_rs2_addr),
        .id_rs1_used(id_rs1_used),
        .id_rs2_used(id_rs2_used),
        
        .ex_rd_addr(ex_rd_addr),
        // QUAN TR?NG: Model 2 ch? stall khi l?nh tr??c là LOAD
        .ex_mem_rden(ex_mem_rden), 
        
        .mem_rd_addr(mem_rd_addr), 
        .mem_reg_wren(mem_reg_wren), 

        .i_branch_taken(branch_taken),
        
        .o_stall(hazard_stall),
        .o_flush_if_id(hazard_flush_if_id),
        .o_flush_id_ex(hazard_flush_id_ex)
    );

    // --- Forwarding Unit ---
    ForwardingUnit u_forwarding_unit (
        .ex_rs1_addr(ex_rs1_addr),
        .ex_rs2_addr(ex_rs2_addr),
        
        .mem_rd_addr(mem_rd_addr),
        .mem_reg_wren(mem_reg_wren),
        
        .wb_rd_addr(wb_rd_addr),
        .wb_reg_wren(wb_reg_wren),
        
        .forward_a(forward_a),
        .forward_b(forward_b)
    );

    // ========================================================================
    // 3. STAGE IMPLEMENTATION
    // ========================================================================

    // ------------------------------------------------------------------------
    // STAGE 1: INSTRUCTION FETCH (IF)
    // ------------------------------------------------------------------------
    
    // Logic ch?n PC Next (Priority: Stall > Branch > Normal)
    always_comb begin
        if (hazard_stall) begin
            if_pc_input = if_pc; // Stall: Gi? nguyên PC
        end else if (branch_taken) begin
            if_pc_input = final_branch_target; // Branch Taken
        end else begin
            if_pc_input = if_pc_four; // Normal: PC + 4
        end
    end

    pc u_pc (
        .clk(i_clk), .rst_n(!i_reset), .pc_next(if_pc_input), .pc(if_pc)
    );

    pcadder u_pcadder (
        .pc(if_pc), .pc_four(if_pc_four)
    );

    imem u_imem (
        .i_clk(i_clk), .i_addr(if_pc), .o_instr(if_instr)
    );

    // Register IF/ID
    IF_ID_reg u_IF_ID_reg (
        .i_clk(i_clk), .i_reset(!i_reset), 
        .i_stall(hazard_stall),
        .i_flush(hazard_flush_if_id),
        .i_pc(if_pc), .i_instr(if_instr),
        .o_pc(id_pc), .o_instr(id_instr)
    );

    // ------------------------------------------------------------------------
    // STAGE 2: INSTRUCTION DECODE (ID)
    // ------------------------------------------------------------------------

    instrdecoder u_decoder (
        .instr(id_instr), 
        .i_rs1_addr(id_rs1_addr), .i_rs2_addr(id_rs2_addr), .i_rd_addr(id_rd_addr),
        .funct3(id_funct3), .funct7(id_funct7), .opcode(id_opcode)
    );

    ControlUnit u_control (
        .i_opcode(id_opcode), .i_funct3(id_funct3), .i_funct7(id_funct7),
        .o_alu_op(id_alu_op), .o_mem_wren(id_mem_wren), .o_mem_rd_en(id_mem_rden),
        .o_wb_sel(id_wb_sel), .o_rd_wren(id_reg_wren),
        .o_opa_sel(id_opa_sel), .o_opb_sel(id_opb_sel),
        .o_br_un(id_br_un), .o_pc_sel(id_pc_sel),
        .o_rs1_used(id_rs1_used), .o_rs2_used(id_rs2_used)
    );

    // L?u ý: Regfile c?n h? tr? Internal Forwarding (nh? ?ã s?a ? b??c tr??c)
    regfile u_regfile (
        .i_clk(i_clk), .i_reset(!i_reset), 
        .i_rd_wren(wb_reg_wren), .i_rd_addr(wb_rd_addr), .i_rd_data(wb_data),
        .i_rs1_addr(id_rs1_addr), .i_rs2_addr(id_rs2_addr),
        .o_rs1_data(id_rs1_data), .o_rs2_data(id_rs2_data)
    );

    immgen u_immgen (
        .instr(id_instr), .imm(id_imm)
    );

    // Register ID/EX
    ID_EX_reg u_ID_EX_reg (
        .i_clk(i_clk), .i_reset(!i_reset), 
        .i_stall(1'b0),               
        .i_flush(hazard_flush_id_ex), 
        
        .i_mem_wren(id_mem_wren), .i_mem_rden(id_mem_rden), .i_reg_wren(id_reg_wren),
        .i_wb_sel(id_wb_sel), .i_alu_op(id_alu_op), 
        .i_op_a_sel(id_opa_sel), .i_op_b_sel(id_opb_sel), .i_br_un(id_br_un), .i_funct3(id_funct3),
        .i_pc_sel(id_pc_sel), 
        
        .i_pc(id_pc), .i_rs1_data(id_rs1_data), .i_rs2_data(id_rs2_data), 
        .i_imm(id_imm), .i_rd_addr(id_rd_addr), .i_rs1_addr(id_rs1_addr), .i_rs2_addr(id_rs2_addr),
        
        .o_mem_wren(ex_mem_wren), .o_mem_rden(ex_mem_rden), .o_reg_wren(ex_reg_wren),
        .o_wb_sel(ex_wb_sel), .o_alu_op(ex_alu_op),
        .o_op_a_sel(ex_opa_sel), .o_op_b_sel(ex_opb_sel), .o_br_un(ex_br_un), .o_funct3(ex_funct3),
        .o_pc_sel(ex_pc_sel),
        .o_pc(ex_pc), .o_rs1_data(ex_rs1_data), .o_rs2_data(ex_rs2_data), 
        .o_imm(ex_imm), .o_rd_addr(ex_rd_addr), .o_rs1_addr(ex_rs1_addr), .o_rs2_addr(ex_rs2_addr)
    );

    // ------------------------------------------------------------------------
    // STAGE 3: EXECUTE (EX)
    // ------------------------------------------------------------------------

    // --- MUX FORWARDING LOGIC (?ây là ph?n quan tr?ng nh?t c?a Model 2) ---
    // Ch?n d? li?u cho RS1
    always_comb begin
        case (forward_a)
            2'b00: forwarded_rs1_data = ex_rs1_data;    // No forward (from ID/EX)
            2'b10: forwarded_rs1_data = mem_alu_result; // Forward from MEM (Priority 1)
            2'b01: forwarded_rs1_data = wb_data;        // Forward from WB (Priority 2)
            default: forwarded_rs1_data = ex_rs1_data;
        endcase
    end

    // Ch?n d? li?u cho RS2
    always_comb begin
        case (forward_b)
            2'b00: forwarded_rs2_data = ex_rs2_data;    // No forward (from ID/EX)
            2'b10: forwarded_rs2_data = mem_alu_result; // Forward from MEM (Priority 1)
            2'b01: forwarded_rs2_data = wb_data;        // Forward from WB (Priority 2)
            default: forwarded_rs2_data = ex_rs2_data;
        endcase
    end

    // --- S? d?ng d? li?u ?ã Forward cho các kh?i tính toán ---

    // 1. Operand Mux (ALU Input)
    operandamux u_op_a_mux (
        .pc(ex_pc), 
        .o_rs1_data(forwarded_rs1_data), // S? d?ng d? li?u forward
        .opa_sel(ex_opa_sel), 
        .i_op_a(ex_op_a)
    );

    operandbmux u_op_b_mux (
        .o_immgen(ex_imm), 
        .o_rs2_data(forwarded_rs2_data), // S? d?ng d? li?u forward
        .opb_sel(ex_opb_sel), 
        .i_op_b(ex_op_b)
    );

    // 2. ALU
    alu u_alu (
        .i_op_a(ex_op_a), .i_op_b(ex_op_b), .i_alu_op(ex_alu_op), .o_alu_data(ex_alu_result)
    );

    // 3. Branch Comparator (Ph?i dùng d? li?u m?i nh?t ?? so sánh)
    brc u_brc (
        .i_rs1_data(forwarded_rs1_data), // S? d?ng d? li?u forward
        .i_rs2_data(forwarded_rs2_data), // S? d?ng d? li?u forward
        .i_br_un(ex_br_un),
        .o_br_less(ex_br_less), .o_br_equal(ex_br_equal)
    );

    // --- BRANCH LOGIC ---
    assign ex_pc_branch_target = ex_pc + ex_imm;
    
    // JALR: Dùng RS1 + Imm (RS1 c?ng ph?i là forwarded data!)
    // Trong u_op_a_mux phía trên ?ã x? lý vi?c ch?n RS1 ho?c PC r?i, 
    // nh?ng JALR tính target riêng.
    // N?u thi?t k? ALU h? tr? ADD cho JALR thì l?y ex_alu_result là chu?n nh?t.
    assign final_branch_target = (ex_pc_sel == 2'b10) ? ex_alu_result : ex_pc_branch_target;

    always_comb begin
        branch_taken = 1'b0;
        if (ex_pc_sel == 2'b01) begin // Branch instructions
            case (ex_funct3)
                3'b000: branch_taken = ex_br_equal;      // BEQ
                3'b001: branch_taken = !ex_br_equal;     // BNE
                3'b100: branch_taken = ex_br_less;       // BLT
                3'b101: branch_taken = !ex_br_less;      // BGE
                3'b110: branch_taken = ex_br_less;       // BLTU
                3'b111: branch_taken = !ex_br_less;      // BGEU
                default: branch_taken = 1'b0;
            endcase
        end 
        else if (ex_pc_sel == 2'b10 || ex_pc_sel == 2'b11) begin // JAL, JALR
            branch_taken = 1'b1;
        end
    end

    // Register EX/MEM
    EX_MEM_reg u_EX_MEM_reg (
        .i_clk(i_clk), .i_reset(!i_reset), .i_flush(hazard_flush_id_ex),
        .i_mem_wren(ex_mem_wren), .i_mem_rden(ex_mem_rden), .i_reg_wren(ex_reg_wren),
        .i_wb_sel(ex_wb_sel), .i_funct3(ex_funct3),
        .i_alu_result(ex_alu_result), 
        .i_rs2_data(forwarded_rs2_data), // QUAN TR?NG: Store data ph?i là d? li?u m?i nh?t
        .i_pc_four(ex_pc + 4), .i_rd_addr(ex_rd_addr),
        .o_mem_wren(mem_mem_wren), .o_mem_rden(mem_mem_rden), .o_reg_wren(mem_reg_wren),
        .o_wb_sel(mem_wb_sel), .o_funct3(mem_funct3),
        .o_alu_result(mem_alu_result), .o_rs2_data(mem_rs2_data),
        .o_pc_four(mem_pc_four), .o_rd_addr(mem_rd_addr)
    );

    // ------------------------------------------------------------------------
    // STAGE 4: MEMORY (MEM)
    // ------------------------------------------------------------------------

    always_comb begin
        mem_byte_mask = 4'b0000;
        mem_wdata_shifted = mem_rs2_data;
        if (mem_mem_wren) begin
            case (mem_funct3)
                3'b000: begin // SB
                    case (mem_alu_result[1:0])
                        2'b00: begin mem_byte_mask = 4'b0001; mem_wdata_shifted = {24'b0, mem_rs2_data[7:0]}; end
                        2'b01: begin mem_byte_mask = 4'b0010; mem_wdata_shifted = {16'b0, mem_rs2_data[7:0], 8'b0}; end
                        2'b10: begin mem_byte_mask = 4'b0100; mem_wdata_shifted = {8'b0, mem_rs2_data[7:0], 16'b0}; end
                        2'b11: begin mem_byte_mask = 4'b1000; mem_wdata_shifted = {mem_rs2_data[7:0], 24'b0}; end
                    endcase
                end
                3'b001: begin // SH
                    if (mem_alu_result[1] == 1'b0) begin 
                        mem_byte_mask = 4'b0011; mem_wdata_shifted = {16'b0, mem_rs2_data[15:0]};
                    end else begin 
                        mem_byte_mask = 4'b1100; mem_wdata_shifted = {mem_rs2_data[15:0], 16'b0};
                    end
                end
                3'b010: begin // SW
                    mem_byte_mask = 4'b1111; mem_wdata_shifted = mem_rs2_data;
                end
            endcase
        end
    end

    assign dmem_wren_valid = mem_mem_wren && (mem_alu_result[31:16] == 16'h0000);

    dmem u_dmem (
        .i_clk(i_clk), .i_wren(dmem_wren_valid),
        .i_addr(mem_alu_result), .i_wdata(mem_wdata_shifted),
        .i_mask(mem_byte_mask), .o_rdata(mem_dmem_rdata)
    );

    // IO Mapped Output (LEDs, Hex)
    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            o_io_ledr <= 32'b0;
            o_io_ledg <= 32'b0;
            o_io_hex0 <= 7'b0; o_io_hex1 <= 7'b0; o_io_hex2 <= 7'b0; o_io_hex3 <= 7'b0;
            o_io_hex4 <= 7'b0; o_io_hex5 <= 7'b0; o_io_hex6 <= 7'b0; o_io_hex7 <= 7'b0;
            o_io_lcd <= 32'b0;
        end else if (mem_mem_wren) begin
            case (mem_alu_result)
                32'h1000_0000: o_io_ledr <= mem_rs2_data;
                32'h1000_1000: o_io_ledg <= mem_rs2_data;
                32'h1000_2000: o_io_hex0 <= mem_rs2_data[6:0]; 
                // Add more specific mappings for HEX1-7, LCD here
            endcase
        end
    end

    logic [31:0] raw_read_data;
    // IO Mapped Input (Switches)
    always_comb begin
        if (mem_alu_result == 32'h1001_0000) raw_read_data = i_io_sw;
        else raw_read_data = mem_dmem_rdata;
    end

    // Load Data Alignment (LB, LH, LW...)
    logic [7:0] aligned_byte;
    logic [15:0] aligned_half;
    always_comb begin
        case (mem_alu_result[1:0])
            2'b00: aligned_byte = raw_read_data[7:0];
            2'b01: aligned_byte = raw_read_data[15:8];
            2'b10: aligned_byte = raw_read_data[23:16];
            2'b11: aligned_byte = raw_read_data[31:24];
        endcase
        aligned_half = (mem_alu_result[1] == 1'b0) ? raw_read_data[15:0] : raw_read_data[31:16];

        case (mem_funct3)
            3'b000: mem_ld_data = {{24{aligned_byte[7]}}, aligned_byte}; // LB
            3'b001: mem_ld_data = {{16{aligned_half[15]}}, aligned_half}; // LH
            3'b010: mem_ld_data = raw_read_data;                           // LW
            3'b100: mem_ld_data = {24'b0, aligned_byte};                   // LBU
            3'b101: mem_ld_data = {16'b0, aligned_half};                   // LHU
            default: mem_ld_data = 32'b0;
        endcase
    end

    // Register MEM/WB
    MEM_WB_reg u_MEM_WB_reg (
        .i_clk(i_clk), .i_reset(!i_reset),
        .i_reg_wren(mem_reg_wren), .i_wb_sel(mem_wb_sel),
        .i_alu_result(mem_alu_result), .i_ld_data(mem_ld_data),
        .i_pc_four(mem_pc_four), .i_rd_addr(mem_rd_addr),
        .o_reg_wren(wb_reg_wren), .o_wb_sel(wb_wb_sel),
        .o_alu_result(wb_alu_result), .o_ld_data(wb_ld_data),
        .o_pc_four(wb_pc_four), .o_rd_addr(wb_rd_addr)
    );

    // ------------------------------------------------------------------------
    // STAGE 5: WRITE BACK (WB)
    // ------------------------------------------------------------------------

    writedatamux u_wb_mux (
        .pc_four(wb_pc_four), .o_alu_data(wb_alu_result), .o_ld_data(wb_ld_data),
        .wb_sel(wb_wb_sel), .wb_data(wb_data)
    );

    // ========================================================================
    // 4. OUTPUTS
    // ========================================================================
    assign o_pc_debug = if_pc; // PC ? WB stage có th? t?t h?n cho debug, nh?ng PC ? IF là chu?n hi?n t?i
    assign o_insn_vld = (if_instr != 32'b0); // Ch? là demo, logic vld th?c s? c?n ph?c t?p h?n
    assign o_ctrl     = (ex_pc_sel != 2'b00); // Báo hi?u có l?nh Control ? EX
    assign o_mispred  = 1'b0; // Static prediction (Always Not Taken), n?u Taken thì là Mispred

endmodule
