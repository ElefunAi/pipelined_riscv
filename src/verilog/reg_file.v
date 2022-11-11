`include "define.vh"

module REG_FILE (
    input wire clk,
    input wire reset,

    input wire write_en,
    input wire [4:0] write_addr,
    input wire [31:0] write_value,

    input wire [31:0] op1_addr, op2_addr,
    output wire [31:0] op1_data, op2_data
);

    reg [31:0] reg_file [0:31];

    always @(posedge clk) begin
        if (reset) begin
            reg_file[0] <= 32'b0; //zero ゼロレジスタ
            reg_file[2] <= 32'h0; //sp   スタックポイント
        end
        else if (write_en) begin
            reg_file[write_addr] <= write_value;
        end
    end

    assign op1_data = reg_file[op1_addr];
    assign op2_data = reg_file[op2_addr];

endmodule