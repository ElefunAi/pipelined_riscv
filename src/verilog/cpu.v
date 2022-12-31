`include "define.vh"

module CPU(
    input wire clk, reset
);

// IF stage
wire jump_flag;
wire br_flag;
wire [31:0] pc;
wire [31:0] inst_out;

// ID stage
wire [31:0] imm;
wire [4:0]  rs1_addr, rs2_addr;
wire [31:0] rs1_data, rs2_data;
wire [4:0] fn;
wire [4:0] write_addr;
wire [1:0] rs1;
wire [2:0] rs2;
wire [1:0] wb_sel;
wire mem_wen, rf_wen;

// stall用
wire stall_flg;
wire id_rs1_data_hazard, id_rs2_data_hazard;
assign id_rs1_data_hazard = (((id_rf_wen == `REN_S) && (5'b0 !== rs1_addr_b) && (id_write_addr == rs1_addr_b)) ? 1'b1 : 1'b0);
assign id_rs2_data_hazard = (((id_rf_wen == `REN_S) && (5'b0 !== rs2_addr_b) && (id_write_addr == rs2_addr_b)) ? 1'b1 : 1'b0);
// assign stall_flg = 1'b0;
assign stall_flg = (id_rs1_data_hazard || id_rs2_data_hazard) ? 1'b1 : 1'b0;

// EXE stage
wire [31:0] alu_out;

// MEM stage
wire [31:0] mem_out;


//====================================================================
// Instruction Fetch Stage
//====================================================================

//  ジャンプ先への更新はジャンプ先命令が発行されるタイミングと合わせる
wire exe_br_flag,exe_jump_flag;
// program counterはbranchとjumpフラグで変化
PC pc_mod (
    // input
    .clk(clk),
    .reset(reset),
    .stall_flag(stall_flg),
    .jump_flag(exe_br_flag || exe_jump_flag),
    .jump_target(alu_out),
    // out
    .pc(pc)
);

INST_MEM inst_mem (
    // input
    .clk(clk),
    .addr(pc),
    // out
    .read_data(inst_out)
);

// pipeline register
reg [31:0] if_pc, if_inst_out;
always @(posedge clk or posedge reset) begin
        if (!reset) begin
            if_pc <= (stall_flg) ? if_pc : pc;
            if_inst_out <= (exe_br_flag || exe_jump_flag) ? `BUBBLE :
                           (stall_flg) ? if_inst_out : inst_out; // 命令ハザード処理
        end
        else if (reset) begin
            if_pc <= 32'b0;
            if_inst_out <= 32'b0;
        end
end

//====================================================================
// Instruction Decode Stage
//====================================================================
// stall用前処理
wire [4:0] rs1_addr_b, rs2_addr_b;
assign rs1_addr_b = id_inst[19:15];
assign rs2_addr_b = id_inst[24:20];

wire [31:0] id_inst;
assign id_inst = (exe_br_flag || exe_jump_flag || 1'b0) ? `BUBBLE : if_inst_out;

// 出力reg
DECODER decoder(
    // input
    .inst(id_inst),
    // output
    .imm(imm),            
    .rs1_addr(rs1_addr),  
    .rs2_addr(rs2_addr),  
    .rd_addr(write_addr), 
    .exe_fun(fn),      
    .rs1(rs1),         
    .rs2(rs2),         
    .mem_wen(mem_wen), 
    .rf_wen(rf_wen),   
    .wb_sel(wb_sel)    
);

REG_FILE reg_file (
    // input
    .clk(clk),      
    .reset(reset),  
    .rs1_addr(rs1_addr), 
    .rs2_addr(rs2_addr), 
    .write_en(mem_rf_wen),       
    .write_addr(mem_write_addr),   
    .write_value(mem_write_value), 
    // output
    .rs1_data(rs1_data),    
    .rs2_data(rs2_data)     
);

// forwarding用
wire [31:0] fw_rs1_data, fw_rs2_data;
                     // forwarding from MEM
assign fw_rs1_data = (rs1_addr == exe_write_addr && exe_rf_wen == `REN_S) ? write_value : 
                      // forwarding from WB
                     (rs1_addr == mem_write_addr && mem_rf_wen == `REN_S) ? mem_write_value : rs1_data;
assign fw_rs2_data = (rs2_addr == exe_write_addr && exe_rf_wen == `REN_S) ? write_value : 
                     (rs2_addr == mem_write_addr && mem_rf_wen == `REN_S) ? mem_write_value : rs2_data;

// data forwarding id_rs1_data,id_rs2_data 
// ALUでタイミングを合わせるのはdecoderからの値と、レジスタファイルからの読み出し
// pipeline register
reg [31:0] id_rs1_data, id_rs2_data, id_imm, id_pc;
reg [4:0] id_fn, id_write_addr;
reg [2:0] id_wb_sel, id_rs2;
reg [1:0] id_rs1;
reg id_mem_wen, id_rf_wen;
    always @(posedge clk or posedge reset) begin
        if (!reset) begin
            id_write_addr <= write_addr;
            id_fn <= fn;
            id_wb_sel <= wb_sel;
            id_mem_wen<= mem_wen;
            id_rf_wen <= rf_wen;
            id_imm  <= imm;
            id_rs1  <= rs1;
            id_rs2  <= rs2;
            id_pc   <= if_pc;
            id_rs1_data <= fw_rs1_data;
            id_rs2_data <= fw_rs2_data;
        end
        else if (reset) begin
            id_write_addr <= 5'd0;
            id_fn <= 5'd0;
            id_wb_sel  <= 2'd0;
            id_mem_wen <= 1'd0;
            id_rf_wen  <= 1'd0;
            id_imm <= 32'd0;
            id_rs1  <= 2'd0;
            id_rs2  <= 2'd0;
            id_pc   <= 32'd0;
            id_rs1_data <= 32'd0;
            id_rs2_data <= 32'd0;
        end
    end

//====================================================================
// Execution Stage
//====================================================================

// rs1_dataはPCかreg_fileの出力かを選択
// rs2_dataはIMM,reg_fileの出力かを選択
wire [31:0] alu_rs1;
wire [31:0] alu_rs2;
assign alu_rs1 =  (id_rs1 == `RS1_X)   ? 32'b0       :
                  (id_rs1 == `RS1_RS1) ? id_rs1_data :
                  (id_rs1 == `RS1_PC)  ? id_pc       : 32'bx;
assign alu_rs2 =  (id_rs2 == `RS2_X)   ? 32'b0       :
                  (id_rs2 == `RS2_RS2) ? id_rs2_data :
                  (id_rs2 == `RS2_IMI) ? id_imm      : 32'bx;

ALU ALU (
    // input
    .alu_fn(id_fn),
    .wb_sel(id_wb_sel),
    .rs1_data(alu_rs1),
    .rs2_data(alu_rs2),
    // output
    .br_flag(br_flag),
    .jump_flag(jump_flag),
    .out(alu_out)
);
// br_flag
assign exe_jump_flag = jump_flag;
assign exe_br_flag = br_flag;

// pipeline register
reg [31:0] exe_alu_out, exe_rs1_data, exe_rs2_data, exe_pc;
reg [4:0] exe_write_addr;
reg [1:0] exe_wb_sel;
reg exe_mem_wen, exe_rf_wen;
    always @(posedge clk or posedge reset) begin
        if (!reset) begin
            exe_mem_wen <= id_mem_wen;
            exe_rf_wen  <= id_rf_wen;
            exe_wb_sel  <= id_wb_sel;
            exe_write_addr <= id_write_addr;
            exe_alu_out <= alu_out;
            exe_rs1_data <= id_rs1_data;
            exe_rs2_data <= id_rs2_data;
            exe_pc <= id_pc;
        end
        else if (reset) begin
            exe_mem_wen <= 1'd0;
            exe_rf_wen  <= 1'd0;
            exe_wb_sel  <= 2'd0;
            exe_write_addr <= 5'd0;
            exe_alu_out <= 32'd0; 
            exe_rs1_data <= 32'd0;
            exe_rs2_data <= 32'd0;
            exe_pc <= 32'd0;
        end
    end

//====================================================================
// Memory Access Stage
//====================================================================

DATA_MEM data_mem (
    // input
    .clk(clk),
    .write_en(exe_mem_wen),
    .addr(exe_alu_out),
    .write_data(exe_rs2_data),
    // output
    .read_data(mem_out)
);

wire [31:0] write_value;
assign write_value = (exe_wb_sel == `WB_ALU) ? exe_alu_out    :
                     (exe_wb_sel == `WB_MEM) ? mem_out    :
                     (exe_wb_sel == `WB_PC)  ? exe_pc + 32'd4 : 32'd0 ;

//  pipeline register
reg [31:0] mem_write_value;
reg [4:0]  mem_write_addr;
reg mem_rf_wen;
    always @(posedge clk) begin
        mem_write_value <= write_value;
        mem_write_addr  <= exe_write_addr;
        mem_rf_wen  <= exe_rf_wen;
    end

//====================================================================
// Write Back Stage
//====================================================================

// WB2reg_file
// ID stageのreg_fileへ書き戻し

endmodule