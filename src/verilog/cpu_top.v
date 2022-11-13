// ここにないのはjump_controller.vとinstruction.v(こっちはおそらく必要ない)
// outputをregにしてtop,inputはwireでつなぐ
`include "define.vh"

module CPU(
    input wire clk, reset
);

wire jump_flag;
wire [31:0] jump_target;

wire [31:0] alu_out;
wire [31:0] rs1_data, rs2_data;
wire [31:0] pc;

wire [1:0] rs1;
wire [2:0] rs2;
wire [31:0] inst_out;
wire [31:0] imm;
wire [4:0] rs1_addr, rs2_addr;
wire [4:0] fn;
wire [1:0] wb_sel;
reg  [1:0] wb_sel_buf;
wire reg_write_en;
reg  reg_write_en_buf;
wire [4:0] reg_write_addr;
reg  [4:0] reg_write_addr_buf;
wire [31:0] reg_write_value;

wire mem_write_en;
reg  mem_write_en_buf;
wire [31:0] mem_out;
reg  [31:0] write_data_buf;

assign reg_write_value = (wb_sel_buf == `WB_ALU) ? alu_out :
                         (wb_sel_buf == `WB_MEM) ? mem_out :
                         (wb_sel_buf == `WB_PC)  ? pc      : 32'd0 ;

always @(posedge clk) begin
    wb_sel_buf <= wb_sel;
    reg_write_en_buf <= reg_write_en;
    reg_write_addr_buf <= reg_write_addr;
    write_data_buf <= rs2_data;
    mem_write_en_buf <= mem_write_en;
    pc_buf <= pc;
    op1_addr_buf <= op1_addr;
    op2_addr_buf <= op1_addr;
end

//====================================================================
// Instruction Fetch Stage
//====================================================================

PC PC (
    .clk(clk),
    .reset(reset),
    .jump_flag(jump_flag),
    .jump_target(jump_target),
    .pc(pc)
);

// pipeline register
    always @(posedge clk or posedge reset) begin

    end


//====================================================================
// Instruction Decode Stage
//====================================================================

decoder decoder(
    .inst(inst_out),
    .imm(imm),
    .op1_addr(op1_addr),
    .op2_addr(op2_addr),
    .rd_addr(reg_write_addr),
    .exe_fun(fn),
    .op1(op1),
    .mem_wen(mem_write_en),
    .rf_wen(reg_write_en),
    .op2(op2),
    .wb_sel(wb_sel)
);

reg_decode_reg_file reg_decode_reg_file (
    .clk(clk),
    .reset(reset),
    .op1_addr(op1_addr),
    .op2_addr(op2_addr),
    .pc(pc),
    .imm(imm),
    .op1(op1),
    .op2(op2),
    .write_en(reg_write_en_buf),
    .write_addr(reg_write_addr_buf),
    .write_value(reg_write_value),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data)
);

// pipeline register
    always @(posedge clk or posedge reset) begin

    end

//====================================================================
// Execution Stage
//====================================================================

ALU ALU (
    .alu_fn(fn),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .out(alu_out)
);

jump_controller jump_controller (
    .exe_fn(fn),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .jump_flag(jump_flag),
    .jump_target(jump_target)
);

// pipeline register
    always @(posedge clk or posedge reset) begin

    end

//====================================================================
// Memory Access Stage
//====================================================================

data_mem data_mem (
    .clk(clk),
    .write_en(mem_write_en_buf),
    .addr(alu_out),
    .write_data(write_data_buf),
    .read_data(mem_out)
);

inst_mem inst_mem (
    .clk(clk),
    .addr(pc),
    .read_data(inst_out)
);
// pipeline register
    always @(posedge clk or posedge reset) begin

    end

//====================================================================
// Write Back Stage
//====================================================================

endmodule