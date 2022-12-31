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
        // $display("pc = %d, cpu.inst=%b, exe_fun=%b, rs1_data=%d, rs2_data=%d, alu_out=%d", cpu.pc, cpu.decoder.opcode, cpu.decoder.exe_fun, cpu.rs1_data, cpu.alu_rs2,  cpu.alu_out);
        $display("inst=%h\npc=%h\nHZD=%b\nrs1_HZD=%b\nrs2_HZD=%b\nrs1_data=%h\nrs2_data=%h\nalu_out=%h\n",cpu.id_inst, cpu.pc, cpu.stall_flg,cpu.id_rs1_data_hazard, cpu.id_rs2_data_hazard, cpu.alu_rs1, cpu.alu_rs2, cpu.exe_alu_out);
    end

    initial begin
        clk = 0;
        reset = 1; #10 reset = 0;
    end

    initial #100 $finish;
endmodule