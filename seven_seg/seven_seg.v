`default_nettype none
`timescale 1ns / 1ps

module top(
    input wire clk,
    input wire [3:0] buttons,
    output wire [6:0] ss_abcdefg_l,
    output wire ss_dp_l,
    output wire [3:0] ss_sel_l
);

    wire rst;
    assign rst = buttons[3];

    ss_driver primary_ss_driver(
        .clk(clk),
        .rst(rst),
        .hex_digits(16'habcd),
        .ss_abcdefg_l(ss_abcdefg_l),
        .ss_dp_l(ss_dp_l),
        .ss_sel_l(ss_sel_l)
    );

    //ss_driver expansion_ss_driver();

endmodule

module hex_to_ss
#(parameter ROTATE=0)
(
    input wire [3:0] hex,
    output reg [6:0] ss_abcdefg_l
);

    always @(hex) begin
        case (hex)
            4'h0: ss_abcdefg_l = ROTATE ? 7'b0000001 : 7'b0000001;
            4'h1: ss_abcdefg_l = ROTATE ? 7'b1111001 : 7'b1001111;
            4'h2: ss_abcdefg_l = ROTATE ? 7'b0010010 : 7'b0010010;
            4'h3: ss_abcdefg_l = ROTATE ? 7'b0110000 : 7'b0000110;
            4'h4: ss_abcdefg_l = ROTATE ? 7'b1101000 : 7'b1001100;
            4'h5: ss_abcdefg_l = ROTATE ? 7'b0100100 : 7'b0100100;
            4'h6: ss_abcdefg_l = ROTATE ? 7'b0000100 : 7'b0100000;
            4'h7: ss_abcdefg_l = ROTATE ? 7'b1110001 : 7'b0001111;
            4'h8: ss_abcdefg_l = ROTATE ? 7'b0000000 : 7'b0000000;
            4'h9: ss_abcdefg_l = ROTATE ? 7'b1100000 : 7'b0001100;
            4'ha: ss_abcdefg_l = ROTATE ? 7'b1000000 : 7'b0001000;
            4'hb: ss_abcdefg_l = ROTATE ? 7'b0001100 : 7'b1100000;
            4'hc: ss_abcdefg_l = ROTATE ? 7'b0000111 : 7'b0110001;
            4'hd: ss_abcdefg_l = ROTATE ? 7'b0011000 : 7'b1000010;
            4'he: ss_abcdefg_l = ROTATE ? 7'b0000110 : 7'b0110000;
            4'hf: ss_abcdefg_l = ROTATE ? 7'b1000110 : 7'b0111000;
            default: ss_abcdefg_l = 7'b1111111;
        endcase
    end

endmodule

module ss_driver
#(parameter ROTATE = 0)
(
    input wire clk,
    input wire rst,
    input wire [15:0] hex_digits,
    output reg [6:0] ss_abcdefg_l,
    output wire ss_dp_l,
    output wire [3:0] ss_sel_l
);

    reg [19:0] clk_cnt;
    wire clk_191Hz;
    assign clk_191Hz = clk_cnt[17];

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            clk_cnt <= 20'b0;
        end else begin
            clk_cnt <= clk_cnt + 20'b1;
        end
    end

    reg [3:0] cycler;
    wire [3:0] cycler_n;
    wire [6:0] ss_array_l [3:0];

    assign cycler_n[1] = cycler[0];
    assign cycler_n[2] = cycler[1];
    assign cycler_n[3] = cycler[2];
    assign cycler_n[0] = cycler[3];

    assign ss_sel_l = ~cycler;

    always @(posedge clk_191Hz, posedge rst) begin
        if (rst) begin
            cycler <= 4'b1;
        end else begin
            cycler <= cycler_n;
        end
    end

    always @(cycler, ss_array_l[0], ss_array_l[1], ss_array_l[2], ss_array_l[3]) begin
        case (cycler)
            4'b0001: ss_abcdefg_l = ss_array_l[0];
            4'b0010: ss_abcdefg_l = ss_array_l[1];
            4'b0100: ss_abcdefg_l = ss_array_l[2];
            4'b1000: ss_abcdefg_l = ss_array_l[3];
            default: ss_abcdefg_l = 7'b1111111;
        endcase
    end

    assign ss_dp_l = 1'b1;

    hex_to_ss #(.ROTATE(ROTATE)) hts0(.hex(hex_digits[3:0]),   .ss_abcdefg_l(ss_array_l[0]));
    hex_to_ss #(.ROTATE(ROTATE)) hts1(.hex(hex_digits[7:4]),   .ss_abcdefg_l(ss_array_l[1]));
    hex_to_ss #(.ROTATE(ROTATE)) hts2(.hex(hex_digits[11:8]),  .ss_abcdefg_l(ss_array_l[2]));
    hex_to_ss #(.ROTATE(ROTATE)) hts3(.hex(hex_digits[15:12]), .ss_abcdefg_l(ss_array_l[3]));

endmodule
