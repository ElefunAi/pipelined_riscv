`include "define.vh"

module DECODER (
    input wire [31:0] inst,
    output wire [31:0] imm,
    output wire [4:0] op1_addr, op2_addr, rd_addr,
    output wire [4:0] fn,
    output wire mem_wen, rf_wen,
    output wire [1:0] wb_sel,
    output wire [1:0] op1,
    output wire [2:0] op2
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

function [13:0] parse_fn_op1_op2_memwen_rfwen_wbsel;
    input [31:0] inst;
    casex (inst) 
    `LW    : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_ADD,  `OP1_RS1, `OP2_IMI, `MEN_X, `REN_S, `WB_MEM};
    `SW    : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_ADD,  `OP1_RS1, `OP2_IMS, `MEN_S, `REN_X, `WB_X  };
    `ADD   : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_ADD,  `OP1_RS1, `OP2_RS2, `MEN_X, `REN_S, `WB_ALU};
    `ADDI  : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_ADD,  `OP1_RS1, `OP2_IMI, `MEN_X, `REN_S, `WB_ALU};
    `SUB   : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_SUB,  `OP1_RS1, `OP2_RS2, `MEN_X, `REN_S, `WB_ALU};
    `AND   : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_AND,  `OP1_RS1, `OP2_RS2, `MEN_X, `REN_S, `WB_ALU};
    `OR    : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_OR,   `OP1_RS1, `OP2_RS2, `MEN_X, `REN_S, `WB_ALU};
    `XOR   : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_XOR,  `OP1_RS1, `OP2_RS2, `MEN_X, `REN_S, `WB_ALU};
    `ANDI  : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_AND,  `OP1_RS1, `OP2_IMI, `MEN_X, `REN_S, `WB_ALU};
    `ORI   : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_OR,   `OP1_RS1, `OP2_IMI, `MEN_X, `REN_S, `WB_ALU};
    `XORI  : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_XOR,  `OP1_RS1, `OP2_IMI, `MEN_X, `REN_S, `WB_ALU};
    `SLL   : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_SLL,  `OP1_RS1, `OP2_RS2, `MEN_X, `REN_S, `WB_ALU};
    `SRL   : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_SRL,  `OP1_RS1, `OP2_RS2, `MEN_X, `REN_S, `WB_ALU};
    `SRA   : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_SRA,  `OP1_RS1, `OP2_RS2, `MEN_X, `REN_S, `WB_ALU};
    `SLLI  : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_SLL,  `OP1_RS1, `OP2_IMI, `MEN_X, `REN_S, `WB_ALU};
    `SRLI  : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_SRL,  `OP1_RS1, `OP2_IMI, `MEN_X, `REN_S, `WB_ALU};
    `SRAI  : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_SRA,  `OP1_RS1, `OP2_IMI, `MEN_X, `REN_S, `WB_ALU};
    `SLT   : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_SLT,  `OP1_RS1, `OP2_RS2, `MEN_X, `REN_S, `WB_ALU};
    `SLTU  : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_SLTU, `OP1_RS1, `OP2_RS2, `MEN_X, `REN_S, `WB_ALU};
    `SLTI  : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_SLT,  `OP1_RS1, `OP2_IMI, `MEN_X, `REN_S, `WB_ALU};
    `SLTIU : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_SLTU, `OP1_RS1, `OP2_IMI, `MEN_X, `REN_S, `WB_ALU};
    `BEQ   : parse_fn_op1_op2_memwen_rfwen_wbsel = {`BR_BEQ,   `OP1_RS1, `OP2_RS2, `MEN_X, `REN_X, `WB_X  };
    `BNE   : parse_fn_op1_op2_memwen_rfwen_wbsel = {`BR_BNE,   `OP1_RS1, `OP2_RS2, `MEN_X, `REN_X, `WB_X  };
    `BLT   : parse_fn_op1_op2_memwen_rfwen_wbsel = {`BR_BLT,   `OP1_RS1, `OP2_RS2, `MEN_X, `REN_X, `WB_X  };
    `BGE   : parse_fn_op1_op2_memwen_rfwen_wbsel = {`BR_BGE,   `OP1_RS1, `OP2_RS2, `MEN_X, `REN_X, `WB_X  };
    `BLTU  : parse_fn_op1_op2_memwen_rfwen_wbsel = {`BR_BLTU,  `OP1_RS1, `OP2_RS2, `MEN_X, `REN_X, `WB_X  };
    `BGEU  : parse_fn_op1_op2_memwen_rfwen_wbsel = {`BR_BGEU,  `OP1_RS1, `OP2_RS2, `MEN_X, `REN_X, `WB_X  };
    `JAL   : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_ADD,  `OP1_PC,  `OP2_IMJ, `MEN_X, `REN_S, `WB_PC };
    `JALR  : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_JALR, `OP1_RS1, `OP2_IMI, `MEN_X, `REN_S, `WB_PC };
    `LUI   : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_ADD,  `OP1_X,   `OP2_IMU, `MEN_X, `REN_S, `WB_ALU};
    `AUIPC : parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_ADD,  `OP1_PC,  `OP2_IMU, `MEN_X, `REN_S, `WB_ALU};
    default: parse_fn_op1_op2_memwen_rfwen_wbsel = {`ALU_X,    `OP1_X,   `OP2_X,   `MEN_X, `REN_X, `WB_X  }; 
    endcase
endfunction

assign {fn, op1, op2, mem_wen, rf_wen, wb_sel} = parse_fn_op1_op2_memwen_rfwen_wbsel(inst);
endmodule