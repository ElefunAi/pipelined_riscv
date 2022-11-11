// memoryモジュール

module DATA_MEM (
    input wire clk,
    input wire write_en,
    input wire [31:0] addr, // 読み込みと書込みが同時に起こらないため、共有
    input wire [31:0] write_data,
    output wire [31:0] read_data
);
    // 4byte*4096行=16384byte=16KB
    reg [31:0] rom [0:4095];
    
    always @(posedge clk) begin
        // 書き込んでいないメモリにアクセスすることは想定しない。
        if (write_en) begin
            rom[addr] <= write_data;
        end
    end

    assign read_data = rom[addr];
endmodule