`default_nettype none
`timescale 1ns / 1ps

`include "vga.vh"

module vga_driver(
    input wire clk,
    input wire rst,
    output wire [8:0] vga_row,
    output wire [9:0] vga_col,
    output wire vga_display,
    output wire vga_hs_l,
    output wire vga_vs_l
);
    wire clk_25MHz;
    ff_ar clk_25MHz_ff(.clk(clk), .rst(rst), .d(~clk_25MHz), .q(clk_25MHz));

    wire [9:0] clk_cnt_q;
    wire [9:0] clk_cnt_n;
    wire [9:0] row_cnt_q;
    wire [9:0] row_cnt_n;

    assign clk_cnt_n = (clk_cnt_q == `VGA_HTOTAL-1) ? 10'b0 : clk_cnt_q + 10'b1;
    assign row_cnt_n = (row_cnt_q == `VGA_VTOTAL-1) ? 10'b0 : (clk_cnt_q == `VGA_HTOTAL-1) ? row_cnt_q + 10'b1 : row_cnt_q;

    // TODO: should these widths be only 10?
    ff_ar #(.W(10)) clk_cnt_ff(.clk(clk_25MHz), .rst(rst), .d(clk_cnt_n), .q(clk_cnt_q));
    ff_ar #(.W(10)) row_cnt_ff(.clk(clk_25MHz), .rst(rst), .d(row_cnt_n), .q(row_cnt_q));

    // outputs

    assign vga_display = ((clk_cnt_q < `VGA_COLS) && (row_cnt_q < `VGA_ROWS)) ? 1'b1 : 1'b0;
    assign vga_col = clk_cnt_q;
    assign vga_row = row_cnt_q[8:0];

    assign vga_hs_l = ((clk_cnt_q >= `VGA_START_HS) && (clk_cnt_q < `VGA_END_HS)) ? 1'b0 : 1'b1;
    assign vga_vs_l = ((row_cnt_q >= `VGA_START_VS) && (row_cnt_q < `VGA_END_VS)) ? 1'b0 : 1'b1;

endmodule

