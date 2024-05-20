`timescale 1 ns / 1 ps

module testbench();
    reg clk = 1;
    reg resetn = 0;
    wire [7:0] gpio;

    always #5 clk = ~clk;

    initial begin
        repeat (10) @(posedge clk);
        resetn <= 1;
    end

    initial begin
        $dumpfile("testbench.vcd");
        $dumpvars(0, testbench);
        repeat (100000) @(posedge clk);
        $display("TIMEOUT");
        $finish;
    end

    picorv32_wrapper uut (
        .clk(clk),
        .resetn(resetn),
        .gpio_o(gpio)
    );
endmodule

module picorv32_wrapper #(
    parameter integer MEM_WORDS = 128 * 1028
) (
    input clk,
    input resetn,
    inout [7:0] gpio_o
);
    tiny_soc_wb #(
    ) uut (
        .clk(clk),
        .resetn(resetn),
        .gpio_o(gpio_o)
    );

    reg [1023:0] firmware_file;
    initial begin
        firmware_file = "/home/oleg/work/riscv/tiny_soc/firmware/firmware.hex";
        $readmemh(firmware_file, uut.i_memory.mem);
    end

endmodule

