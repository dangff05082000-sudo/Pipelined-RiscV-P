module dmem (
    input  logic        i_clk,
    input  logic        i_wren,
    input  logic [31:0] i_addr,
    input  logic [31:0] i_wdata,
    input  logic [3:0]  i_mask, // Byte mask t? LSU
    output logic [31:0] o_rdata
);
    // 64KB b? nh? d? li?u (Shared v?i Instruction memory trong ki?n trúc test này)
    logic [31:0] mem [0:16383]; 

    initial begin
        $readmemh("../02_test/isa.mem", mem);
    end

    // Synchronous Read & Write
    always_ff @(posedge i_clk) begin
        // Read
        // L?u ý: Trong pipeline, ??a ch? vào ? ??u chu k?, cu?i chu k? data m?i ra
        // ?i?u này kh?p v?i thi?t k? MEM stage
        o_rdata <= mem[i_addr[15:2]]; 
        
        // Write
        if (i_wren) begin
            if (i_mask[0]) mem[i_addr[15:2]][ 7: 0] <= i_wdata[ 7: 0];
            if (i_mask[1]) mem[i_addr[15:2]][15: 8] <= i_wdata[15: 8];
            if (i_mask[2]) mem[i_addr[15:2]][23:16] <= i_wdata[23:16];
            if (i_mask[3]) mem[i_addr[15:2]][31:24] <= i_wdata[31:24];
        end
    end
endmodule
