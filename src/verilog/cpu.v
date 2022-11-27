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
wire [1:0] rs1;
wire [2:0] rs2;
wire [1:0] wb_sel;
wire mem_wen, rf_wen;

wire [31:0] write_value;
// regとwireが混在しているのでエラー、regに統一する
assign write_value = (wb_sel_buf == `WB_ALU) ? if_alu_out :
                     (wb_sel_buf == `WB_MEM) ? mem_mem_out :
                     (wb_sel_buf == `WB_PC)  ? pc      : 32'd0 ;

// EXE stage
wire [31:0] alu_out;

// MEM stage
wire [31:0] mem_out;

// stallの制御

//====================================================================
// Instruction Fetch Stage
//====================================================================

PC pc_mod (
    .clk(clk),
    .reset(reset),
    .jump_flag(jump_flag),
    .jump_target(alu_out),
    .pc(pc)
);

INST_MEM inst_mem (
    .clk(clk),
    .addr(pc),
    .read_data(inst_out)
);

//====================================================================
// Instruction Decode Stage
//====================================================================

// 出力reg
decoder decoder(
    // input
    .inst(inst_out),
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
    .write_en(rf_wen),       
    .write_addr(write_addr),   
    .write_value(reg_write_value), 
    // output
    .rs1_data(rs1_data),    
    .rs2_data(rs2_data)     
);

// ALUでタイミングを合わせるのはdecoderからの値と、レジスタファイルからの読み出し
// pipeline register
reg [31:0] id_rs1_data, id_rs2_data;
reg [4:0] id_fn;
reg id_mem_wen;
    always @(posedge clk or posedge reset) begin
        if (!reset) begin
            id_mem_wen <= mem_wen;
            id_fn <= fn;
            id_rs1_data <= rs1_data;
            id_rs2_data <= rs2_data; 
        end
        else if (reset) begin
            id_mem_wen <= 1'd0;
            id_fn <= 5'd0;
            id_rs1_data <= 32'd0;
            id_rs2_data <= 32'd0; 
        end
    end

//====================================================================
// Execution Stage
//====================================================================

ALU ALU (
    .alu_fn(id_fn),
    .rs1_data(id_rs1_data),
    .rs2_data(id_rs2_data),
    .jump_flag(jump_flag),
    .out(alu_out)
);

// pipeline register
reg [31:0] exe_alu_out, exe_rs1_data, exe_rs2_data;
reg exe_mem_wen;
    always @(posedge clk or posedge reset) begin
        if (!reset) begin
            exe_mem_wen <= id_mem_wen;
            exe_alu_out <= alu_out;
            exe_rs1_data <= id_rs1_data;
            exe_rs2_data <= id_rs2_data;
        end
        else if (reset) begin
            exe_mem_wen <= 1'd0;
            exe_alu_out <= 32'd0; 
            exe_rs1_data <= id_rs1_data;
            exe_rs2_data <= id_rs2_data;
        end
    end

//====================================================================
// Memory Access Stage
//====================================================================

DATA_MEM data_mem (
    .clk(clk),
    .write_en(exe_mem_wen),
    .addr(exe_alu_out),
    .write_data(exe_rs2_data),
    .read_data(mem_out)
);

// pipeline register
reg [31:0] mem_mem_out;
    always @(posedge clk or posedge reset) begin
        if (!reset) begin
            mem_mem_out <= mem_out;
        end
        else if (reset) begin
            mem_mem_out <= 32'd0;
        end        
    end

//====================================================================
// Write Back Stage
//====================================================================

endmodule