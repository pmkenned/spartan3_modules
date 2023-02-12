`timescale 1ns / 1ps
`default_nettype none

`include "common.vh"

module uart(
    input wire clk,
    input wire rst,
    input wire [7:0] byte_to_send,
    input wire send_byte,
    output wire ready,
    input wire rs232_rxd,
    output wire rs232_txd,
    input wire rs232_rxd_a,
    output wire rs232_txd_a
);

    // NOTE: assumes a 50MHz input clock
    `define UART_CLKS_PER_BIT 'd54      // 921600 baud

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

    wire [9:0] txd_shift_q, txd_shift_d;
    assign txd_shift_d = {
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

    assign ready = uart_bit_cnt == 'd0;

    assign rs232_txd = txd_shift_q[0];
    assign rs232_txd_a = 1'b1;

endmodule
