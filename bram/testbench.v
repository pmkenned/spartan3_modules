`default_nettype none
`timescale 1ns / 1ps

module testbench;

    // Inputs
    reg clk;
    reg rst;

    reg [7:0] switches;
    wire [3:0] buttons;
    wire [7:0] leds;
    wire [6:0] ss_abcdefg_l;
    wire ss_dp_l;
    wire [3:0] ss_sel_l;

    assign buttons[3] = rst;
    assign buttons[2:0] = 3'b0;

    top top (
        .clk(clk),
        .switches(switches),
        .buttons(buttons),
        .leds(leds),
        .ss_abcdefg_l(ss_abcdefg_l),
        .ss_dp_l(ss_dp_l),
        .ss_sel_l(ss_sel_l)
    );

    always #10 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        switches = 'b0;

        // Wait 100 ns for global reset to finish
        #100;

        @(posedge clk) rst <= 1'b1;
        @(posedge clk) rst <= 1'b0;
        repeat (500000) @(posedge clk);

        $finish;
        
    end
      
endmodule
