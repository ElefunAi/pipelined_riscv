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
        $display("op2 = %d, imm = %d, rs2 = %d, pc = %d, alu_out = %d, wb_sel = %d",
                  cpu.op2, cpu.decoder.opcode, cpu.id_ex_rs2_data, cpu.mem_wb_pc,  cpu.mem_wb_alu_out, cpu.mem_wb_wb_sel);
    end

    initial begin
        clk = 0;
        reset = 1; #5 reset = 0;
    end

    initial #100 $finish;
endmodule