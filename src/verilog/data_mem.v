// memoryモジュール
module DATA_MEM (
    input wire clk,
    input wire write_en,
    input wire [31:0] addr,
    input wire [31:0] write_data,
    output reg [31:0] read_data
);
    // 4byte*4096行=16384byte=16KB
    reg [31:0] rom [0:2**12-1];
    reg [31:0] read_reg;
    
    always @(posedge clk) begin
        read_reg <= rom[addr[11:0]];
        if (write_en) begin
            rom[addr[11:0]] <= write_data;
        end
    end

    assign read_data = read_reg;
    // reg [31:0] rom [0:4095];
    
    // always @(posedge clk) begin
    //     // 書き込んでいないメモリにアクセスすることは想定しない。<=手間かからないのになぜ？
    //     if (write_en) begin
    //         rom[addr] <= write_data;
    //     end
    // end

    // これだと書き込み結果が即反映されるので違和感がある
    // 読み出し結果が変わるのは次に参照した時では？
    // assign read_data = rom[addr];
endmodule