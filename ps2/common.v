`default_nettype none
`timescale 1ns / 1ps

`include "common.vh"

module ff_ar #(
    parameter W=1,
    parameter RESET_VAL=0
)(
    input wire clk,
    input wire rst,
    input wire [W-1:0] d,
    output reg [W-1:0] q
);

    always @(posedge clk, posedge rst) begin
        if (rst) q <= RESET_VAL;
        else     q <= d;
    end

endmodule

module counter
#(
    parameter W=8,
    parameter START_VAL=0,
    parameter FINAL_VAL=2**W-1,
    parameter INC_VAL=1,
    parameter DIR=`DIR_UP,
    parameter SATURATE=0
)
(
    input wire clk,
    input wire rst,
    input wire x,
    input wire clr,
    output wire [W-1:0] cnt
);

    wire [W-1:0] next_num;
    generate
        if (DIR == `DIR_UP) begin
            assign next_num = cnt + 'b1;
        end else begin
            assign next_num = cnt - 'b1;
        end
    endgenerate

    wire [W-1:0] cnt_n;
    assign cnt_n = clr ? START_VAL : (x ? ((cnt == FINAL_VAL) ? (SATURATE ? cnt : START_VAL) : next_num) : cnt);

    ff_ar #(.W(W), .RESET_VAL(START_VAL)) counter_ff(.clk(clk), .rst(rst), .d(cnt_n), .q(cnt));

endmodule

module shift_register
#(
    parameter W=8,
    parameter SHIFT_W=1,
    parameter RESET_VAL=0,
    parameter SHIFT_DIR=`SHIFT_DIR_LEFT
)
(
    input wire clk,
    input wire rst,
    input wire en,
    input wire [SHIFT_W-1:0] d,
    output wire [W-1:0] q
);

    wire [W-1:0] q_n;
    generate
        if (SHIFT_DIR == `SHIFT_DIR_RIGHT) begin
            assign q_n = en ? {d, q[W-1:SHIFT_W]} : q;
        end else begin
            assign q_n = en ? {q[W-1-SHIFT_W:0], d} : q;
        end
    endgenerate

    ff_ar #(.W(W), .RESET_VAL(RESET_VAL)) shift_ff(.clk(clk), .rst(rst), .d(q_n), .q(q));

endmodule
