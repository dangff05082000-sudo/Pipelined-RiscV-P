module imem (
    input  logic        i_clk,
    input  logic [31:0] i_addr,
    output logic [31:0] o_instr
);
    // 64KB Memory = 16384 t? nh? (words)
    logic [31:0] mem [0:16383];

    initial begin
        // ??m b?o ???ng d?n file hex ?úng v?i c?u trúc th? m?c c?a b?n
        $readmemh("../02_test/isa.mem", mem);
    end

    always_ff @(posedge i_clk) begin
        // Word Address: B? 2 bit cu?i, l?y 14 bit ti?p theo (2^14 = 16384)
        o_instr <= mem[i_addr[15:2]]; 
    end

endmodule
