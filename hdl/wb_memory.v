module wb_memory #(
    parameter integer WORDS = 'h2000
) (
    input clk,

    /* Wishbone slave interface. */
    input             wb_cyc_i,
    input             wb_stb_i,
    input             wb_we_i,
    input [31:0]      wb_addr_i,
    input [31:0]      wb_data_i,
    input [3:0]       wb_sel_i,

    output reg        wb_ack_o,
    output            wb_stall_o,
    output reg [31:0] wb_data_o
);
    reg [31:0] mem[0:WORDS-1];

    reg [1023:0] firmware_file;
`ifndef VERILATOR 
    initial begin
        firmware_file = "/home/oleg/work/riscv/tiny_soc/firmware/firmware.hex";
        $readmemh(firmware_file, mem);
    end
`endif

    wire [12:0] mem_addr;
    assign mem_addr = wb_addr_i[14:2];

`ifdef VERILATOR
    initial begin
        mem[0] = 32'haa55;
    end
`endif

    assign wb_stall_o = 0;

    always @(posedge clk) begin
        wb_ack_o  <= wb_stb_i && !wb_ack_o;
        wb_data_o <= mem[mem_addr];
        if (wb_stb_i && wb_we_i && (wb_addr_i < (4 * WORDS))) begin
            if (wb_sel_i[0]) mem[mem_addr][7:0]   <= wb_data_i[7:0];
            if (wb_sel_i[1]) mem[mem_addr][15:8]  <= wb_data_i[15:8];
            if (wb_sel_i[2]) mem[mem_addr][23:16] <= wb_data_i[23:16];
            if (wb_sel_i[3]) mem[mem_addr][31:24] <= wb_data_i[31:24];
        end
    end
endmodule

