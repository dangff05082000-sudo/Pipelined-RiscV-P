module imem (
    input  logic        i_clk,
    input  logic [31:0] i_addr,
    output logic [31:0] o_instr
);
    // 64KB b? nh? l?nh (16384 words) - Theo yêu c?u mapping Milestone 3
    // Tuy nhiên ?? test ISA c? b?n, có th? ?? nh? h?n (ví d? 8KB) ?? ch?y simulation nhanh h?n
    // Nh?ng ??a ch? input vào v?n là 32-bit
    logic [31:0] mem [0:8191]; // 32KB

    initial begin
        // ???ng d?n file hex ph?i chính xác
        $readmemh("../02_test/isa_4b.hex", mem); 
    end

    // Synchronous Read: Output thay ??i sau c?nh lên clock
    always_ff @(posedge i_clk) begin
        // PC chia 4 ?? l?y index word (Word Aligned)
        o_instr <= mem[i_addr[14:2]]; 
    end

endmodule
