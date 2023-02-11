`default_nettype none
`timescale 1ns / 1ps

`define "common.vh"

module testbench;

    reg clk;
    reg rst;

    reg d1;
    wire q1;
    ff_ar #(.W(1), .RESET_VAL(0)) ff1(.clk(clk), .rst(rst), .d(d1), .q(q1));

    reg [1:0] d2;
    wire [1:0] q2;
    ff_ar #(.W(2), .RESET_VAL(0)) ff2(.clk(clk), .rst(rst), .d(d2), .q(q2));

    always #10 clk = ~clk;

    initial begin
        clk = 0;
        rst = 0;
        d1 = 0;
        d2 = 0;

        #100;

        rst <= 1'b1;
        #10
        rst <= 1'b0;

        @(posedge clk) d1 <= 'b1;
        @(posedge clk) d1 <= 'b0;
        @(posedge clk) d2 <= 'b01;
        @(posedge clk) d2 <= 'b10;
        @(posedge clk) d2 <= 'b11;

        #100;

        $finish;

    end

endmodule
