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
        // $display("x = %d, rs2 = %d, pc = %d, alu_out = %d, wb_sel = %d, nop_flag = %d, hazard = %d, stall = %d",
        //           cpu.reg_file.reg_file[15], cpu.id_ex_rs2_data, cpu.pc,  cpu.mem_wb_mem_out, cpu.mem_wb_wb_sel, cpu.mem_wb_nop_flag, cpu.have_data_hazard, cpu.pc_mod.stall);
        $display("memout= %d, addr = %d, en = %d. data=%d", cpu.data_mem.read_data, cpu.data_mem.addr, cpu.data_mem.write_en, cpu.data_mem.write_data);
    end

    initial begin
        clk = 0;
        reset = 1; #10 reset = 0;
    end

    initial #100 $finish;
endmodule