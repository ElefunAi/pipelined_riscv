module MEM (
    input wire clk,
    input wire write_en,
    input wire [31:0] addr,
    input wire [31:0] write_data,
    output wire [31:0] inst,
    output wire [31:0] read_data
);
    // 1byte*16384行=16384byte=16KB
    reg [7:0] rom [0:2**14-1];
    reg [31:0] read_reg;

    initial begin
        $readmemh("build/isa/rv32ui-p-xori.hex", rom);
    end
    
    always @(posedge clk) begin
        read_reg <= {rom[addr+3], rom[addr+2], rom[addr+1], rom[addr+0]};
        if (write_en) begin
            rom[addr+3] <= write_data[31:24];
            rom[addr+2] <= write_data[23:16];
            rom[addr+1] <= write_data[15:8];
            rom[addr+0] <= write_data[7:0];
        end
    end

    assign inst = {rom[addr+3], rom[addr+2], rom[addr+1], rom[addr]};
    assign read_data = read_reg;
endmodule