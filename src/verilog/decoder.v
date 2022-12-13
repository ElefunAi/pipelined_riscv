`include "define.vh"
module DECODER (
    input wire [31:0] inst,
    output wire [31:0] imm,
    output wire [4:0] rs1_addr, rs2_addr, rd_addr,
    output wire [4:0] exe_fun,
    output wire mem_wen, rf_wen,
    output wire [1:0] rs1, rs2, wb_sel
);
    // 宣言
    // 内部信号
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [4:0] rd;

    // opcodeから命令形式保持(R,I,S,B,U,Jなので、3bitレジスタで保持)
    reg [2:0] alu_x;

    // assign
    assign opcode = inst[6:0];
    assign rd = inst[11:7];
    assign funct3 = inst[14:12];
    assign funct7 = inst[31:25];

    // デコーダが渡すもの
    // exe_fun(演算内容),rs1(第1オペランド),rs2(第2オペランド),mem_wen(メモリenable),
    // rf_wen(ライトバックenable),wb_sel(ライトバックデータセレクタ)
    // wb_selで例えばWB_ALUは、ALUの出力をレジスタへ書き戻すことを表す
    // つまり、reg_fileにとってはWB_ALU & rf_wen(Write ENable)がenable信号
    // reg_fileに対して=>32bit rs1_addr, rs2_addr, rd_addr, imm(即値)
    assign rs1_addr = inst[19:15];
    assign rs2_addr = inst[24:20];
    assign rd_addr = inst[11:7];
    // 即値の扱い方 risc-v ISA manual参照(P.24)
    assign imm = (opcode == `LUI || opcode == `AUIPC) ? {inst[31:12], 12'd0} : // U-format
                 (opcode == `JAL) ? {{11{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'd0} : // J-format
                 (opcode == `JALR || opcode == `LW || opcode == `OPIMI) ? {{20{inst[31]}},inst[31],inst[30:25],inst[24:21],inst[20]} : // I-format
                 (opcode == `BRANCH) ? {{19{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'd0} : //B-format
                 (opcode == `STORE) ? {{20{inst[31]}},inst[31],inst[30:25],inst[11:8],inst[7]} : 32'd0;// ? S-format : R-format(即値なし)

    function [13:0] ports;
        input [6:0] opcode;
        input [2:0] funct3;
        input [6:0] funct7;
        case (opcode)
            `LUI : begin
                ports = {`ALU_ADD, `RS1_X, `RS2_IMI, `MEN_X, `REN_S, `WB_ALU};
            end
            `AUIPC : begin
                ports = {`ALU_ADD, `RS1_PC, `RS2_IMI, `MEN_X, `REN_S, `WB_ALU};
            end
            `JAL : begin
                ports = {`ALU_ADD, `RS1_PC, `RS2_IMI, `MEN_X, `REN_S, `WB_PC};   
            end
            `JALR : begin
                ports = {`ALU_JALR, `RS1_RS1, `RS2_IMI, `MEN_X, `REN_S, `WB_PC};                 
            end
            `BRANCH : begin
                case (funct3)
                    3'b000 : begin  //BEQ
                        ports = {`BR_BEQ, `RS1_RS1, `RS2_RS2, `MEN_X, `REN_X, `WB_X};
                    end
                    3'b001 : begin  //BNE
                        ports = {`BR_BNE, `RS1_RS1, `RS2_RS2, `MEN_X, `REN_X, `WB_X};
                    end
                    3'b100 : begin  //BLT
                        ports = {`BR_BLT, `RS1_RS1, `RS2_RS2, `MEN_X, `REN_X, `WB_X};                       
                    end
                    3'b101 : begin  //BGE
                        ports = {`BR_BGE, `RS1_RS1, `RS2_RS2, `MEN_X, `REN_X, `WB_X};                      
                    end
                    3'b110 : begin  //BLTU
                        ports = {`BR_BLTU, `RS1_RS1, `RS2_RS2, `MEN_X, `REN_X, `WB_X};                       
                    end
                    3'b111 : begin  //BGEU
                        ports = {`BR_BGEU, `RS1_RS1, `RS2_RS2, `MEN_X, `REN_X, `WB_X};
                    end
                    default: begin //NOP=>_Xで統一
                        ports = {`ALU_X, `RS1_X, `RS2_X, `MEN_X, `REN_X, `WB_X};
                    end
                endcase
            end
            `LW : begin
                ports = {`ALU_ADD, `RS1_RS1, `RS2_RS2, `MEN_X, `REN_S, `WB_MEM};            
            end
            `STORE : begin
                ports = {`ALU_ADD, `RS1_RS1, `RS2_IMI, `MEN_S, `REN_X, `WB_X};                    
            end
            `OPIMI : begin
                case (funct3)
                    3'b000 : begin  //ADDI
                        ports = {`ALU_ADD, `RS1_RS1, `RS2_IMI, `MEN_X, `REN_S, `WB_ALU};                                       
                    end
                    3'b001 : begin  //SLLI
                        ports = {`ALU_SLL, `RS1_RS1, `RS2_IMI, `MEN_X, `REN_S, `WB_ALU};                        
                    end
                    3'b010 : begin  //SLTI
                        ports = {`ALU_SLT, `RS1_RS1, `RS2_IMI, `MEN_X, `REN_S, `WB_ALU};                 
                    end
                    3'b011 : begin  //SLTIU
                        ports = {`ALU_SLTU, `RS1_RS1, `RS2_IMI, `MEN_X, `REN_S, `WB_ALU};
                    end
                    3'b100 : begin  //XORI
                        ports = {`ALU_XOR, `RS1_RS1, `RS2_IMI, `MEN_X, `REN_S, `WB_ALU};                      
                    end
                    3'b101 : begin
                        case (funct7)
                            7'b0000000 : begin  //SRLI
                                ports = {`ALU_SRL, `RS1_RS1, `RS2_IMI, `MEN_X, `REN_S, `WB_ALU};                            
                            end
                            7'b0100000 : begin  //SRAI
                                ports = {`ALU_SRA, `RS1_RS1, `RS2_IMI, `MEN_X, `REN_S, `WB_ALU};
                            end
                            default: begin //NOP=>_Xで統一
                                ports = {`ALU_X, `RS1_X, `RS2_X, `MEN_X, `REN_X, `WB_X};
                            end
                        endcase
                    end
                    3'b110 : begin  //ORI
                        ports = {`ALU_OR, `RS1_RS1, `RS2_IMI, `MEN_X, `REN_S, `WB_ALU};                       
                    end
                    3'b111 : begin  //ANDI
                        ports = {`ALU_AND, `RS1_RS1, `RS2_IMI, `MEN_X, `REN_S, `WB_ALU};                       
                    end
                    default: begin //NOP=>_Xで統一 
                        ports = {`ALU_X, `RS1_X, `RS2_X, `MEN_X, `REN_X, `WB_X};
                    end
                endcase
            end
            `OPRS2 : begin
                case (funct3)
                    3'b000 : begin
                        case (funct7)
                            7'b0000000 :  begin  //ADD
                                ports = {`ALU_ADD, `RS1_RS1, `RS2_RS2, `MEN_X, `REN_S, `WB_ALU};
                            end
                            7'b0100000 :  begin  //SUB
                                ports = {`ALU_SUB, `RS1_RS1, `RS2_RS2, `MEN_X, `REN_S, `WB_ALU};
                            end
                            default: begin //NOP=>_Xで統一 
                                ports = {`ALU_X, `RS1_X, `RS2_X, `MEN_X, `REN_X, `WB_X};
                            end
                        endcase
                    end
                    3'b001 : begin  //SLL
                        ports = {`ALU_SLL, `RS1_RS1, `RS2_RS2, `MEN_X, `REN_S, `WB_ALU};                      
                    end
                    3'b010 : begin  //SLT
                        ports = {`ALU_SLT, `RS1_RS1, `RS2_RS2, `MEN_X, `REN_S, `WB_ALU};                                           
                    end
                    3'b011 : begin  //SLTU
                        ports = {`ALU_SLTU, `RS1_RS1, `RS2_RS2, `MEN_X, `REN_S, `WB_ALU};                      
                    end
                    3'b100 : begin  //XOR
                        ports = {`ALU_XOR, `RS1_RS1, `RS2_RS2, `MEN_X, `REN_S, `WB_ALU};                                             
                    end
                    3'b101 : begin
                        case (funct7)
                            7'b0000000 :  begin  //SRL
                                ports = {`ALU_SRL, `RS1_RS1, `RS2_RS2, `MEN_X, `REN_S, `WB_ALU};
                            end
                            7'b0100000 :  begin  //SRA
                                ports = {`ALU_SRA, `RS1_RS1, `RS2_RS2, `MEN_X, `REN_S, `WB_ALU};
                            end
                            default: begin //NOP=>_Xで統一
                                ports = {`ALU_X, `RS1_X, `RS2_X, `MEN_X, `REN_X, `WB_X};
                            end
                        endcase
                    end
                    3'b110 : begin  //OR
                        ports = {`ALU_OR, `RS1_RS1, `RS2_RS2, `MEN_X, `REN_S, `WB_ALU};                      
                    end
                    3'b111 : begin  //AND
                        ports = {`ALU_AND, `RS1_RS1, `RS2_RS2, `MEN_X, `REN_S, `WB_ALU};                   
                    end
                    default: begin //NOP=>_Xで統一 
                        ports = {`ALU_X, `RS1_X, `RS2_X, `MEN_X, `REN_X, `WB_X};
                    end
                endcase
            end
            default: begin //NOP=>_Xで統一 
                ports = {`ALU_X, `RS1_X, `RS2_X, `MEN_X, `REN_X, `WB_X};
            end
        endcase        
    endfunction
    assign {exe_fun, rs1, rs2, mem_wen, rf_wen, wb_sel} = ports(opcode, funct3, funct7);
endmodule