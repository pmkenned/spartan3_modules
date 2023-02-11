`timescale 1ns / 1ps
`default_nettype none

`include "ps2.vh"

`define assert(condition) if (!(condition)) begin $display("ASSERTION FAILED"); $stop; end

module testbench;

    reg ps2_data;
    reg ps2_clk;
    reg clk;
    reg rst;
    wire ps2_data_net;
    wire ps2_clk_net;
    wire [7:0] leds;

    assign ps2_data_net = ps2_data;
    assign ps2_clk_net = ps2_clk;

    top top(
        .ps2_data(ps2_data_net),
        .ps2_clk(ps2_clk_net),
        .leds(leds),
        .clk(clk),
        .rst(rst)
    );

    always begin
        #10 clk = ~clk;
    end

    task ps2_generate_word(input [7:0] byte);

        begin

            // idle state
            @(posedge clk);
            ps2_clk  <= 1'b1;
            ps2_data <= 1'b1;

            repeat(20) @(posedge clk);
            ps2_data <= 1'b0; // start bit

            repeat(20) @(posedge clk);
            ps2_clk  <= 1'b0; // negedge ps2_clk

            repeat(20) @(posedge clk);
            ps2_clk  <= 1'b1;
            ps2_data <= byte[0]; // bit[0]

            repeat(20) @(posedge clk);
            ps2_clk  <= 1'b0; // negedge ps2_clk

            repeat(20) @(posedge clk);
            ps2_clk  <= 1'b1;
            ps2_data <= byte[1]; // bit[1]

            repeat(20) @(posedge clk);
            ps2_clk  <= 1'b0; // negedge ps2_clk

            repeat(20) @(posedge clk);
            ps2_clk  <= 1'b1;
            ps2_data <= byte[2]; // bit[2]

            repeat(20) @(posedge clk);
            ps2_clk  <= 1'b0; // negedge ps2_clk

            repeat(20) @(posedge clk);
            ps2_clk  <= 1'b1;
            ps2_data <= byte[3]; // bit[3]

            repeat(20) @(posedge clk);
            ps2_clk  <= 1'b0; // negedge ps2_clk

            repeat(20) @(posedge clk);
            ps2_clk  <= 1'b1;
            ps2_data <= byte[4]; // bit[4]

            repeat(20) @(posedge clk);
            ps2_clk  <= 1'b0; // negedge ps2_clk

            repeat(20) @(posedge clk);
            ps2_clk  <= 1'b1;
            ps2_data <= byte[5]; // bit[5]

            repeat(20) @(posedge clk);
            ps2_clk  <= 1'b0; // negedge ps2_clk

            repeat(20) @(posedge clk);
            ps2_clk  <= 1'b1;
            ps2_data <= byte[6]; // bit[6]

            repeat(20) @(posedge clk);
            ps2_clk  <= 1'b0; // negedge ps2_clk

            repeat(20) @(posedge clk);
            ps2_clk  <= 1'b1;
            ps2_data <= byte[7]; // bit[7]

            repeat(20) @(posedge clk);
            ps2_clk  <= 1'b0; // negedge ps2_clk

            repeat(20) @(posedge clk);
            ps2_clk  <= 1'b1;
            ps2_data <= 1'b0; // parity (TODO)

            repeat(20) @(posedge clk);
            ps2_clk  <= 1'b0; // negedge ps2_clk

            repeat(20) @(posedge clk);
            ps2_clk  <= 1'b1;
            ps2_data <= 1'b1; // stop

            repeat(20) @(posedge clk);
            ps2_clk  <= 1'b0; // negedge ps2_clk

            repeat(20) @(posedge clk);
            ps2_clk  <= 1'b1; // idle

        end

    endtask

    initial begin
        clk = 'b0;
        ps2_data = 'b1;
        ps2_clk = 'b1;

        // toggle reset
        @(posedge clk) rst <= 'b1;
        @(posedge clk) rst <= 'b0;

        ps2_generate_word(`SCAN_KEY_UP);
        ps2_generate_word(`SCAN_A);

        $finish;
    end

endmodule
