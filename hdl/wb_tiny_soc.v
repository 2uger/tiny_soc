/*
 * Memory map:
 * 0x0000 - 0x8000 - RAM
 * 0x9000 - 0x9008 - UART
 * 0x9100 - 0x9104 - GPIO
 * 0x9200 - 0x9204 - TIMER
 */
module tiny_soc_wb #(
    parameter integer CLK_FREQ  = 100_000_000,
    parameter integer BAUD_RATE = 115200,

    /* CPU parameters. */
    parameter integer        MEM_WORDS      = 'h2000,
    parameter         [31:0] STACKADDR      = 4 * MEM_WORDS,
    parameter         [31:0] PROGADDR_RESET = 32'h0000_0000,
    parameter         [31:0] PROGADDR_IRQ   = 32'h0000_0010,

    parameter integer N_SLAVES = 'h4,

    /* MMIO Uart. */
    parameter integer ADDR_UART_TX_DATA  = 32'h0000_9000,
    parameter integer ADDR_UART_RX_DATA  = 32'h0000_9004,
    parameter integer ADDR_UART_STATUS   = 32'h0000_9008,

    /* MMIO Gpio. */
    parameter integer ADDR_GPIO_CTRL     = 32'h0000_9100,
    parameter integer ADDR_GPIO_VAL      = 32'h0000_9104,

    /* MMIO Timer. */
    parameter integer ADDR_TIMER_CTRL    = 32'h0000_9200,
    parameter integer ADDR_TIMER_CNT     = 32'h0000_9204,

    /* Wishbone interconnect select signal. */
    parameter integer WB_SEL_RAM   = 4'b0001,
    parameter integer WB_SEL_UART  = 4'b0010,
    parameter integer WB_SEL_GPIO  = 4'b0100,
    parameter integer WB_SEL_TIMER = 4'b1000
) (
    input clk,
    input resetn,

    /* UART */
    input  ser_rx_i,
    output wire ser_tx_o,

    /* GPIO */
    inout [7:0] gpio_o
);
    /* CPU wishbone interface. */
    wire cpu_wbm_cyc_o;
    wire cpu_wbm_stb_o;
    wire cpu_wbm_we_o;
    wire [31:0] cpu_wbm_addr_o;
    wire [31:0] cpu_wbm_data_o;
    wire [3:0] cpu_wbm_sel_o;

    wire [31:0] cpu_wbm_data_i;
    wire cpu_wbm_ack_i;

    reg [31:0] irq;

    /* Wishbone master interface signals. */
    wire [N_SLAVES - 1:0] inter_wbm_cyc_o;
    wire [N_SLAVES - 1:0] inter_wbm_stb_o;
    wire [N_SLAVES - 1:0] inter_wbm_we_o;
    wire [(N_SLAVES * 32) - 1:0] inter_wbm_addr_o;
    wire [(N_SLAVES * 32) - 1:0] inter_wbm_data_o;
    wire [(N_SLAVES * 4) - 1:0] inter_wbm_sel_o;
    wire [N_SLAVES - 1:0] inter_wbm_ack_i;
    wire [(N_SLAVES * 32) - 1:0] inter_wbm_data_i;

    /* Timer signals. */
    wire timer_irq;

    always @(posedge clk) begin
        irq <= {28'b0, timer_irq, 3'b0};
    end

    picorv32_wb #(
        .STACKADDR(STACKADDR),
        .PROGADDR_RESET(PROGADDR_RESET),
        .PROGADDR_IRQ(PROGADDR_IRQ),
        .COMPRESSED_ISA(1),
        .ENABLE_MUL(1),
        .ENABLE_DIV(1),
        .ENABLE_IRQ(1),
        .ENABLE_IRQ_QREGS(0)
    ) i_picorv32 (
        .wb_clk_i(clk),
        .wb_rst_i(~resetn),

        .wbm_cyc_o(cpu_wbm_cyc_o),
        .wbm_stb_o(cpu_wbm_stb_o),
        .wbm_we_o(cpu_wbm_we_o),
        .wbm_adr_o(cpu_wbm_addr_o),
        .wbm_dat_o(cpu_wbm_data_o),
        .wbm_sel_o(cpu_wbm_sel_o),

        .wbm_ack_i(cpu_wbm_ack_i),
        .wbm_dat_i(cpu_wbm_data_i),

        .irq(irq)
    );

    wb_interconnect #(
        .N_SLAVES(N_SLAVES),
        .ADDR_END_RAM(4 * MEM_WORDS),
        .ADDR_BASE_UART(ADDR_UART_TX_DATA),
        .ADDR_END_UART(ADDR_UART_STATUS),
        .ADDR_BASE_GPIO(ADDR_GPIO_CTRL),
        .ADDR_END_GPIO(ADDR_GPIO_VAL),
        .ADDR_BASE_TIMER(ADDR_TIMER_CTRL),
        .ADDR_END_TIMER(ADDR_TIMER_CNT),
        .WB_SEL_RAM(WB_SEL_RAM),
        .WB_SEL_UART(WB_SEL_UART),
        .WB_SEL_GPIO(WB_SEL_GPIO),
        .WB_SEL_TIMER(WB_SEL_TIMER)
    ) i_wb_interconnect (
        .wbs_cyc_i(cpu_wbm_cyc_o),
        .wbs_stb_i(cpu_wbm_stb_o),
        .wbs_we_i(cpu_wbm_we_o),
        .wbs_addr_i(cpu_wbm_addr_o),
        .wbs_data_i(cpu_wbm_data_o),
        .wbs_sel_i(cpu_wbm_sel_o),

        .wbs_ack_o(cpu_wbm_ack_i),
        .wbs_data_o(cpu_wbm_data_i),

        .wbm_cyc_o(inter_wbm_cyc_o),
        .wbm_stb_o(inter_wbm_stb_o),
        .wbm_we_o(inter_wbm_we_o),
        .wbm_addr_o(inter_wbm_addr_o),
        .wbm_data_o(inter_wbm_data_o),
        .wbm_sel_o(inter_wbm_sel_o),

        .wbm_ack_i(inter_wbm_ack_i),
        .wbm_data_i(inter_wbm_data_i)
    );

    wb_memory #(
        .WORDS(MEM_WORDS)
    ) i_memory (
        .clk(clk),

        .wb_cyc_i(inter_wbm_cyc_o[$clog2(WB_SEL_RAM)]),
        .wb_stb_i(inter_wbm_stb_o[$clog2(WB_SEL_RAM)]),
        .wb_we_i(inter_wbm_we_o[$clog2(WB_SEL_RAM)]),
        .wb_addr_i(inter_wbm_addr_o[(($clog2(WB_SEL_RAM) + 1) * 32) - 1:($clog2(WB_SEL_RAM) * 32)]),
        .wb_data_i(inter_wbm_data_o[(($clog2(WB_SEL_RAM) + 1) * 32) - 1:($clog2(WB_SEL_RAM) * 32)]),
        .wb_sel_i(inter_wbm_sel_o[(($clog2(WB_SEL_RAM) + 1) * 4) - 1:($clog2(WB_SEL_RAM) * 4)]),

        .wb_ack_o(inter_wbm_ack_i[$clog2(WB_SEL_RAM)]),
        .wb_data_o(inter_wbm_data_i[(($clog2(WB_SEL_RAM) + 1) * 32) - 1:($clog2(WB_SEL_RAM) * 32)])
    );

    wb_uart #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .ADDR_TX_DATA(ADDR_UART_TX_DATA),
        .ADDR_RX_DATA(ADDR_UART_RX_DATA),
        .ADDR_STATUS(ADDR_UART_STATUS)
    ) i_wb_uart (
        .clk(clk),
        .resetn(resetn),

        .wb_cyc_i(inter_wbm_cyc_o[$clog2(WB_SEL_UART)]),
        .wb_stb_i(inter_wbm_stb_o[$clog2(WB_SEL_UART)]),
        .wb_we_i(inter_wbm_we_o[$clog2(WB_SEL_UART)]),
        .wb_addr_i(inter_wbm_addr_o[(($clog2(WB_SEL_UART) + 1) * 32) - 1:($clog2(WB_SEL_UART) * 32)]),
        .wb_data_i(inter_wbm_data_o[(($clog2(WB_SEL_UART) + 1) * 32) - 1:($clog2(WB_SEL_UART) * 32)]),
        .wb_sel_i(inter_wbm_sel_o[(($clog2(WB_SEL_UART) + 1) * 4) - 1:($clog2(WB_SEL_UART) * 4)]),

        .wb_ack_o(inter_wbm_ack_i[$clog2(WB_SEL_UART)]),
        .wb_data_o(inter_wbm_data_i[(($clog2(WB_SEL_UART) + 1) * 32) - 1:($clog2(WB_SEL_UART) * 32)]),

        .tx_o(ser_tx_o),
        .rx_i(ser_rx_i)
    );

    wb_gpio #(
        .ADDR_CTRL(ADDR_GPIO_CTRL),
        .ADDR_VAL(ADDR_GPIO_VAL)
    ) i_wb_gpio (
        .clk(clk),
        .resetn(resetn),

        .wb_cyc_i(inter_wbm_cyc_o[$clog2(WB_SEL_GPIO)]),
        .wb_stb_i(inter_wbm_stb_o[$clog2(WB_SEL_GPIO)]),
        .wb_we_i(inter_wbm_we_o[$clog2(WB_SEL_GPIO)]),
        .wb_addr_i(inter_wbm_addr_o[(($clog2(WB_SEL_GPIO) + 1) * 32) - 1:($clog2(WB_SEL_GPIO) * 32)]),
        .wb_data_i(inter_wbm_data_o[(($clog2(WB_SEL_GPIO) + 1) * 32) - 1:($clog2(WB_SEL_GPIO) * 32)]),
        .wb_sel_i(inter_wbm_sel_o[(($clog2(WB_SEL_GPIO) + 1) * 4) - 1:($clog2(WB_SEL_GPIO) * 4)]),

        .wb_ack_o(inter_wbm_ack_i[$clog2(WB_SEL_GPIO)]),
        .wb_data_o(inter_wbm_data_i[(($clog2(WB_SEL_GPIO) + 1) * 32) - 1:($clog2(WB_SEL_GPIO) * 32)]),

        .gpio_o(gpio_o)
    );

    wb_timer #(
        .ADDR_CTRL(ADDR_TIMER_CTRL),
        .ADDR_CNT(ADDR_TIMER_CNT)
    ) i_wb_timer (
        .clk(clk),
        .resetn(resetn),

        .wb_cyc_i(inter_wbm_cyc_o[$clog2(WB_SEL_TIMER)]),
        .wb_stb_i(inter_wbm_stb_o[$clog2(WB_SEL_TIMER)]),
        .wb_we_i(inter_wbm_we_o[$clog2(WB_SEL_TIMER)]),
        .wb_addr_i(inter_wbm_addr_o[(($clog2(WB_SEL_TIMER) + 1) * 32) - 1:($clog2(WB_SEL_TIMER) * 32)]),
        .wb_data_i(inter_wbm_data_o[(($clog2(WB_SEL_TIMER) + 1) * 32) - 1:($clog2(WB_SEL_TIMER) * 32)]),
        .wb_sel_i(inter_wbm_sel_o[(($clog2(WB_SEL_TIMER) + 1) * 4) - 1:($clog2(WB_SEL_TIMER) * 4)]),

        .wb_ack_o(inter_wbm_ack_i[$clog2(WB_SEL_TIMER)]),
        .wb_data_o(inter_wbm_data_i[(($clog2(WB_SEL_TIMER) + 1) * 32) - 1:($clog2(WB_SEL_TIMER) * 32)]),

        .irq_o(timer_irq)
    );

endmodule
