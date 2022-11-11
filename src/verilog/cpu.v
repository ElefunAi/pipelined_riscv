module CPU (
    input wire clk, reset
);

// todo: 制御とパイプライン実装

wire [31:0] reg_write_value;
wire [31:0] alu_out;
wire [31:0] op1_data, op2_data;
wire [31:0] pc;

wire [1:0] op1;
wire [2:0] op2;
wire [31:0] imm;
wire [4:0] op1_addr, op2_addr, rd_addr;
wire [4:0] fn;
wire mem_wen, rf_wen;
wire [1:0] wb_sel;

wire [31:0] inst_data;
wire [31:0] read_data;


assign reg_write_value = (wb_sel == `WB_ALU) ? alu_out :
                         (wb_sel == `WB_MEM) ? mem_out :
                         (wb_sel == `WB_PC)  ? pc      : 32'd0 ;

PC pc (
    .clk(clk), // input
    .reset(reset), // input
    .jump_flag(), // input
    .jump_target(), // input
    .pc(pc) // output
);

DECODER decoder (
    .inst(), // input
    .imm(imm), // output
    .op1_addr(op1_addr), // output
    .op2_addr(op2_addr), // output
    .rd_addr(rd_addr), // output
    .fn(fn), // output
    .mem_wen(mem_wen), // output
    .rf_wen(rf_wen), // output
    .wb_sel(wb_sel), // output
    .op1(op1), // output 
    .op2(op2) // output
);

REG_FILE reg_file (
    .clk(clk), // input
    .reset(reset), // input
    .write_en(), // input
    .write_addr(), // input
    .write_value(), // input
    .op1_addr(), // input
    .op2_addr(), // input
    .op1_data(op1_data), // output
    .op2_data(op2_data) // output
);

ALU alu (
    .fn(), // input
    .rs1_data(), // input
    .rs2_data(), // input
    .out(alu_out) // output
);

INST_MEM inst_name (
    .addr(), // input
    .data(inst_data) // output
);

DATA_MEM data_mem (
    .clk(clk), // input
    .write_en(), // input
    .write_addr(), // input
    .write_data(), // input
    .read_addr(), // input
    .read_data(read_data) // output
);
    
endmodule