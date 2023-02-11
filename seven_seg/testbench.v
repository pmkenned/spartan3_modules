`default_nettype none
`timescale 1ns / 1ps

module testbench;

    reg clk;
    reg rst;
    wire [3:0] buttons;
    wire [6:0] ss_abcdefg_l;
    wire ss_dp_l;
    wire [3:0] ss_sel_l;

    assign buttons[3] = rst;

    top top(
        .clk(clk),
        .buttons(buttons),
        .ss_abcdefg_l(ss_abcdefg_l),
        .ss_dp_l(ss_dp_l),
        .ss_sel_l(ss_sel_l)
    );

    always #10 clk = ~clk;

    initial begin
        clk = 0;
        rst = 0;

        #10;
        rst = 1;
        #10;
        rst = 0;

        #100;
    end

endmodule
