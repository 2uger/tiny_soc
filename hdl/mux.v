module mux #(
    parameter integer WIDTH    = 32,
    parameter integer N_INPUTS = 4
) (
    input      [(N_INPUTS * WIDTH) - 1:0] a_i,
    input      [N_INPUTS - 1:0]           sel_i,
    output reg [WIDTH - 1:0]              b_o
);

    always @* begin
        case (sel_i)
            4'b0001: b_o = a_i[(1 * WIDTH) - 1:(0 * WIDTH)];
            4'b0010: b_o = a_i[(2 * WIDTH) - 1:(1 * WIDTH)];
            4'b0100: b_o = a_i[(3 * WIDTH) - 1:(2 * WIDTH)];
            4'b1000: b_o = a_i[(4 * WIDTH) - 1:(3 * WIDTH)];
            default: b_o = 0;
        endcase
    end
endmodule

