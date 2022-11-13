`include "define.vh"

module JUMP_CONTROLLER (
    input wire [4:0] fn,
    input wire [31:0] rs1_data,
    input wire [31:0] rs2_data,
    output wire jump_flag,
    output wire [31:0] jump_target
);
    // 条件分岐
    wire active_beq;
    assign active_beq = (rs1_data == rs2_data) ? 1'b1 : 1'b0;

    wire active_bne;
    assign active_bne = (rs1_data != rs2_data) ? 1'b1 : 1'b0;

    wire active_blt;
    assign active_blt = ($signed(rs1_data) < $signed(rs2_data)) ? 1'b1 : 1'b0;

    wire active_bge;
    assign active_bge = ($signed(rs1_data) > $signed(rs2_data)) ? 1'b1 : 1'b0;
    
    wire active_bltu;
    assign active_bltu = (rs1_data < rs2_data) ? 1'b1 : 1'b0;

    wire active_bgeu;
    assign active_bgeu = (rs1_data > rs2_data) ? 1'b1 : 1'b0;

    wire [31:0] jalr_target;
    assign jalr_target = (rs1_data + rs2_data) & ~32'b1;

    // output
    assign jump_flag = (fn == `BR_BEQ) ? active_beq :
                       (fn == `BR_BNE) ? active_bne :
                       (fn == `BR_BLT) ? active_blt :
                       (fn == `BR_BGE) ? active_bge :
                       (fn == `BR_BLTU) ? active_bltu :
                       (fn == `BR_BGEU) ? active_bgeu :
                       (fn == `ALU_JALR) ? 1'b1 : 1'b0;
    assign jump_target = (fn == `ALU_JALR) ? jalr_target : rs2_data;

endmodule