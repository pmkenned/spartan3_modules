`timescale 1ns / 1ps
`default_nettype none

`include "common.vh"
`include "ps2.vh"

// TODO: context menu key
// TODO: print screen, scroll lock, pause

module ps2_unit(
    inout wire ps2_data,
    inout wire ps2_clk,
    input wire clk,
    input wire rst,
    output wire key_down,
    output wire key_up,
    output wire [7:0] scan_code
);

    wire [7:0] ps2_data_byte;
    wire ps2_odd_parity;
    wire ps2_packet_done;

    assign ps2_data = 1'bz;
    assign ps2_clk  = 1'bz;

    // TODO: ps2_transmitter

    ps2_receiver ps2_rx(
        .clk(clk),
        .rst(rst),
        .ps2_data(ps2_data),
        .ps2_clk(ps2_clk),
        .ps2_data_byte(ps2_data_byte),
        .ps2_odd_parity(ps2_odd_parity),
        .ps2_packet_done(ps2_packet_done)
    );

    ps2_parser ps2_p(
        .clk(clk),
        .rst(rst),
        .ps2_data_byte(ps2_data_byte),
        .ps2_odd_parity(ps2_odd_parity),
        .ps2_packet_done(ps2_packet_done),
        .key_down(key_down),
        .key_up(key_up),
        .scan_code(scan_code)
    );

endmodule

module ps2_receiver(
    input wire clk,
    input wire rst,
    input wire ps2_data,
    input wire ps2_clk,
    output wire [7:0] ps2_data_byte,
    output wire ps2_odd_parity,
    output wire ps2_packet_done
);

    // TODO: if necessary, may use shift register to get stable ps2_clk transition

    wire ps2_clk_stable;
    ff_ar ps2_clk_stable_ff(.clk(clk), .rst(rst), .d(~ps2_clk), .q(ps2_clk_stable));

    wire [9:0] ps2_data_reg_q; // don't store stop bit
    shift_register #(.W(10), .SHIFT_DIR(`SHIFT_DIR_RIGHT)) ps2_data_shift_reg(.clk(ps2_clk_stable), .rst(rst), .en(1'b1), .d(ps2_data), .q(ps2_data_reg_q));

    // NOTE: final value is 10 so that the stop bit cycle resets the counter to 0 to start over
    wire [3:0] ps2_clk_cnt_q;
    counter #(.W(4), .START_VAL(0), .FINAL_VAL(10)) ps2_clk_counter(.clk(ps2_clk_stable), .rst(rst), .clr(1'b0), .inc(1'b1), .cnt(ps2_clk_cnt_q));

    wire ps2_done_flag_q, ps2_done_flag_n;
    assign ps2_done_flag_n = (ps2_clk_cnt_q == 'd10) ? 1'b1 : 1'b0;
    ff_ar ps2_done_flag_ff(.clk(clk), .rst(rst), .d(ps2_done_flag_n), .q(ps2_done_flag_q));

    // outputs

    assign ps2_packet_done = (ps2_clk_cnt_q == 'd10 && ~ps2_done_flag_q);
    assign ps2_data_byte = ps2_data_reg_q[8:1];
    assign ps2_odd_parity = ps2_data_reg_q[9];

endmodule

module ps2_parser(
    input wire clk,
    input wire rst,
    input wire [7:0] ps2_data_byte,
    input wire ps2_odd_parity,
    input wire ps2_packet_done,
    output wire key_down,
    output wire key_up,
    output wire [7:0] scan_code
);

    // TODO: check parity bit

    wire prev_was_key_up_q;
    wire prev_was_key_up_n;
    assign prev_was_key_up_n = (ps2_packet_done) ? ((ps2_data_byte == `SCAN_KEY_UP) ? 1'b1 : 1'b0) : prev_was_key_up_q;
    ff_ar prev_was_key_up_ff(.clk(clk), .rst(rst), .d(prev_was_key_up_n), .q(prev_was_key_up_q));

    wire [7:0] byte1_q;
    wire [7:0] byte1_n;
    wire [7:0] byte2_q;
    wire [7:0] byte2_n;

    assign byte1_n = (ps2_packet_done && ~prev_was_key_up_q) ? ps2_data_byte : byte1_q;
    assign byte2_n = (ps2_packet_done && prev_was_key_up_q) ? ps2_data_byte : 8'b0;

    ff_ar #(.W(8)) byte_1_reg(.clk(clk), .rst(rst), .d(byte1_n), .q(byte1_q));
    ff_ar #(.W(8)) byte_2_reg(.clk(clk), .rst(rst), .d(byte2_n), .q(byte2_q));

    // outputs

    assign key_down = (ps2_packet_done && ~prev_was_key_up_q && ~prev_was_key_up_n) ? 1'b1 : 1'b0;
    assign key_up   = (ps2_packet_done && prev_was_key_up_q) ? 1'b1 : 1'b0;
    assign scan_code = ps2_data_byte;

endmodule
