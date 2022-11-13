// memoryモジュール
module inst_mem (
    input wire clk,
    input wire [31:0] addr,
    output reg [31:0] read_data
);
    // 1byte*16384行=16384byte=16KB
    reg [7:0] rom [0:16383];

    initial begin
        $readmemh("./src/hex/test1.hex", rom);
    end
    
    always @(posedge clk) begin
        read_data <= {rom[addr+3], rom[addr+2], rom[addr+1], rom[addr]};
    end
endmodule