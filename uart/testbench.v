`default_nettype none
`timescale 1ns / 1ps

module testbench;

    reg clk;
    reg rst;
    wire [3:0] buttons;
    reg [7:0] switches;

    reg rs232_rxd;
    wire rs232_txd;
    reg rs232_rxd_a;
    wire rs232_txd_a;

    assign buttons[3] = rst;
    assign buttons[2:0] = 'b0;

    top top(
        .clk(clk),
        .buttons(buttons),
        .switches(switches),
        .rs232_rxd(rs232_rxd),
        .rs232_txd(rs232_txd),
        .rs232_rxd_a(rs232_rxd_a),
        .rs232_txd_a(rs232_rxd_a)
    );

    always #10 clk = ~clk;

    initial begin
        clk = 0;
        rst = 0;
        buttons = 0;
        switches = 0;
        rs232_rxd = 1;
        rs232_rxd_a = 1;

        @(posedge clk); rst <= 1'b1;
        @(posedge clk); rst <= 1'b0;

        repeat(10) @(posedge clk);

        $finish;

    end

endmodule
