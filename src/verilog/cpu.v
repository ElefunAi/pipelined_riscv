module CPU (
    input wire clk, reset
);

assign reg_write_value = (wb_sel == `WB_ALU) ? alu_out :
                         (wb_sel == `WB_MEM) ? mem_out :
                         (wb_sel == `WB_PC)  ? pc      : 32'd0 ;

PC pc (
    .clk(),
    .reset(),
    .jump_flag(),
    .jump_target(),
    .pc()
);

DECODER decoder (
    .inst(),
    .imm(),
    .op1_addr(),
    .op2_addr(),
    .rd_addr(),
    .fn(),
    .mem_wen(),
    .rf_wen(),
    .wb_sel(),
    .op1(), 
    .op2()
);

REG_FILE reg_file (
    .clk(),
    .reset(),
    .write_en(),
    .write_addr(),
    .write_value(),
    .op1_addr(),
    .op2_addr(),
    .op1_data(),
    .op2_data()
);

ALU alu (
    .fn(),
    .rs1_data(),
    .rs2_data(),
    .out()
);

INST_MEM inst_name (
    .addr(),
    .data()
);

DATA_MEM data_mem (
    .clk(),
    .write_en(),
    .write_addr(),
    .write_data(),
    .read_addr(),
    .read_data()
);
    
endmodule