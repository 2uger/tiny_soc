`timescale 1ns / 1ps

module wb_gpio #(
    parameter integer ADDR_CTRL = 'h0,
    parameter integer ADDR_VAL  = 'h0,
    parameter integer GPIO_NUM  = 'h8
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

    inout [7:0] gpio_o
);
    reg [31:0] reg_ctrl;
    reg [31:0] reg_val;

    reg [7:0] gpio_inout;
    integer i;
    always @(*) begin
        for (i = 0; i < GPIO_NUM; i = i + 1) begin
            gpio_inout[i] = (reg_ctrl[i] == 1) ? reg_val[i] : 1'bz;
        end
    end

    assign gpio_o = gpio_inout;

    assign wb_stall_o = 0;

    always @(posedge clk, negedge resetn) begin
        if (!resetn) begin
            reg_ctrl <= 32'b0;
            reg_val  <= 32'b0;
            wb_ack_o <= 0;
        end else begin
            wb_ack_o <= wb_stb_i && !wb_ack_o;

            if (wb_stb_i && wb_we_i) begin
                case (wb_addr_i)
                    ADDR_CTRL: begin
                        if (wb_sel_i[0]) reg_ctrl[7:0]   <= wb_data_i[7:0];
                        if (wb_sel_i[1]) reg_ctrl[15:8]  <= wb_data_i[15:8];
                        if (wb_sel_i[2]) reg_ctrl[23:16] <= wb_data_i[23:16];
                        if (wb_sel_i[3]) reg_ctrl[31:24] <= wb_data_i[31:24];
                    end
                    ADDR_VAL: begin
                        if (wb_sel_i[0]) begin
                            for (i = 0; i < 8; i = i + 1) begin
                                if (reg_ctrl[i] == 1) reg_val[i] <= wb_data_i[i];
                                else reg_val[i] <= gpio_o[i];
                            end
                        end
                    end
                endcase
            end
        end
    end

    always @(*) begin
        case (wb_addr_i)
            ADDR_CTRL: wb_data_o = reg_ctrl;
            ADDR_VAL: begin
                for (i = 0; i < GPIO_NUM; i = i + 1) begin
                    if (reg_val[i] == 1) wb_data_o[i] = 1;
                    else wb_data_o[i] = 0;
                end
            end
            default: wb_data_o = 'b0;
        endcase
    end

endmodule

