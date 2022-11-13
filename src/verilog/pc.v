module PC (
    input wire clk, reset,
    input wire jump_flag,
    input wire stall,
    input wire [31:0] jump_target,
    output wire [31:0] pc
);
    reg [31:0] pc_reg;

    always @(posedge clk) begin
        if (reset) pc_reg <= 32'b0;
        else if (jump_flag) pc_reg <= jump_target;
        else if (!stall) pc_reg <= pc + 4;
        else pc_reg <= pc_reg;
    end

    assign pc = pc_reg;

endmodule