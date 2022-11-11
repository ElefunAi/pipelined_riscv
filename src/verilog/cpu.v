module CPU (
    input wire clk, reset
);

// todo: 制御とパイプライン実装
// pc を伝播する必要あり

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

wire [31:0] inst;
wire [31:0] mem_out;

wire jump_flag;
wire [31:0] jump_target;

// IF
reg [31:0] if_id_pc;
reg [31:0] if_id_inst;

// ID
reg [31:0] id_ex_pc;
reg [4:0] id_ex_fn;
reg [31:0] id_ex_rs1_data;
reg [31:0] id_ex_rs2_data;
reg id_ex_mem_wen;
reg [1:0] id_ex_wb_sel;
reg id_ex_rf_wen;
reg [4:0] id_ex_rd_addr;

// EX
reg [31:0] ex_mem_pc;
reg [31:0] ex_mem_rs2_data;
reg [31:0] ex_mem_alu_out;
reg ex_mem_mem_wen;
reg [1:0] ex_mem_wb_sel;
reg ex_mem_rf_wen;
reg [4:0] ex_mem_rd_addr;

// MEM
reg [31:0] mem_wb_pc;
reg [31:0] mem_wb_alu_out;
reg [31:0] mem_wb_mem_out;
reg [1:0] mem_wb_wb_sel;
reg mem_wb_rf_wen;
reg [4:0] mem_wb_rd_addr;
//WB

always @(posedge clk) begin
    // if (reset) begin
    //     // IF
    //     if_id_pc <= 0;
    //     if_id_inst <= 0;

    //     // ID
    //     id_ex_pc <= 0;
    //     id_ex_fn <= 0;
    //     id_ex_rs1_data <= 0;
    //     id_ex_rs2_data <= 0;
    //     id_ex_mem_wen <= 0;
    //     id_ex_wb_sel <= 0;
    //     id_ex_rf_wen <= 0;
    //     id_ex_rd_addr <= 0;

    //     // EX
    //     ex_mem_pc <= 0;
    //     ex_mem_rs2_data <= 0;
    //     ex_mem_alu_out <= 0;
    //     ex_mem_mem_wen <= 0;
    //     ex_mem_wb_sel <= 0;
    //     ex_mem_rf_wen <= 0;
    //     ex_mem_rd_addr <= 0;

    //     // MEM
    //     mem_wb_pc <= 0;
    //     mem_wb_alu_out <= 0;
    //     mem_wb_mem_out <= 0;
    //     mem_wb_wb_sel <= 0;
    //     mem_wb_rf_wen <= 0;
    //     mem_wb_rd_addr <= 0;
    // end

    // IF
    if_id_pc <= pc;
    if_id_inst <= inst;

    // ID
    id_ex_pc <= if_id_pc;
    id_ex_fn <= fn;
    id_ex_rs1_data <= rs1_data;
    id_ex_rs2_data <= rs2_data;
    id_ex_mem_wen <= mem_wen;
    id_ex_wb_sel <= wb_sel;
    id_ex_rf_wen <= rf_wen;
    id_ex_rd_addr <= rd_addr;

    // EX
    ex_mem_pc <= id_ex_pc;
    ex_mem_rs2_data <= id_ex_rs2_data;
    ex_mem_alu_out <= alu_out;
    ex_mem_mem_wen <= id_ex_mem_wen;
    ex_mem_wb_sel <= id_ex_wb_sel;
    ex_mem_rf_wen <= id_ex_rf_wen;
    ex_mem_rd_addr <= id_ex_rd_addr;

    // MEM
    mem_wb_pc <= ex_mem_pc;
    mem_wb_alu_out <= ex_mem_alu_out;
    mem_wb_mem_out <= mem_out;
    mem_wb_wb_sel <= ex_mem_wb_sel;
    mem_wb_rf_wen <= ex_mem_rf_wen;
    mem_wb_rd_addr <= ex_mem_rd_addr;
end

wire [31:0] rs1_data;
assign rs1_data = (op1 == `OP1_X)   ? 32'b0    :
                  (op1 == `OP1_RS1) ? op1_data :
                  (op1 == `OP1_PC)  ? if_id_pc : 32'bx;

wire [31:0] rs2_data;
assign rs2_data = (op2 == `OP2_X)   ? 32'b0    :
                  (op2 == `OP2_RS2) ? op2_data :
                  (op2 == `OP2_IMI) ||
                  (op2 == `OP2_IMS) ||
                  (op2 == `OP2_IMJ) ||
                  (op2 == `OP2_IMU) ? imm      : 32'bx;
               

wire [31:0] rf_write_value;
assign rf_write_value = (mem_wb_wb_sel == `WB_ALU) ? mem_wb_alu_out :
                        (mem_wb_wb_sel == `WB_MEM) ? mem_wb_alu_out :
                        (mem_wb_wb_sel == `WB_PC)  ? mem_wb_pc      : 32'd0 ;

PC pc_mod (
    .clk(clk), // input
    .reset(reset), // input
    .jump_flag(jump_flag), // input
    .jump_target(jump_target), // input
    .pc(pc) // output
);

DECODER decoder (
    .inst(if_id_inst), // input
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
    .write_en(mem_wb_rf_wen), // input
    .write_addr(mem_wb_rd_addr), // input
    .write_value(rf_write_value), // input
    .op1_addr(op1_addr), // input
    .op2_addr(op2_addr), // input
    .op1_data(op1_data), // output
    .op2_data(op2_data) // output
);

JUMP_CONTROLLER jump_controller (
    .fn(id_ex_fn), // input
    .rs1_data(id_ex_rs1_data), // input
    .rs2_data(id_ex_rs2_data), // input
    .jump_flag(jump_flag), // output
    .jump_target(jump_target) // output
);

ALU alu (
    .fn(id_ex_fn), // input
    .rs1_data(id_ex_rs1_data), // input
    .rs2_data(id_ex_rs2_data), // input
    .out(alu_out) // output
);

INST_MEM inst_name (
    .addr(pc), // input
    .data(inst) // output
);

DATA_MEM data_mem (
    .clk(clk), // input
    .write_en(ex_mem_mem_wen), // input
    .addr(ex_mem_alu_out), // input
    .write_data(ex_mem_rs2_data), // input
    .read_data(mem_out) // output
);
    
endmodule