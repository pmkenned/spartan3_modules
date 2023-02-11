`default_nettype none
`timescale 1ns / 1ps

module testbench;

    reg clk;
    reg rst;
    wire [3:0] buttons;
    wire vga_hs_l;
    wire vga_vs_l;
    wire [2:0] vga_rgb;

    assign buttons[3] = rst;
    assign buttons[2:0] = 'b0;

    top top(
        .clk(clk),
        .buttons(buttons),
        .vga_hs_l(vga_hs_l),
        .vga_vs_l(vga_vs_l),
        .vga_rgb(vga_rgb)
    );

    initial begin
        clk = 0;
        rst = 0;

        @(posedge clk); rst <= 1'b1;
        @(posedge clk); rst <= 1'b0;

        $finish;

    end

endmodule
