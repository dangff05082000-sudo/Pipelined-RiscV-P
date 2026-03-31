module pc (
    input  logic        i_clk,
    input  logic        i_reset,
    input  logic        i_stall, // Input quan tr?ng cho Hazard
    input  logic [31:0] i_pc_next,
    output logic [31:0] o_pc
);
    always_ff @(posedge i_clk or negedge i_reset) begin
        if (!i_reset) begin
            o_pc <= 32'b0;
        end 
        else if (!i_stall) begin 
            // Ch? c?p nh?t PC m?i khi KHÔNG b? Stall
            o_pc <= i_pc_next;
        end
        // N?u i_stall == 1, o_pc gi? nguyên giá tr? c? (??ng yên)
    end
endmodule
