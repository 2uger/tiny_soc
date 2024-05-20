module demux #(
    parameter integer WIDTH     = 32,
    parameter integer N_OUTPUTS = 4
) (
    input      [WIDTH - 1:0]               a_i,
    input      [N_OUTPUTS - 1:0]           sel_i,
    output reg [(N_OUTPUTS * WIDTH) - 1:0] b_o
);
    integer i;
    always @* begin
        for (i = 0; i < N_OUTPUTS * WIDTH; i = i + 1) begin
            b_o[i] = 1'b0;
        end
        case (sel_i)
            4'b0001: b_o[(1 * WIDTH) - 1:(0 * WIDTH)] = a_i;
            4'b0010: b_o[(2 * WIDTH) - 1:(1 * WIDTH)] = a_i;
            4'b0100: b_o[(3 * WIDTH) - 1:(2 * WIDTH)] = a_i;
            4'b1000: b_o[(4 * WIDTH) - 1:(3 * WIDTH)] = a_i;
            default: b_o = 'b0;
        endcase
    end
endmodule

