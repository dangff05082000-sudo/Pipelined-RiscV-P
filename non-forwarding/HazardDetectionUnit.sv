module HazardDetectionUnit (
    // --- Inputs t? t?ng ID (L?nh hi?n t?i ?ang gi?i mã) ---
    input  logic [4:0] id_rs1_addr,
    input  logic [4:0] id_rs2_addr,
    input  logic       id_rs1_used, // = 1 n?u l?nh có dùng Rs1
    input  logic       id_rs2_used, // = 1 n?u l?nh có dùng Rs2

    // --- Inputs t? t?ng EX (L?nh tr??c ?ó 1 nh?p) ---
    input  logic [4:0] ex_rd_addr,
    input  logic       ex_reg_wren, 

    // --- Inputs t? t?ng MEM (L?nh tr??c ?ó 2 nh?p) ---
    input  logic [4:0] mem_rd_addr,
    input  logic       mem_reg_wren,

    // --- Inputs t? t?ng WB (L?nh tr??c ?ó 3 nh?p) ---
    // [?Ã S?A]: Lo?i b? ki?m tra WB ?? tránh Deadlock.
    // Register File chu?n s? t? x? lý vi?c Ghi/??c cùng chu k?.
    // input  logic [4:0] wb_rd_addr,  <-- Không c?n dùng
    // input  logic       wb_reg_wren, <-- Không c?n dùng

    // --- Input báo r? nhánh (Control Hazard) ---
    input  logic       i_branch_taken,

    // --- Outputs ?i?u khi?n Pipeline ---
    output logic       o_stall,        // 1 = Gi? nguyên PC và IF/ID
    output logic       o_flush_if_id,  // 1 = Xóa l?nh ? IF/ID
    output logic       o_flush_id_ex   // 1 = Xóa l?nh ? ID/EX
);

    logic raw_hazard_ex;
    logic raw_hazard_mem;
    logic data_hazard;

    always_comb begin
        // --------------------------------------------------------
        // 1. PHÁT HI?N DATA HAZARD (RAW - Read After Write)
        // --------------------------------------------------------
        
        // Hazard t?i EX: L?nh ngay tr??c ?ó (?ang ? EX) s?p ghi vào thanh ghi ta c?n
        if (ex_reg_wren && (ex_rd_addr != 0) &&
           ((id_rs1_used && id_rs1_addr == ex_rd_addr) || 
            (id_rs2_used && id_rs2_addr == ex_rd_addr))) begin
            raw_hazard_ex = 1'b1;
        end else begin
            raw_hazard_ex = 1'b0;
        end

        // Hazard t?i MEM: L?nh tr??c ?ó n?a (?ang ? MEM) s?p ghi vào thanh ghi ta c?n
        if (mem_reg_wren && (mem_rd_addr != 0) &&
           ((id_rs1_used && id_rs1_addr == mem_rd_addr) || 
            (id_rs2_used && id_rs2_addr == mem_rd_addr))) begin
            raw_hazard_mem = 1'b1;
        end else begin
            raw_hazard_mem = 1'b0;
        end

        // [QUAN TR?NG]: Không check WB Hazard n?a.
        
        // T?ng h?p Data Hazard
        data_hazard = raw_hazard_ex | raw_hazard_mem;

        // --------------------------------------------------------
        // 2. X? LÝ ?U TIÊN (Priority Logic)
        // --------------------------------------------------------
        
        // M?c ??nh outputs
        o_stall       = 1'b0;
        o_flush_if_id = 1'b0;
        o_flush_id_ex = 1'b0;

        if (i_branch_taken) begin
            // --- CONTROL HAZARD (?u tiên cao nh?t) ---
            // N?u Branch Taken (quy?t ??nh ? EX), h?y các l?nh sai ?ang ? IF và ID
            o_flush_if_id = 1'b1; 
            o_flush_id_ex = 1'b1; 
        end 
        else if (data_hazard) begin
            // --- DATA HAZARD (Model 1: Non-forwarding) ---
            // N?u có xung ??t d? li?u, ta ph?i d?ng l?i ch? l?nh tr??c ghi xong.
            
            // 1. Stall Front-end: Gi? nguyên PC và l?nh hi?n t?i ? IF/ID
            o_stall       = 1'b1;
            
            // 2. Flush Back-end: ??y bong bóng (NOP) vào ID/EX ?? các t?ng sau ch?y ti?p
            o_flush_id_ex = 1'b1;
        end
    end

endmodule
