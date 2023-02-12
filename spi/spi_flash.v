`timescale 1ns / 1ps
`default_nettype none

`include "common.vh"

// For reference, see:
// https://www.sdcard.org/downloads/pls/
// SD Specifications Part 1 Physical Layer Simplified Specification
// Chapter 7: SPI Mode
//
// COMMANDS
//
// CMD0 reset command including CRC: 0x40, 0x0, 0x0, 0x0, 0x0, 0x95
//
// All commands are 6 bytes
// Position     47      46      45:40       39:8        7:1     0
// Value        0       1       x           x           x       1
// Meaning      start   trans   command     argument    CRC7    end
//
//          765432109876543210987654321098765432109876543210
// CMDXX:   01CCCCCCAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAARRRRRRR1
//  C: command
//  A: argument
//  R: CRC7
//
// CMD0: GO_IDLE_STATE. Response: R1
//          010000000000000000000000000000000000000010010101
//
// CMD8: SEND_IF_COND. Response: R7
//          0100100000000000000000000000VVVVCCCCCCCCRRRRRRR1
//     39:20: Reserved(0)
//  V: 19:16: VHS (0001: 2.7-3.6V)
//  C: 15:8 : check pattern
//
// CMD16: SET_BLOCKLEN. Response: R1
//          01010000AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAARRRRRRR1
//  A: block length
//
// CMD17: READ_SINGLE_BLOCK. Response: R1
//          01010001AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAARRRRRRR1
//  A: address
//
// CMD18: READ_MULTIPLE_BLOCK. Response: R1
//          01010010AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAARRRRRRR1
//  A: address
//
// CMD24: WRITE_BLOCK. Response: R1
//          01011000AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAARRRRRRR1
//  A: address
//
// CMD25: WRITE_MULTIPLE_BLOCK. Response: R1
//          01011001AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAARRRRRRR1
//  A: address
//
// CMD55: APP_CMD. Response R1
//          01110111SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSRRRRRRR1
//  S: stuff bits (ignored)
//
// CMD58: READ_OCR. Response: R3
//          01111010SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSRRRRRRR1
//  S: stuff bits (ignored)
//
// NOTE: All ACMDs must be preceded by CMD55
//
// ACMD22: SEND_NUM_WR_BLOCKS. Response: R1
//          01010110SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSRRRRRRR1
//  S: stuff bits (ignored)
//
// ACMD41: SD_SEND_OP_COND. Response: R1
//          011010010H000000000000000000000000000000RRRRRRR1
//  H: HCS: host capacity support
//
// RESPONSES
//
// Format R1: 1 byte
//              7: 0
//              6: parameter error
//              5: address error
//              4: erase sequence error
//              3: com crc error
//              2: illegal command
//              1: erase reset
//              0: in idle state (1 means busy)
//
// Format R3: 5 bytes + CRC7
//              39:32: R1
//              31:0 : OCR register
//
// Format R7: 5 bytes + CRC7
//              39:32: R1
//              31:28: command version
//              27:12: reserved
//              11:8 : voltage accepted
//               7:0 : echo back
//
// Data Response Token: 1 byte
//              7:5: x
//                4: 0
//              3:1: status
//                0: 1
//  Status: 010 : Data accepted
//          101 : Data rejected due to CRC error
//          110 : Data rejected due to write error
//  In case of error during write multiple, host shall stop with CMD12
//  In case of write error, host may send CMD13 to check status
//  ACMD22 can be used to find number of well-written blocks
//
// Start block tokens and stop tran token
//  All data is transferred MSB first
//  Data tokens are 4 to 515 bytes long
//  For single block read, single block write, and multiple block read:
//   First byte: start block: 8'b11111110
//   Bytes 2-513: user data
//   Last 2 bytes: 16 bit CRC
// For multiple byte write:
//  First byte of each block:
//   If data is to be transferred:   8'b11111100
//   If Stop Transmission requested: 8'b11111101
//
// Data Error Token
//  7:4: 0
//    3: out of range
//    2: card ecc failed
//    1: cc error
//    0: error
//
// PROTOCOL
//
// <power on>
// --> CMD0 (assert CS): enter SPI mode
// <-- Response of SPI mode R1
// --> CMD8: SEND_IF_COND. VHS field in argument specifies supplied voltage.
// <-- Response with check pattern indicating same voltage
// --> CMD58 (optional): READ_OCR: get supported voltage levels
// <-- response
// --> ACMD41: SD_SEND_OP_COND: repeat until card not busy
// <-- R1 response: "in idle state" bit indicates if busy (0: done)
// --> CMD58: get capacity info
// <-- CCS field in response indicates SDSD(0) or SDHC/SDXC(1)
//
// CMD59 is used to enable/disable CRC checks
// Data blocks are suffixed by 16-bit CCITT polynomial x^16 + x^12 + x^5 + 1
// CRC7: x^7 + x^3 + 1
//
// READS:
// --> CMD16: SET_BLOCKLEN
// --> CMD17/18: read block
// <-- response, data block with CRC
// --> CMD12: stop data transmission
//
// WRITES:
// --> CMD24/25: write block
// <-- response
// --> [start block token] data block
// <-- data response token, busy
// --> CMD13: SEND_STATUS to check result
//  In multiblock write, a 'Stop Tran' token instead of 'start block'
//  will stop transmission
// --> ACMD22: SEND_NUM_WR_BLOCKS: used in case of a write error indication
//  to get the number of well-written blocks
//
// Can deassert CS while programming is still happening
// CMD0 during programming will terminate pending writes
//
// REGISTERS
//
// OCR
//  ...
//  20: 3.2-3.3V
//  21: 3.3-3.4V
//  22: 3.4-3.5V
//  23: 3.5-3.6V
//  ...
//  30: Card Capacity Status (CCS) 1: high capacity
//  31: Card power up status bit (0: busy)
//
// CID: Card Identification
// CSD: Card-Specific Data
// RCA: Relative Card Address
// DSR: driver-stage Register
// SCR: SD Configuration Register

`ifndef CMD24_A0
`define CMD24_A0    48'h58000000006f
`define CMD17_A0    48'h510000000055
`endif

// simulation model for spi flash chip
module spi_flash(
    input  wire sck,
    output wire miso,
    input  wire mosi,
    input  wire cs_l
);

    // TODO: create state machine which interprets instructions

    reg rst;

    initial begin
        rst = 1'b0;
        #10;
        rst = 1'b1;
        #10;
        rst = 1'b0;
    end

    reg [7:0] memory [0:512]; // 512 bytes for now

    wire cmd24_a0, cmd17_a0;
    assign cmd24_a0 = mosi_reg_q == `CMD24_A0;
    assign cmd17_a0 = mosi_reg_q == `CMD17_A0;

    // WRITES

    // once mosi goes low, the data starts on the next bit
    wire cmd24_n, cmd24_q;
    assign cmd24_n = (cmd24_q | cmd24_a0) & mosi;
    ff_ar cmd24_ff(.clk(sck), .rst(rst), .d(cmd24_n), .q(cmd24_q));

    // data_block_q indicates that we are currently receiving data bytes
    wire data_block_n, data_block_q;
    assign data_block_n = ((cmd24_q && ~cmd24_n) | data_block_q) && (mosi_cnt != 'd4095);
    ff_ar data_block_ff(.clk(sck), .rst(rst), .d(data_block_n), .q(data_block_q));

    // READS

    wire [3:0] r1_cnt;
    counter #(.W(4)) r1_cnt_reg(.clk(sck), .rst(rst), .inc(cmd17_q), .clr(1'b0), .cnt(r1_cnt));

    // 8 cycles for R1 and 8 cycles for 0xfe
    wire cmd17_n, cmd17_q;
    assign cmd17_n = (cmd17_q | cmd17_a0) & (r1_cnt != 4'd15);
    ff_ar cmd17_ff(.clk(sck), .rst(rst), .d(cmd17_n), .q(cmd17_q));

    // data_read_block_q indicates that we are currently transmitting data bytes
    wire data_read_block_n, data_read_block_q;
    assign data_read_block_n = ((cmd17_q && ~cmd17_n) | data_read_block_q) && (mosi_cnt != 'd4095);
    ff_ar data_read_block_ff(.clk(sck), .rst(rst), .d(data_read_block_n), .q(data_read_block_q));

    // this counter is used by both reads and writes
    wire [12:0] mosi_cnt;
    counter #(.W(13)) mosi_cnt_reg(.clk(sck), .rst(rst), .inc(~cs_l && (data_block_q | data_read_block_n)), .clr(cmd24_q | cmd17_n), .cnt(mosi_cnt));

    // records incoming data
    wire [47:0] mosi_reg_q;
    shift_register #(.W(48)) mosi_reg(.clk(sck), .rst(rst), .en(~cs_l), .d(mosi), .q(mosi_reg_q));

    assign miso = ~cs_l ? mem_reg_q[7] : 1'bz;

    // TODO: not storing the last two bytes correctly
    reg [7:0] mem_reg_q;
    always @(posedge sck) begin
        if (data_block_q && mosi_cnt[2:0] == 3'b000) begin
            memory[mosi_cnt[12:3]-1] <= mosi_reg_q[7:0];
        end
        if (data_read_block_n && mosi_cnt[2:0] == 3'b000) begin
            mem_reg_q <= memory[mosi_cnt[12:3]];
        end else if (r1_cnt[3] | data_read_block_q) begin
            mem_reg_q <= {mem_reg_q[6:0], 1'b1};
        end else begin
            mem_reg_q <= 8'hfe;
        end
    end

endmodule
