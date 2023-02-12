`timescale 1ns / 1ps
`default_nettype none

`define assert(condition) if (!(condition)) begin $display("ASSERTION FAILED"); $stop; end

module testbench;

    reg clk;
    reg rst;
    wire [7:0] leds;
    reg [3:0] buttons;
    reg [7:0] switches;
    reg [2:0] xb_buttons;
    wire [35:21] gpio;

    assign buttons[3] = rst;

    top top(
        .clk(clk),
        .rst(rst)
        .leds(leds),
        .buttons(buttons),
        .switches(switches),
        .xb_buttons(xb_buttons),
        .gpio(gpio)
    );

    always begin
        #10 clk = ~clk;
    end

    initial begin
        clk = 'b0;

        // toggle reset
        @(posedge clk) rst <= 'b1;
        @(posedge clk) rst <= 'b0;

        $finish;
    end

endmodule
