// memoryモジュール

module DATA_MEM (
    input wire clk,
    input wire write_en,
    input wire [31:0] write_addr,
    input wire [31:0] write_data,
    input wire [31:0] read_addr,
    output wire [31:0] read_data
);
    // 4byte*4096行=16384byte=16KB
    reg [31:0] rom [0:4095];
    
    always @(posedge clk) begin
        // 書き込んでいないメモリにアクセスすることは想定しない。
        if (write_en) begin
            rom[write_addr] <= write_data;
        end
    end

    assign read_data = rom[read_addr];
endmodule