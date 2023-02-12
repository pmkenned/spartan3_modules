`timescale 1ns / 1ps
`default_nettype none

`define assert(condition) if (!(condition)) begin $display("ASSERTION FAILED"); $stop; end

module testbench;

    reg clk;
    reg rst;
    wire [7:0] leds;
    wire [3:0] buttons;
    reg [7:0] switches;
    reg [2:0] xb_buttons;
    wire [35:21] gpio;

    assign buttons[3] = rst;

    wire sck;
    wire miso;
    wire mosi;
    wire cs_l;

    assign sck  = gpio[21];
    assign gpio[23] = miso;
    assign mosi = gpio[25];
    assign cs_l = gpio[27];

    top top(
        .clk(clk),
        .leds(leds),
        .buttons(buttons),
        .switches(switches),
        .xb_buttons(xb_buttons),
        .gpio(gpio)
    );

    spi_flash spi_flash(
        .sck(sck),
        .miso(miso),
        .mosi(mosi),
        .cs_l(cs_l)
    );

    always begin
        #10 clk = ~clk;
    end

    initial begin
        clk = 'b0;
        rst = 'b0;
        switches = 'b0;
        xb_buttons = 'b0;

        // toggle reset
        @(posedge clk) rst <= 'b1;
        @(posedge clk) rst <= 'b0;

        // init sequence
        // 48*5 (transmit) + 3*7 + 48*2 (receive), rounding up: 400
        repeat(400) @(posedge clk);

        // write block
        @(posedge clk) xb_buttons[0] <= 1'b1;
        @(posedge clk) xb_buttons[0] <= 1'b0;
        repeat(4200) @(posedge clk);

        // read block
        @(posedge clk) xb_buttons[1] <= 1'b1;
        @(posedge clk) xb_buttons[1] <= 1'b0;
        repeat(4200) @(posedge clk);

        $finish;
    end

endmodule
