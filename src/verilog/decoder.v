`include "define.vh"

module DECODER (
    input wire [31:0] inst,
    output wire [31:0] imm,
    output wire [4:0] op1_addr, op2_addr, rd_addr,
    output reg [4:0] fn,
    output reg mem_wen, rf_wen,
    output reg [1:0] wb_sel,
    output reg [1:0] op1,
    output reg [2:0] op2
);

// assign
assign opcode = inst[6:0];
assign rd = inst[11:7];
assign funct3 = inst[14:12];
assign funct7 = inst[31:25];
assign op1_addr = inst[19:15];
assign op2_addr = inst[24:20];
assign rd_addr = inst[11:7];
// 即値の扱い方 risc-v ISA manual参照(P.24)
assign imm = (opcode == `LUI || opcode == `AUIPC) ? {inst[31:12], 12'd0} : // U-format
             (opcode == `JAL) ? {{11{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'd0} : // J-format
             (opcode == `JALR || opcode == `LW || opcode == `OPIMI) ? {{20{inst[31]}},inst[31],inst[30:25],inst[24:21],inst[20]} : // I-format
             (opcode == `BRANCH) ? {{18{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'd0} : //B-format
             (opcode == `STORE) ? {{20{inst[31]}},inst[31],inst[30:25],inst[11:8],inst[7]} : 32'd0;// ? S-format : R-format(即値なし)

always @* begin
    casex (inst) 
        `LW    : begin exe_fun=`ALU_ADD;  op1=`OP1_RS1; op2=`OP2_IMI; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_MEM; end
        `SW    : begin exe_fun=`ALU_ADD;  op1=`OP1_RS1; op2=`OP2_IMS; mem_wen=`MEN_S; rf_wen=`REN_X; wb_sel=`WB_X;   end
        `ADD   : begin exe_fun=`ALU_ADD;  op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `ADDI  : begin exe_fun=`ALU_ADD;  op1=`OP1_RS1; op2=`OP2_IMI; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `SUB   : begin exe_fun=`ALU_SUB;  op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `AND   : begin exe_fun=`ALU_AND;  op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `OR    : begin exe_fun=`ALU_OR;   op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `XOR   : begin exe_fun=`ALU_XOR;  op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `ANDI  : begin exe_fun=`ALU_AND;  op1=`OP1_RS1; op2=`OP2_IMI; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `ORI   : begin exe_fun=`ALU_OR;   op1=`OP1_RS1; op2=`OP2_IMI; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `XORI  : begin exe_fun=`ALU_XOR;  op1=`OP1_RS1; op2=`OP2_IMI; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `SLL   : begin exe_fun=`ALU_SLL;  op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `SRL   : begin exe_fun=`ALU_SRL;  op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `SRA   : begin exe_fun=`ALU_SRA;  op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `SLLI  : begin exe_fun=`ALU_SLL;  op1=`OP1_RS1; op2=`OP2_IMI; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `SRLI  : begin exe_fun=`ALU_SRL;  op1=`OP1_RS1; op2=`OP2_IMI; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `SRAI  : begin exe_fun=`ALU_SRA;  op1=`OP1_RS1; op2=`OP2_IMI; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `SLT   : begin exe_fun=`ALU_SLT;  op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `SLTU  : begin exe_fun=`ALU_SLTU; op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `SLTI  : begin exe_fun=`ALU_SLT;  op1=`OP1_RS1; op2=`OP2_IMI; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `SLTIU : begin exe_fun=`ALU_SLTU; op1=`OP1_RS1; op2=`OP2_IMI; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `BEQ   : begin exe_fun=`BR_BEQ;   op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_X; wb_sel=`WB_X;   end
        `BNE   : begin exe_fun=`BR_BNE;   op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_X; wb_sel=`WB_X;   end
        `BLT   : begin exe_fun=`BR_BLT;   op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_X; wb_sel=`WB_X;   end
        `BGE   : begin exe_fun=`BR_BGE;   op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_X; wb_sel=`WB_X;   end
        `BLTU  : begin exe_fun=`BR_BLTU;  op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_X; wb_sel=`WB_X;   end
        `BGEU  : begin exe_fun=`BR_BGEU;  op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_X; wb_sel=`WB_X;   end
        `JAL   : begin exe_fun=`ALU_ADD;  op1=`OP1_PC;  op2=`OP2_IMJ; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_PC;  end
        `JALR  : begin exe_fun=`ALU_JALR; op1=`OP1_RS1; op2=`OP2_IMI; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_PC;  end
        `LUI   : begin exe_fun=`ALU_ADD;  op1=`OP1_X;   op2=`OP2_IMU; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `AUIPC : begin exe_fun=`ALU_ADD;  op1=`OP1_PC;  op2=`OP2_IMU; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        default: begin exe_fun=`ALU_X;    op1=`OP1_X;   op2=`OP2_X;   mem_wen=`MEN_X; rf_wen=`REN_X; wb_sel=`WB_X  ; end 
    endcase
end

endmodule