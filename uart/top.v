`default_nettype none
`timescale 1ns / 1ps

`include "common.vh"

module top(
    input wire clk,
    input wire [3:0] buttons,
    input wire [2:0] xb_buttons,
    input wire [7:0] switches,
    input wire rs232_rxd,
    output wire rs232_txd,
    input wire rs232_rxd_a,
    output wire rs232_txd_a
);

// NOTE: assumes a 50MHz input clock
//  `define UART_CLKS_PER_BIT 'd434     // 115200 baud
    `define UART_CLKS_PER_BIT 'd54      // 921600 baud

    wire rst;
    assign rst = buttons[3];

    wire [2:0] xb_buttons_q;
    wire [2:0] xb_buttons_pulse;
    ff_ar #(.W(3)) xb_buttons_ff(.clk(clk), .rst(rst), .d(xb_buttons), .q(xb_buttons_q));
    assign xb_buttons_pulse = xb_buttons & ~xb_buttons_q;

    wire send_byte;
    assign send_byte = xb_buttons_pulse[0];

    wire [8:0] uart_clk_cnt;
    wire [3:0] uart_bit_cnt;

    counter #(
        .W(9),
        .FINAL_VAL(`UART_CLKS_PER_BIT)
    ) uart_clk_counter (
        .clk(clk),
        .rst(rst),
        .inc(uart_bit_cnt != 'd0),
        .clr(send_byte),
        .cnt(uart_clk_cnt)
    );

    counter #(
        .W(4),
        .FINAL_VAL(10)
    ) uart_bit_counter (
        .clk(clk),
        .rst(rst),
        .inc(send_byte || uart_clk_cnt == `UART_CLKS_PER_BIT),
        .clr(1'b0),
        .cnt(uart_bit_cnt)
    );

    wire [7:0] byte_to_send;
    assign byte_to_send = switches;

    wire parity_bit;
    assign parity_bit = 1'b1; // TODO
    wire [9:0] txd_shift_q, txd_shift_d;
    assign txd_shift_d = {
        // TODO: add parity bit here
        byte_to_send,
        1'b0,   // start bit
        1'b1    // stop bit (held until start)
    };
    piso_shift_register #(
        .W(10),
        .RESET_VAL(10'h3ff),
        .SHIFT_DIR(`SHIFT_DIR_RIGHT)
    ) txd_shift_reg (
        .clk    (clk),
        .rst    (rst),
        .shift  (uart_clk_cnt == `UART_CLKS_PER_BIT),
        .x      (txd_shift_q[0]),
        .load   (send_byte),
        .d      (txd_shift_d),
        .q      (txd_shift_q)
    );

    assign rs232_txd = txd_shift_q[0];
    assign rs232_txd_a = 1'b1;

endmodule
