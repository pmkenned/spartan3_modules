`default_nettype none
`timescale 1ns / 1ps

module testbench;

    reg clk;
    reg rst;
    wire [8:0] vga_row;
    wire [9:0] vga_col;
    wire vga_display;
    wire vga_hs_l;
    wire vga_vs_l;

    vga_driver vga_driver(
        .clk(clk),
        .rst(rst),
        .vga_row(vga_row),
        .vga_col(vga_col),
        .vga_display(vga_display),
        .vga_hs_l(vga_hs_l),
        .vga_vs_l(vga_vs_l)
    );

    initial begin
        clk = 0;
        rst = 0;

        @(posedge clk); rst <= 1'b1;
        @(posedge clk); rst <= 1'b0;

        $finish;

    end

endmodule
