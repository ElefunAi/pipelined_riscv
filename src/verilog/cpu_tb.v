`timescale 1 us/ 100 ns
`default_nettype none

`include "define.vh"

module cpu_tb;
    parameter HALFCYCLE = 0.5; //500ns
    parameter CYCLE = 1;
    reg clk, reset;

    CPU cpu(.clk(clk), .reset(reset));

    always begin 
        #HALFCYCLE clk = ~clk;
        #HALFCYCLE clk = ~clk;
        //$display("alu_out = %d, memout= %d, addr = %d, en = %d,%d. data=%d, rs2_data = %d, hazard = %D", cpu.alu_out, cpu.data_mem.read_data, cpu.data_mem.addr, cpu.mem_wen, cpu.data_mem.write_en, cpu.data_mem.write_data, cpu.rs2_data, cpu.have_data_hazard);
        $display("pc = %d, cpu.imm=%b, rs1_data=%d, rs2_data=%d, write_val=%d, write_addr=%d", cpu.pc, cpu.if_inst_out, cpu.alu_rs2, cpu.alu_rs2, cpu.wb_write_value, cpu.write_addr);
    end

    initial begin
        clk = 0;
        reset = 1; #10 reset = 0;
    end

    initial #100 $finish;
endmodule