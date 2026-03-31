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

    // --- Hazard & Control Signals ---
    logic hazard_stall;
    logic hazard_flush_if_id;
    logic hazard_flush_id_ex;
    logic branch_taken;

    // --- IF Stage ---
    logic [31:0] if_pc, if_pc_next, if_pc_four;
    logic [31:0] if_instr_raw; // Raw output t? imem
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
    logic [3:0]  mem_byte_mask;
    logic [31:0] mem_wdata_shifted;
    logic        dmem_wren_valid;

    // --- MEM/WB Outputs ---
    logic [31:0] wb_alu_result, wb_ld_data, wb_pc_four;
    logic [4:0]  wb_rd_addr;
    logic        wb_reg_wren;
    logic [1:0]  wb_wb_sel;
    logic [31:0] wb_dmem_raw_data; // D? li?u thô t? Dmem (xu?t hi?n ? WB)
    logic [2:0]  wb_funct3;        // Funct3 chuy?n xu?ng WB ?? x? lý Load

    // --- WB Stage ---
    logic [31:0] wb_data;

    // ========================================================================
    // 2. HAZARD DETECTION UNIT INSTANTIATION
    // ========================================================================
    HazardDetectionUnit u_hazard_unit (
        .id_rs1_addr    (id_rs1_addr),
        .id_rs2_addr    (id_rs2_addr),
        .id_rs1_used    (id_rs1_used),
        .id_rs2_used    (id_rs2_used),
        
        .ex_rd_addr     (ex_rd_addr),
        .ex_reg_wren    (ex_reg_wren), 
        
        .mem_rd_addr    (mem_rd_addr), 
        .mem_reg_wren   (mem_reg_wren), 

        // L?u ý: ?ã b? input WB Hazard theo nh? s?a ??i ? HazardDetectionUnit.sv
        // .wb_rd_addr     (wb_rd_addr),
        // .wb_reg_wren    (wb_reg_wren),

        .i_branch_taken (branch_taken),
        
        .o_stall        (hazard_stall),
        .o_flush_if_id  (hazard_flush_if_id),
        .o_flush_id_ex  (hazard_flush_id_ex)
    );

    // ========================================================================
    // 3. STAGE IMPLEMENTATION
    // ========================================================================

    // ------------------------------------------------------------------------
    // STAGE 1: INSTRUCTION FETCH (IF)
    // ------------------------------------------------------------------------
    
    always_comb begin
        if (branch_taken) begin
             if_pc_input = final_branch_target;
        end 
        else if (hazard_stall) begin
            if_pc_input = if_pc;
        end 
        else begin
            if_pc_input = if_pc_four;
        end
    end

    pc u_pc (
        .i_clk(i_clk), .i_reset(i_reset), 
        .i_stall(hazard_stall),
        .i_pc_next(if_pc_input), 
        .o_pc(if_pc)
    );

    pcadder u_pcadder (
        .pc(if_pc), .pc_four(if_pc_four)
    );

    // IMEM (Synchronous Read)
    // Output if_instr_raw s? có giá tr? ? chu k? ti?p theo (T?c là chu k? ID)
    imem u_imem (
        .i_clk(i_clk), .i_addr(if_pc), .o_instr(if_instr_raw)
    );

    // X? lý FLUSH cho Synchronous Memory ngay tr??c khi vào Decoder
    // N?u Flush, ép l?nh thành NOP (addi x0, x0, 0 = 0x00000013)
    assign id_instr = hazard_flush_if_id ? 32'h00000013 : if_instr_raw;

    // Register IF/ID
    // CHÚ Ý: Ch? l?u PC, KHÔNG l?u Instruction (vì Instr ?ã tr? 1 nh?p t? Imem)
    IF_ID_reg u_IF_ID_reg (
        .i_clk(i_clk), .i_reset(i_reset), 
        .i_stall(hazard_stall),
        .i_flush(hazard_flush_if_id),
        .i_pc(if_pc), 
        .i_instr(32'b0), // Dummy input (không dùng vì ?ã bypass ? trên)
        .o_pc(id_pc), 
        .o_instr()       // Dummy output (không dùng)
    );

    // ------------------------------------------------------------------------
    // STAGE 2: INSTRUCTION DECODE (ID)
    // ------------------------------------------------------------------------

    instrdecoder u_decoder (
        .instr(id_instr), // L?y tr?c ti?p t? logic bypass Imem
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

    regfile u_regfile (
        .i_clk(i_clk), .i_reset(i_reset), 
        .i_rd_wren(wb_reg_wren), .i_rd_addr(wb_rd_addr), .i_rd_data(wb_data),
        .i_rs1_addr(id_rs1_addr), .i_rs2_addr(id_rs2_addr),
        .o_rs1_data(id_rs1_data), .o_rs2_data(id_rs2_data)
    );

    immgen u_immgen (
        .instr(id_instr), .imm(id_imm)
    );

    // Register ID/EX
    ID_EX_reg u_ID_EX_reg (
        .i_clk(i_clk), .i_reset(i_reset), 
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

    operandamux u_op_a_mux (
        .pc(ex_pc), .o_rs1_data(ex_rs1_data), .opa_sel(ex_opa_sel), .i_op_a(ex_op_a)
    );

    operandbmux u_op_b_mux (
        .o_immgen(ex_imm), .o_rs2_data(ex_rs2_data), .opb_sel(ex_opb_sel), .i_op_b(ex_op_b)
    );

    alu u_alu (
        .i_op_a(ex_op_a), .i_op_b(ex_op_b), .i_alu_op(ex_alu_op), .o_alu_data(ex_alu_result)
    );

    brc u_brc (
        .i_rs1_data(ex_rs1_data), .i_rs2_data(ex_rs2_data), .i_br_un(ex_br_un),
        .o_br_less(ex_br_less), .o_br_equal(ex_br_equal)
    );

    // --- BRANCH LOGIC ---
    assign ex_pc_branch_target = ex_pc + ex_imm;
    assign final_branch_target = (ex_pc_sel == 2'b10) ? {ex_alu_result[31:1], 1'b0} : ex_pc_branch_target;

    always_comb begin
        branch_taken = 1'b0;
        if (ex_pc_sel == 2'b01) begin // Branch
            case (ex_funct3)
                3'b000: branch_taken = ex_br_equal;       // BEQ
                3'b001: branch_taken = !ex_br_equal;      // BNE
                3'b100: branch_taken = ex_br_less;        // BLT
                3'b101: branch_taken = !ex_br_less;       // BGE
                3'b110: branch_taken = ex_br_less;        // BLTU
                3'b111: branch_taken = !ex_br_less;       // BGEU
                default: branch_taken = 1'b0;
            endcase
        end 
        else if (ex_pc_sel == 2'b10 || ex_pc_sel == 2'b11) begin // JAL, JALR
            branch_taken = 1'b1;
        end
    end

    // Register EX/MEM
    EX_MEM_reg u_EX_MEM_reg (
        .i_clk(i_clk), .i_reset(i_reset), .i_flush(hazard_flush_id_ex),
        .i_mem_wren(ex_mem_wren), .i_mem_rden(ex_mem_rden), .i_reg_wren(ex_reg_wren),
        .i_wb_sel(ex_wb_sel), .i_funct3(ex_funct3),
        .i_alu_result(ex_alu_result), .i_rs2_data(ex_rs2_data), 
        .i_pc_four(ex_pc + 4), .i_rd_addr(ex_rd_addr),
        .o_mem_wren(mem_mem_wren), .o_mem_rden(mem_mem_rden), .o_reg_wren(mem_reg_wren),
        .o_wb_sel(mem_wb_sel), .o_funct3(mem_funct3),
        .o_alu_result(mem_alu_result), .o_rs2_data(mem_rs2_data),
        .o_pc_four(mem_pc_four), .o_rd_addr(mem_rd_addr)
    );

    // ------------------------------------------------------------------------
    // STAGE 4: MEMORY (MEM)
    // ------------------------------------------------------------------------

    // Logic Write Mask (Store) v?n n?m ? MEM vì Write là Synchronous
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
                    mem_byte_mask = 4'b1111;
                    mem_wdata_shifted = mem_rs2_data;
                end
            endcase
        end
    end

    assign dmem_wren_valid = mem_mem_wren && (mem_alu_result[31:16] == 16'h0000);

    // DMEM (Synchronous Read & Write)
    // Output wb_dmem_raw_data s? có giá tr? ? chu k? ti?p theo (T?c là chu k? WB)
    dmem u_dmem (
        .i_clk(i_clk), .i_wren(dmem_wren_valid),
        .i_addr(mem_alu_result), .i_wdata(mem_wdata_shifted),
        .i_mask(mem_byte_mask), 
        .o_rdata(wb_dmem_raw_data) // Output này thu?c v? t?ng WB
    );

    // Peripherals (IO) - Write logic
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
                // Các hex khác t??ng t? tùy mapping...
            endcase
        end
    end

    // Register MEM/WB
    // ?ã thêm funct3 ?? x? lý Load data t?i WB
    MEM_WB_reg u_MEM_WB_reg (
        .i_clk(i_clk), .i_reset(i_reset),
        .i_reg_wren(mem_reg_wren), .i_wb_sel(mem_wb_sel),
        .i_alu_result(mem_alu_result), 
        .i_ld_data(32'b0), // Dummy input
        .i_pc_four(mem_pc_four), .i_rd_addr(mem_rd_addr),
        
        .i_funct3(mem_funct3), 
        .o_funct3(wb_funct3),
        
        .o_reg_wren(wb_reg_wren), .o_wb_sel(wb_wb_sel),
        .o_alu_result(wb_alu_result), 
        .o_ld_data(),      // Dummy output
        .o_pc_four(wb_pc_four), .o_rd_addr(wb_rd_addr)
    );

    // ------------------------------------------------------------------------
    // STAGE 5: WRITE BACK (WB)
    // ------------------------------------------------------------------------

    // --- LOGIC X? LÝ LOAD DATA (Di chuy?n t? MEM xu?ng WB) ---
    logic [31:0] raw_read_data_wb;

    // Mux ch?n gi?a IO Switch và DMEM (d?a trên ??a ch? ?ã latch ? WB)
    always_comb begin
        if (wb_alu_result == 32'h1001_0000) raw_read_data_wb = i_io_sw;
        else raw_read_data_wb = wb_dmem_raw_data;
    end

    // Logic c?n ch?nh Byte/Half/Word (d?a trên wb_funct3)
    logic [7:0] aligned_byte;
    logic [15:0] aligned_half;
    
    always_comb begin
        case (wb_alu_result[1:0])
            2'b00: aligned_byte = raw_read_data_wb[7:0];
            2'b01: aligned_byte = raw_read_data_wb[15:8];
            2'b10: aligned_byte = raw_read_data_wb[23:16];
            2'b11: aligned_byte = raw_read_data_wb[31:24];
        endcase
        
        aligned_half = (wb_alu_result[1] == 1'b0) ? raw_read_data_wb[15:0] : raw_read_data_wb[31:16];

        case (wb_funct3)
            3'b000: wb_ld_data = {{24{aligned_byte[7]}}, aligned_byte}; // LB
            3'b001: wb_ld_data = {{16{aligned_half[15]}}, aligned_half}; // LH
            3'b010: wb_ld_data = raw_read_data_wb;                        // LW
            3'b100: wb_ld_data = {24'b0, aligned_byte};                   // LBU
            3'b101: wb_ld_data = {16'b0, aligned_half};                   // LHU
            default: wb_ld_data = 32'b0;
        endcase
    end

    // Cu?i cùng: Mux ch?n d? li?u ghi vào Regfile
    writedatamux u_wb_mux (
        .pc_four(wb_pc_four), .o_alu_data(wb_alu_result), .o_ld_data(wb_ld_data),
        .wb_sel(wb_wb_sel), .wb_data(wb_data)
    );

    // ========================================================================
    // 4. OUTPUTS
    // ========================================================================
    assign o_pc_debug = if_pc;
    
    // [?Ã S?A]: Lo?i b? l?nh NOP (0x00000013) kh?i tín hi?u valid ?? tính IPC chính xác
    assign o_insn_vld = (id_instr != 32'b0) && (id_instr != 32'h00000013);
    
    assign o_ctrl = branch_taken;
    assign o_mispred = 1'b0; // Model này ch?a có Branch Prediction nên mispred = 0

endmodule
