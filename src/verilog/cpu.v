`include "define.vh"

module CPU(
    input wire clk, reset
);

// IF stage
wire jump_flag;
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

// EXE stage
wire [31:0] alu_out;

// MEM stage
wire [31:0] mem_out;

// stallの制御

//====================================================================
// Instruction Fetch Stage
//====================================================================

PC pc_mod (
    // input
    .clk(clk),
    .reset(reset),
    .jump_flag(jump_flag),
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
            if_pc <= pc;
            if_inst_out <= inst_out;
        end
        else if (reset) begin
            if_pc <= 32'b0;
            if_inst_out <= 32'b0;
        end
end

//====================================================================
// Instruction Decode Stage
//====================================================================

// 出力reg
DECODER decoder(
    // input
    .inst(if_inst_out),
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

wire [31:0] wb_write_value;
assign wb_write_value = (wb_wb_sel == `WB_ALU) ? wb_alu_out :
                        (wb_wb_sel == `WB_MEM) ? wb_mem_out :
                        (wb_wb_sel == `WB_PC)  ? if_pc      : 32'd0 ;

REG_FILE reg_file (
    // input
    .clk(clk),      
    .reset(reset),  
    .rs1_addr(rs1_addr), 
    .rs2_addr(rs2_addr), 
    .write_en(wb_rf_wen),       
    .write_addr(wb_write_addr),   
    .write_value(wb_write_value), 
    // output
    .rs1_data(rs1_data),    
    .rs2_data(rs2_data)     
);

// ALUでタイミングを合わせるのはdecoderからの値と、レジスタファイルからの読み出し
// pipeline register
reg [31:0] id_rs1_data, id_rs2_data;
reg [4:0] id_fn, id_write_addr;
reg [2:0] id_wb_sel;
reg id_mem_wen, id_rf_wen;
    always @(posedge clk or posedge reset) begin
        if (!reset) begin
            id_write_addr <= write_addr;
            id_fn <= fn;
            id_wb_sel <= wb_sel;
            id_mem_wen<= mem_wen;
            id_rf_wen <= rf_wen;
            id_rs1_data <= rs1_data;
            id_rs2_data <= rs2_data; 
        end
        else if (reset) begin
            id_write_addr <= 5'd0;
            id_fn <= 5'd0;
            id_wb_sel  <= 2'd0;
            id_mem_wen <= 1'd0;
            id_rf_wen  <= 1'd0;
            id_rs1_data <= 32'd0;
            id_rs2_data <= 32'd0; 
        end
    end

//====================================================================
// Execution Stage
//====================================================================

ALU ALU (
    // input
    .alu_fn(id_fn),
    .rs1_data(id_rs1_data),
    .rs2_data(id_rs2_data),
    // output
    .jump_flag(jump_flag),
    .out(alu_out)
);

// pipeline register
reg [31:0] exe_alu_out, exe_rs1_data, exe_rs2_data;
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
        end
        else if (reset) begin
            exe_mem_wen <= 1'd0;
            exe_rf_wen  <= 1'd0;
            exe_wb_sel  <= 2'd0;
            exe_write_addr <= 5'd0;
            exe_alu_out <= 32'd0; 
            exe_rs1_data <= id_rs1_data;
            exe_rs2_data <= id_rs2_data;
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


//====================================================================
// Write Back Stage
//====================================================================

// pipeline register
reg [31:0] wb_mem_out, wb_alu_out;
reg [4:0] wb_write_addr;
reg [1:0] wb_wb_sel;
reg wb_rf_wen;
    always @(posedge clk) begin
        wb_alu_out <= exe_alu_out;
        wb_mem_out <= mem_out;
        wb_write_addr <= exe_write_addr;
        wb_wb_sel  <= exe_wb_sel;
        wb_rf_wen  <= exe_rf_wen;
    end

endmodule