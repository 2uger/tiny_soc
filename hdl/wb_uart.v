`timescale 1ns / 1ps

module wb_uart #(
    parameter integer CLK_FREQ     = 100_000_000,
    parameter integer BAUD_RATE    = 115200,
    parameter integer ADDR_TX_DATA = 'h0,
    parameter integer ADDR_RX_DATA = 'h0,
    parameter integer ADDR_STATUS  = 'h0
) (
    input clk,
    input resetn,

    input             wb_cyc_i,
    input             wb_stb_i,
    input             wb_we_i,
    input [31:0]      wb_addr_i,
    input [31:0]      wb_data_i,
    input [3:0]       wb_sel_i,

    output reg        wb_ack_o,
    output            wb_stall_o,
    output reg [31:0] wb_data_o,

    output tx_o,
    input  rx_i
);
    wire [7:0] rx_data;
    wire rx_done;

    wire tx_busy;
    wire tx_done;
    reg tx_enable;

    wire [31:0] status;
    assign status = {29'b0, rx_done, tx_busy, tx_done};

    assign wb_stall_o = 0;

    always @(posedge clk) begin
        wb_ack_o <= wb_stb_i && !wb_ack_o;

        if (wb_stb_i && wb_we_i && (wb_addr_i == ADDR_TX_DATA))
            tx_enable <= 1;
        else
            tx_enable <= 0;
    end

    always @(*) begin
        wb_data_o = 'b0;
        case (wb_addr_i)
            ADDR_RX_DATA: wb_data_o = {24'b0, rx_data};
            ADDR_STATUS:  wb_data_o = status;
            default: wb_data_o = 'b0;
        endcase
    end

    uart_tx #(
        .CLKS_PER_BIT(CLK_FREQ / BAUD_RATE)
    ) i_uart_tx (
        .clk(clk),
        .resetn(resetn),
        .e_i(tx_enable),
        .d_i(wb_data_i[7:0]),
        .tx_o(tx_o),
        .busy_o(tx_busy),
        .done_o(tx_done)
    );

    uart_rx #(
        .CLKS_PER_BIT(CLK_FREQ / BAUD_RATE)
    ) i_uart_rx (
        .clk(clk),
        .resetn(resetn),
        .rx_i(rx_i),
        .d_o(rx_data),
        .done_o(rx_done)
    );

endmodule

module uart_tx #(
    parameter CLKS_PER_BIT = 868
) (
    input clk,
    input resetn,

    input       e_i,
    input [7:0] d_i,

    output wire tx_o,
    output reg busy_o,
    output reg done_o
);
    /* Count time between bits. */
    reg [$clog2(CLKS_PER_BIT):0] timer_cnt;

    reg [2:0] state;
    reg [2:0] next_state;
    localparam IDLE  = 3'b001;
    localparam START = 3'b011;
    localparam DATA  = 3'b010;
    localparam STOP  = 3'b110;

    reg [7:0] data    = 8'b0;
    reg [2:0] bit_idx = 3'b0;
    reg shift_bit_idx;

    always @(posedge clk) begin
        if (!resetn) begin
            state     <= IDLE;
            bit_idx   <= 0;
        end else begin
            state     <= next_state;
            bit_idx   <= shift_bit_idx ? bit_idx + 1 : bit_idx;
            data      <= e_i ? d_i : data;
        end
    end

    assign tx_o = (state == DATA) ? data[bit_idx] : (state == START) ? 0 : 1;

    always @(posedge clk) begin
        if (!resetn) begin
            timer_cnt <= CLKS_PER_BIT;
        end else begin
            case (state)
                IDLE:    timer_cnt <= CLKS_PER_BIT;
                START:   timer_cnt <= (timer_cnt == 1) ? CLKS_PER_BIT : timer_cnt - 1;
                DATA:    timer_cnt <= (timer_cnt == 0) ? CLKS_PER_BIT : timer_cnt - 1;
                STOP:    timer_cnt <= timer_cnt - 1;
                default: timer_cnt <= CLKS_PER_BIT;
            endcase
        end
    end

    always @(*) begin
        busy_o        = 1;
        done_o        = 0;
        shift_bit_idx = 0;
        case (state)
            IDLE: begin
                done_o     = 1;
                busy_o     = 0;
                next_state = e_i ? START : IDLE;
            end
            /* Start bit. */
            START: begin
                next_state = (timer_cnt == 1) ? DATA : START;
            end
            DATA: begin
                shift_bit_idx = (timer_cnt == 0) ? 1 : 0;
                next_state    = (timer_cnt == 0) ? ((bit_idx < 7) ? DATA : STOP) : DATA;
            end
            /* Stop bit. */
            STOP: begin
                next_state = (timer_cnt == 0) ? IDLE : STOP;
            end
            default:
                next_state = IDLE;
        endcase
    end
endmodule

module uart_rx #(
    parameter CLKS_PER_BIT = 868
) (
    input clk,
    input resetn,

    input rx_i,

    output reg [7:0] d_o,
    output reg       busy_o,
    output reg       done_o
);
    reg [$clog2(CLKS_PER_BIT):0] timer_cnt;

    reg [2:0]  state;
    reg [2:0]  next_state;
    localparam IDLE    = 3'b001;
    localparam START   = 3'b011;
    localparam DATA    = 3'b010;
    localparam STOP    = 3'b110;
    localparam CLEANUP = 3'b100;

    reg [2:0] bit_idx;
    reg shift_bit_idx;

    always @ (posedge clk) begin
        if (!resetn) begin
            state     <= IDLE;
            bit_idx   <= 0;
        end else begin
            state     <= next_state;
            bit_idx   <= shift_bit_idx ? bit_idx + 1 : bit_idx;
        end
    end

    always @ (posedge clk) begin
        if (!resetn) begin
            d_o <= 0;
        end else begin
            if ((state == DATA) && shift_bit_idx && (bit_idx != 7)) d_o[bit_idx] <= rx_i;
        end
    end

    always @(posedge clk) begin
        if (!resetn) begin
            timer_cnt <= CLKS_PER_BIT;
        end else begin
            case (state)
                IDLE:    timer_cnt <= CLKS_PER_BIT;
                START:   timer_cnt <= (timer_cnt <= (CLKS_PER_BIT-1) / 2) ? CLKS_PER_BIT : timer_cnt - 1;
                DATA:    timer_cnt <= (timer_cnt == 0) ? CLKS_PER_BIT : timer_cnt - 1;
                STOP:    timer_cnt <= timer_cnt - 1;
                default: timer_cnt <= CLKS_PER_BIT;
            endcase
        end
    end

    always @(*) begin
        busy_o         = 1;
        done_o         = 0;
        shift_bit_idx  = 0;
        case (state)
            IDLE: begin
                busy_o     = 0;
                next_state = (rx_i == 0) ? START : IDLE;
            end
            START: begin
                /* Check in the middle of the byte. */
                next_state = (timer_cnt <= (CLKS_PER_BIT-1) / 2) ? ((rx_i == 0) ? DATA : IDLE) : START;
            end
            DATA: begin
                shift_bit_idx = (timer_cnt == 0) ? 1 : 0;
                next_state    = (timer_cnt == 0) ? ((bit_idx < 7) ? DATA : STOP) : DATA;
            end
            STOP: begin
                /* Wait for stop bit to finish */
                done_o     = 1;
                next_state = (timer_cnt == 0) ? IDLE : STOP;
            end
            default: begin
                next_state     = IDLE;
            end
        endcase
    end
endmodule

