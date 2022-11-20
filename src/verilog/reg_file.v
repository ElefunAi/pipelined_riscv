`include "define.vh"

module REG_FILE (
    input wire clk,
    input wire reset,
    input wire write_en,
    input wire [4:0] write_addr,
    input wire [31:0] write_value,
    input wire [4:0] rs1_addr, rs2_addr,
    output wire [31:0] rs1_data, rs2_data
);

    reg [31:0] reg_file [0:31];

    always @(posedge clk) begin
        if (write_en) begin
            reg_file[write_addr] <= write_value;
        end
    end

    assign rs1_data = (rs1_addr == 5'b0) ? 32'b0 : reg_file[rs1_addr];
    assign rs2_data = (rs2_addr == 5'b0) ? 32'b0 : reg_file[rs2_addr];

endmodule