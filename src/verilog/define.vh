// RV32Iのみ(例外処理もなし)

// 命令の識別
`define LUI     7'b0110111
`define AUIPC   7'b0010111
`define JAL     7'b1101111
`define JALR    7'b1100111
`define BRANCH  7'b1100011
`define LW      7'b0000011
`define STORE   7'b0100011
`define OPIMI   7'b0010011 //OPERATION IMIDIATE
`define OPRS2   7'b0110011 //OPERATION RS2

// fn
`define ALU_X    5'd0
`define ALU_ADD  5'd1
`define ALU_SUB  5'd2
`define ALU_AND  5'd3
`define ALU_OR   5'd4
`define ALU_XOR  5'd5
`define ALU_SLL  5'd6
`define ALU_SRL  5'd7
`define ALU_SRA  5'd8
`define ALU_SLT  5'd9
`define ALU_SLTU 5'd10
`define BR_BEQ   5'd11
`define BR_BNE   5'd12
`define BR_BLT   5'd13
`define BR_BGE   5'd14
`define BR_BLTU  5'd15
`define BR_BGEU  5'd16
`define ALU_JALR 5'd17

// op1
`define OP1_X    2'd0
`define OP1_RS1  2'd1
`define OP1_PC   2'd2

// op2
`define OP2_X    3'd0
`define OP2_RS2  3'd1
`define OP2_IMI  3'd2
`define OP2_IMS  3'd3
`define OP2_IMJ  3'd4
`define OP2_IMU  3'd5

// mem_wen
`define MEN_X   1'd0
`define MEN_S   1'd1

// rf_wen

`define REN_X   1'd0
`define REN_S   1'd1

// wb_sel
`define WB_X      2'd0
`define WB_ALU    2'd1
`define WB_MEM    2'd2
`define WB_PC     2'd3

/* 以下命令コード */
// ロード・ストア
`define LW     32'bxxxxxxxxxxxxxxxxx010xxxxx0000011
`define SW     32'bxxxxxxxxxxxxxxxxx010xxxxx0100011

// 加算
`define ADD    32'b0000000xxxxxxxxxx000xxxxx0110011
`define ADDI   32'bxxxxxxxxxxxxxxxxx000xxxxx0010011

// 減算
`define SUB    32'b0100000xxxxxxxxxx000xxxxx0110011

// 論理演算
`define AND    32'b0000000xxxxxxxxxx111xxxxx0110011
`define OR     32'b0000000xxxxxxxxxx110xxxxx0110011
`define XOR    32'b0000000xxxxxxxxxx100xxxxx0110011
`define ANDI   32'bxxxxxxxxxxxxxxxxx111xxxxx0010011
`define ORI    32'bxxxxxxxxxxxxxxxxx110xxxxx0010011
`define XORI   32'bxxxxxxxxxxxxxxxxx100xxxxx0010011

// シフト
`define SLL    32'b0000000xxxxxxxxxx001xxxxx0110011
`define SRL    32'b0000000xxxxxxxxxx101xxxxx0110011
`define SRA    32'b0100000xxxxxxxxxx101xxxxx0110011
`define SLLI   32'b0000000xxxxxxxxxx001xxxxx0010011
`define SRLI   32'b0000000xxxxxxxxxx101xxxxx0010011
`define SRAI   32'b0100000xxxxxxxxxx101xxxxx0010011

// 比較
`define SLT    32'b0000000xxxxxxxxxx010xxxxx0110011
`define SLTU   32'b0000000xxxxxxxxxx011xxxxx0110011
`define SLTI   32'bxxxxxxxxxxxxxxxxx010xxxxx0010011
`define SLTIU  32'bxxxxxxxxxxxxxxxxx011xxxxx0010011

// 条件分岐
`define BEQ    32'bxxxxxxxxxxxxxxxxx000xxxxx1100011
`define BNE    32'bxxxxxxxxxxxxxxxxx001xxxxx1100011
`define BLT    32'bxxxxxxxxxxxxxxxxx100xxxxx1100011
`define BGE    32'bxxxxxxxxxxxxxxxxx101xxxxx1100011
`define BLTU   32'bxxxxxxxxxxxxxxxxx110xxxxx1100011
`define BGEU   32'bxxxxxxxxxxxxxxxxx111xxxxx1100011

// ジャンプ
`define JAL    32'bxxxxxxxxxxxxxxxxxxxxxxxxx1101111
`define JALR   32'bxxxxxxxxxxxxxxxxx000xxxxx1100111

// 即値ロード
`define LUI    32'bxxxxxxxxxxxxxxxxxxxxxxxxx0110111
`define AUIPC  32'bxxxxxxxxxxxxxxxxxxxxxxxxx0010111