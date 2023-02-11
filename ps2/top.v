`timescale 1ns / 1ps
`default_nettype none

`include "ps2.vh"

module top(
    input wire clk,
    input wire rst,
    inout wire ps2_data,
    inout wire ps2_clk,
    output wire [7:0] leds
);

    wire key_down;
    wire key_up;
    wire [7:0] scan_code;

    wire caps_lock;
    wire num_lock;
    wire shift;
    wire [7:0] ascii;

    assign leds = ascii;

    // TODO: make these ffs
    assign shift = 1'b0;
    assign caps_lock = 1'b0;
    assign num_lock = 1'b0;

    ps2_unit ps2(
        .ps2_data(ps2_data),
        .ps2_clk(ps2_clk),
        .clk(clk),
        .rst(rst),
        .key_down(key_down),
        .key_up(key_up),
        .scan_code(scan_code)
    );

    scan_code_to_ascii sc2a(
        .scan_code(scan_code),
        .caps_lock(caps_lock),
        .num_lock(num_lock),
        .shift(shift),
        .ascii(ascii)
    );

endmodule

module scan_code_to_ascii(
    input wire [7:0] scan_code,
    input wire caps_lock,
    input wire num_lock,
    input wire shift,
    output reg [7:0] ascii
);

    wire upper;
    assign upper = (caps_lock ^ shift);

    always @(*) begin
        case (scan_code)
            `SCAN_0:        ascii = shift ? ")" : "0";
            `SCAN_1:        ascii = shift ? "!" : "1";
            `SCAN_2:        ascii = shift ? "@" : "2";
            `SCAN_3:        ascii = shift ? "#" : "3";
            `SCAN_4:        ascii = shift ? "$" : "4";
            `SCAN_5:        ascii = shift ? "%" : "5";
            `SCAN_6:        ascii = shift ? "^" : "6";
            `SCAN_7:        ascii = shift ? "&" : "7";
            `SCAN_8:        ascii = shift ? "*" : "8";
            `SCAN_9:        ascii = shift ? "(" : "9";
            `SCAN_MINUS:    ascii = shift ? "_" : "-";
            `SCAN_EQUAL:    ascii = shift ? "+" : "=";
            `SCAN_LBRACKET: ascii = shift ? "{" : "[";
            `SCAN_RBRACKET: ascii = shift ? "}" : "]";
            `SCAN_BSLASH:   ascii = shift ? "|" : "\\";
            `SCAN_FSLASH:   ascii = shift ? "/" : "?";
            `SCAN_SEMI:     ascii = shift ? ":" : ";";
            `SCAN_QUOTE:    ascii = shift ? "\"" : "'";
            `SCAN_COMMA:    ascii = shift ? "<" : ",";
            `SCAN_PERIOD:   ascii = shift ? ">" : ".";
            `SCAN_A:        ascii = upper ? "A" : "a";
            `SCAN_B:        ascii = upper ? "B" : "b";
            `SCAN_C:        ascii = upper ? "C" : "c";
            `SCAN_D:        ascii = upper ? "D" : "d";
            `SCAN_E:        ascii = upper ? "E" : "e";
            `SCAN_F:        ascii = upper ? "F" : "f";
            `SCAN_G:        ascii = upper ? "G" : "g";
            `SCAN_H:        ascii = upper ? "H" : "h";
            `SCAN_I:        ascii = upper ? "I" : "i";
            `SCAN_J:        ascii = upper ? "J" : "j";
            `SCAN_K:        ascii = upper ? "K" : "k";
            `SCAN_L:        ascii = upper ? "L" : "l";
            `SCAN_M:        ascii = upper ? "M" : "m";
            `SCAN_N:        ascii = upper ? "N" : "n";
            `SCAN_O:        ascii = upper ? "O" : "o";
            `SCAN_P:        ascii = upper ? "P" : "p";
            `SCAN_Q:        ascii = upper ? "Q" : "q";
            `SCAN_R:        ascii = upper ? "R" : "r";
            `SCAN_S:        ascii = upper ? "S" : "s";
            `SCAN_T:        ascii = upper ? "T" : "t";
            `SCAN_U:        ascii = upper ? "U" : "u";
            `SCAN_V:        ascii = upper ? "V" : "v";
            `SCAN_W:        ascii = upper ? "W" : "w";
            `SCAN_X:        ascii = upper ? "X" : "x";
            `SCAN_Y:        ascii = upper ? "Y" : "y";
            `SCAN_Z:        ascii = upper ? "Z" : "z";
            default:        ascii = 8'h00;
        endcase
    end

endmodule
