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

// 内部信号
wire [6:0] opcode;
wire [2:0] funct3;
wire [6:0] funct7;
wire [4:0] rs1;
wire [4:0] rs2;
wire [4:0] rd;
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

always @(inst) begin
    casex (inst) 
        `LW    : begin fn=`ALU_ADD;  op1=`OP1_RS1; op2=`OP2_IMI; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_MEM; end
        `SW    : begin fn=`ALU_ADD;  op1=`OP1_RS1; op2=`OP2_IMS; mem_wen=`MEN_S; rf_wen=`REN_X; wb_sel=`WB_X;   end
        `ADD   : begin fn=`ALU_ADD;  op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `ADDI  : begin fn=`ALU_ADD;  op1=`OP1_RS1; op2=`OP2_IMI; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `SUB   : begin fn=`ALU_SUB;  op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `AND   : begin fn=`ALU_AND;  op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `OR    : begin fn=`ALU_OR;   op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `XOR   : begin fn=`ALU_XOR;  op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `ANDI  : begin fn=`ALU_AND;  op1=`OP1_RS1; op2=`OP2_IMI; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `ORI   : begin fn=`ALU_OR;   op1=`OP1_RS1; op2=`OP2_IMI; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `XORI  : begin fn=`ALU_XOR;  op1=`OP1_RS1; op2=`OP2_IMI; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `SLL   : begin fn=`ALU_SLL;  op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `SRL   : begin fn=`ALU_SRL;  op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `SRA   : begin fn=`ALU_SRA;  op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `SLLI  : begin fn=`ALU_SLL;  op1=`OP1_RS1; op2=`OP2_IMI; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `SRLI  : begin fn=`ALU_SRL;  op1=`OP1_RS1; op2=`OP2_IMI; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `SRAI  : begin fn=`ALU_SRA;  op1=`OP1_RS1; op2=`OP2_IMI; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `SLT   : begin fn=`ALU_SLT;  op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `SLTU  : begin fn=`ALU_SLTU; op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `SLTI  : begin fn=`ALU_SLT;  op1=`OP1_RS1; op2=`OP2_IMI; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `SLTIU : begin fn=`ALU_SLTU; op1=`OP1_RS1; op2=`OP2_IMI; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `BEQ   : begin fn=`BR_BEQ;   op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_X; wb_sel=`WB_X;   end
        `BNE   : begin fn=`BR_BNE;   op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_X; wb_sel=`WB_X;   end
        `BLT   : begin fn=`BR_BLT;   op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_X; wb_sel=`WB_X;   end
        `BGE   : begin fn=`BR_BGE;   op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_X; wb_sel=`WB_X;   end
        `BLTU  : begin fn=`BR_BLTU;  op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_X; wb_sel=`WB_X;   end
        `BGEU  : begin fn=`BR_BGEU;  op1=`OP1_RS1; op2=`OP2_RS2; mem_wen=`MEN_X; rf_wen=`REN_X; wb_sel=`WB_X;   end
        `JAL   : begin fn=`ALU_ADD;  op1=`OP1_PC;  op2=`OP2_IMJ; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_PC;  end
        `JALR  : begin fn=`ALU_JALR; op1=`OP1_RS1; op2=`OP2_IMI; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_PC;  end
        `LUI   : begin fn=`ALU_ADD;  op1=`OP1_X;   op2=`OP2_IMU; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        `AUIPC : begin fn=`ALU_ADD;  op1=`OP1_PC;  op2=`OP2_IMU; mem_wen=`MEN_X; rf_wen=`REN_S; wb_sel=`WB_ALU; end
        default: begin fn=`ALU_X;    op1=`OP1_X;   op2=`OP2_X;   mem_wen=`MEN_X; rf_wen=`REN_X; wb_sel=`WB_X  ; $display("hello"); end 
    endcase
end

endmodule