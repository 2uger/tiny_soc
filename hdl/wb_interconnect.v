module wb_interconnect #(
    parameter N_SLAVES = 4,

    parameter ADDR_END_RAM    = 'h2000,
    parameter ADDR_BASE_UART  = 'h9000,
    parameter ADDR_END_UART   = 'h9008,
    parameter ADDR_BASE_GPIO  = 'h9100,
    parameter ADDR_END_GPIO   = 'h9104,
    parameter ADDR_BASE_TIMER = 'h9200,
    parameter ADDR_END_TIMER  = 'h9204,

    parameter WB_SEL_RAM   = 4'b0001,
    parameter WB_SEL_UART  = 4'b0010,
    parameter WB_SEL_GPIO  = 4'b0100,
    parameter WB_SEL_TIMER = 4'b1000
) (
    input clk,

    /* Wishbone slave interface. */
    input         wbs_cyc_i,
    input         wbs_stb_i,
    input         wbs_we_i,
    input  [31:0] wbs_addr_i,
    input  [31:0] wbs_data_i,
    input  [3:0]  wbs_sel_i,
    output [31:0] wbs_data_o,
    output        wbs_ack_o,
    output        wbs_stall_o,

    /* Wishbone master interface. */
    output [N_SLAVES - 1:0]        wbm_cyc_o,
    output [N_SLAVES - 1:0]        wbm_stb_o,
    output [N_SLAVES - 1:0]        wbm_we_o,
    output [(N_SLAVES * 32) - 1:0] wbm_addr_o,
    output [(N_SLAVES * 32) - 1:0] wbm_data_o,
    output [(N_SLAVES * 4) - 1:0]  wbm_sel_o,
    input  [N_SLAVES - 1:0]        wbm_ack_i,
    input  [N_SLAVES - 1:0]        wbm_stall_i,
    input  [(N_SLAVES * 32) - 1:0] wbm_data_i
);
    reg [N_SLAVES - 1:0] sel;

    always @(*) begin
        if      (wbs_addr_i <= ADDR_END_RAM)                                        sel = WB_SEL_RAM;
        else if ((wbs_addr_i >= ADDR_BASE_UART)  && (wbs_addr_i <= ADDR_END_UART))  sel = WB_SEL_UART;
        else if ((wbs_addr_i >= ADDR_BASE_GPIO)  && (wbs_addr_i <= ADDR_END_GPIO))  sel = WB_SEL_GPIO;
        else if ((wbs_addr_i >= ADDR_BASE_TIMER) && (wbs_addr_i <= ADDR_END_TIMER)) sel = WB_SEL_TIMER;
        else sel = 0;
    end

    demux #(.WIDTH(1),  .N_OUTPUTS(N_SLAVES)) i_demux_wb_cyc  (.a_i(wbs_cyc_i),  .sel_i(sel), .b_o(wbm_cyc_o));
    demux #(.WIDTH(1),  .N_OUTPUTS(N_SLAVES)) i_demux_wb_stb  (.a_i(wbs_stb_i),  .sel_i(sel), .b_o(wbm_stb_o));
    demux #(.WIDTH(1),  .N_OUTPUTS(N_SLAVES)) i_demux_wb_we   (.a_i(wbs_we_i),   .sel_i(sel), .b_o(wbm_we_o));
    demux #(.WIDTH(32), .N_OUTPUTS(N_SLAVES)) i_demux_wb_addr (.a_i(wbs_addr_i), .sel_i(sel), .b_o(wbm_addr_o));
    demux #(.WIDTH(32), .N_OUTPUTS(N_SLAVES)) i_demux_wb_data (.a_i(wbs_data_i), .sel_i(sel), .b_o(wbm_data_o));
    demux #(.WIDTH(4),  .N_OUTPUTS(N_SLAVES)) i_demux_wb_sel  (.a_i(wbs_sel_i),  .sel_i(sel), .b_o(wbm_sel_o));

    mux #(.WIDTH(1),  .N_INPUTS(4)) i_mux_wb_ack   (.a_i(wbm_ack_i),   .sel_i(sel), .b_o(wbs_ack_o));
    mux #(.WIDTH(1),  .N_INPUTS(4)) i_mux_wb_stall (.a_i(wbm_stall_i), .sel_i(sel), .b_o(wbs_stall_o));
    mux #(.WIDTH(32), .N_INPUTS(4)) i_mux_wb_data  (.a_i(wbm_data_i),  .sel_i(sel), .b_o(wbs_data_o));

endmodule
