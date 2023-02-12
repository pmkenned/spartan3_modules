`timescale 1ns / 1ps
`default_nettype none

module top(
    input wire clk,
    input wire [3:0] buttons,
    input wire [7:0] switches,
    output wire [7:0] leds,
    input wire [2:0] xb_buttons,
    inout wire [35:21] gpio
);

    wire rst;
    assign rst = buttons[3];

    wire sck;
    wire miso;
    wire mosi;
    wire cs_l;

    wire sck_en;
    assign sck_en = 1'b0; // TODO
    assign sck = sck_en && clk;
    assign miso = 1'bz;
    assign mosi = 1'b0; // TODO: master-out
    assign cs_l = 1'b1;

    assign gpio[21] = sck;
    assign gpio[23] = miso;
    assign gpio[25] = mosi;
    assign gpio[27] = cs_l;

    assign gpio[22] = 1'bz;
    assign gpio[24] = 1'bz;
    assign gpio[26] = 1'bz;
    assign gpio[35:28] = 'bz;

    assign leds = 'b0; // TODO: show data

    // Initialization sequence:
    // --> CMD0:    48'h400000000095; assert CS
    // <-- R1 (1b): 8'h00;
    // --> CMD8:    48'h4800000100d5; VHS=0001 (3.3V), check pattern=8'b0
    // <-- R7 (5b): 40'hxxxxxxxxxx;
    // --> CMD55:   48'h770000000065;
    // <-- R1 (1b): 8'h00;
    // --> ACMD41:  48'h6900000000e5; HCS=0
    // <-- R1 (1b): 8'h01; (some number of these)
    // <-- R1 (1b): 8'h00;
    // --> CMD58:   48'h7a00000000fd;
    // <-- R3 (5b): 40'hxxxxxxxxxx; OCR register; CCS is valid field

    // WRITE_BLOCK:         48'b0101_1000_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_RRRR_RRR1
    // READ_SINGLE_BLOCK:   48'b0101_0001_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_RRRR_RRR1

    // Write sequence:
    // --> CMD24:   48'h58000000006f; addr=0
    // <-- R1 (1b): 8'h00;
    // --> Data block: 8'hfe, data bytes, 16-bit CRC
    // <-- data response: 8'bxxx00101, busy (data held low)

    // Read sequence:
    // --> CMD17:   48'h510000000055; addr=0
    // <-- R1 (1b): 8'h00
    // <-- 8'hfe, data bytes, 16-bit CRC

    spi_flash spi_flash(
        .sck(sck),
        .miso(miso),
        .mosi(mosi),
        .cs_l(cs_l)
    );

endmodule
