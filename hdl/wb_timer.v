`timescale 1ns / 1ps

module wb_timer # (
    parameter ADDR_CTRL       = 'h0,
    parameter ADDR_CNT        = 'h0,
    parameter CTRL_CNT_WIDTH  = 30,
    parameter CTRL_ENABLE_IRQ = 30,
    parameter CTRL_ENABLE_CNT = 31
) (
    input  clk,
    input  resetn,

    input             wb_cyc_i,
    input             wb_stb_i,
    input             wb_we_i,
    input [31:0]      wb_addr_i,
    input [31:0]      wb_data_i,
    input [3:0]       wb_sel_i,

    output reg        wb_ack_o,
    output            wb_stall_o,
    output reg [31:0] wb_data_o,

    output             irq_o
);
    reg [31:0] reg_cnt;
    reg [31:0] reg_ctrl;

    assign irq_o = ((reg_ctrl[CTRL_ENABLE_IRQ] == 1'b1)
                    && (reg_ctrl[CTRL_ENABLE_CNT] == 1'b1)
                    && (reg_cnt >= reg_ctrl[CTRL_CNT_WIDTH - 1:0])) ? 1'b1 : 1'b0;

    assign wb_stall_o = 0;

    always @(posedge clk) begin
        if (!resetn) begin
            reg_cnt  <= 32'b0;
            reg_ctrl <= 32'b0;
            wb_ack_o <= 1'b0;
        end else begin
            reg_cnt <= (reg_ctrl[CTRL_ENABLE_CNT] == 1'b0) ? 3 :
                       (reg_cnt >= reg_ctrl[CTRL_CNT_WIDTH - 1:0]) ? 32'b0 :
                       (reg_cnt + 1);

            wb_ack_o <= wb_stb_i && !wb_ack_o;

            if (wb_stb_i && wb_we_i && (wb_addr_i == ADDR_CTRL)) begin
                if (wb_sel_i[0]) reg_ctrl[7:0]   <= wb_data_i[7:0];
                if (wb_sel_i[1]) reg_ctrl[15:8]  <= wb_data_i[15:8];
                if (wb_sel_i[2]) reg_ctrl[23:16] <= wb_data_i[23:16];
                if (wb_sel_i[3]) reg_ctrl[31:24] <= wb_data_i[31:24];
            end
        end
    end

    always @(*) begin
        case (wb_addr_i)
            ADDR_CTRL: wb_data_o = reg_ctrl;
            ADDR_CNT: wb_data_o = reg_cnt;
            default: wb_data_o = 'b0;
        endcase
    end
endmodule

