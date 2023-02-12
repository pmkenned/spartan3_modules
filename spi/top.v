`timescale 1ns / 1ps
`default_nettype none

// Initialization sequence:
// --> CMD0:    48'h400000000095; assert CS
// <-- R1 (1b): 8'h00;
// --> CMD8:    48'h4800000100d5; VHS=0001 (3.3V), check pattern=8'b0
// <-- R7 (6b): 48'h00xxxxx100xx; voltage=4'b0001, check pattner=8'b0
// --> CMD55:   48'h770000000065;
// <-- R1 (1b): 8'h00;
// --> ACMD41:  48'h6900000000e5; HCS=0
// <-- R1 (1b): 8'h01; (some number of these)
// <-- R1 (1b): 8'h00;
// --> CMD58:   48'h7a00000000fd;
// <-- R3 (6b): 48'hxxxxxxxxxxxx; OCR register (valid CCS) + CRC7
//
// WRITE_BLOCK:         48'b0101_1000_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_RRRR_RRR1
// READ_SINGLE_BLOCK:   48'b0101_0001_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_RRRR_RRR1
//
// Write sequence:
// --> CMD24:   48'h58000000006f; addr=0
// <-- R1 (1b): 8'h00;
// --> Data block: 8'hfe, data bytes, 16-bit CRC
// <-- data response: 8'bxxx00101, busy (data held low)
//
// Read sequence:
// --> CMD17:   48'h510000000055; addr=0
// <-- R1 (1b): 8'h00
// <-- 8'hfe, data bytes, 16-bit CRC

`define CMD0        48'h400000000095
`define CMD8        48'h4800000100d5
`define CMD55       48'h770000000065
`define ACMD41      48'h6900000000e5
`define CMD58       48'h7a00000000fd
`define CMD24_A0    48'h58000000006f
`define CMD17_A0    48'h510000000055

// FSM State Encodings:

`define STATE_IDLE      7'b0000000
// init states
`define STATE_TCMD0     7'b1001000
`define STATE_R1A       7'b0110000
`define STATE_TCMD8     7'b1001001
`define STATE_R7        7'b0101000
`define STATE_TCMD55    7'b1001010
`define STATE_R1B       7'b0110001
`define STATE_TACMD41   7'b1001011
`define STATE_R1C       7'b0110010
`define STATE_TCMD58    7'b1001100
`define STATE_R3        7'b0101001
// write states
`define STATE_TCMD24    7'b1001101
`define STATE_R1D       7'b0110011
`define STATE_TDATA     7'b1000000
`define STATE_RESP      7'b0110101
// read states
`define STATE_TCMD17    7'b1001110
`define STATE_R1E       7'b0110100
`define STATE_RDATA     7'b0100000

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

    wire [2:0] xb_buttons_q;
    ff_ar #(.W(3)) xb_buttons_ff(.clk(clk), .rst(rst), .d(xb_buttons), .q(xb_buttons_q));
    wire [2:0] xb_buttons_pulse;
    assign xb_buttons_pulse = xb_buttons & ~xb_buttons_q;

    wire write_block, read_block;
    assign write_block = xb_buttons_pulse[0];
    assign read_block = xb_buttons_pulse[1];

    wire sck;
    wire miso;
    wire mosi;
    wire cs_l;

    wire sck_en;
    assign sck = sck_en && ~clk; // sample on negedge of clk
    assign miso = 1'bz;
    assign mosi = cmd_reg_q[47];
    assign cs_l = ~sck_en;

    assign gpio[21] = sck;
    assign gpio[23] = miso;
    assign gpio[25] = mosi;
    assign gpio[27] = cs_l;

    assign gpio[22] = 1'bz;
    assign gpio[24] = 1'bz;
    assign gpio[26] = 1'bz;
    assign gpio[35:28] = 'bz;

    assign leds = {8{miso}}; // TODO: latch miso

    reg  [1:0] state_n;
    wire [1:0] state_q;

    wire transmit, receive, r1, r3r7, idle;
    assign transmit     = state_q[6];
    assign receive      = state_q[5];
    assign r1           = state_q[4];
    assign r3r7         = state_q[3];
    assign idle         = ~state_q[6] & ~state_q[5];
    assign data_block   = ~state_q[4] & ~state_q[3]; // 515 bytes (4120 bits)

    assign sck_en = transmit | receive;

    reg [12:0] max_mosi;
    always @(*) begin
        max_mosi = 'bx;
        if      (data_block)        max_mosi = 'd4119;
        else if (receive && r1)     max_mosi = 'd7;
        else if (receive && r3r7)   max_mosi = 'd47;
        else if (transmit)          max_mosi = 'd47;
    end

    wire [12:0] mosi_cnt, miso_cnt;
    assign miso_cnt = mosi_cnt; // alias
    counter #(.W(6)) mosi_cnt_reg(
        .clk(clk),
        .rst(rst),
        .inc(transmit | receive),
        .clr(mosi_cnt == max_mosi),
        .cnt(mosi_cnt)
    );

    reg load_cmd_reg;
    reg  [47:0] cmd_reg_n;
    wire [47:0] cmd_reg_q;

    always @(*) begin
        state_n = state_q;
        case (state_q)
            // idle state
            `STATE_IDLE:
                state_n = `STATE_IDLE;
                if (write_block)    state_n = `STATE_TCMD24;
                if (read_block)     state_n = `STATE_TCMD17;
            // init states
            `STATE_TCMD0:   if (mosi_cnt == max_mosi)   state_n = `STATE_R1A;
            `STATE_R1A:     if (miso_cnt == max_mosi)   state_n = `STATE_TCMD8;
            `STATE_TCMD8:   if (mosi_cnt == max_mosi)   state_n = `STATE_R7;
            `STATE_R7:      if (miso_cnt == max_mosi)   state_n = `STATE_TCMD55;
            `STATE_TCMD55:  if (mosi_cnt == max_mosi)   state_n = `STATE_R1B;
            `STATE_R1B:     if (miso_cnt == max_mosi)   state_n = `STATE_TACMD41;
            `STATE_TACMD41: if (mosi_cnt == max_mosi)   state_n = `STATE_R1C;
            `STATE_R1C:     if (miso_cnt == max_mosi)   state_n = `STATE_TCMD58;
            `STATE_TCMD58:  if (mosi_cnt == max_mosi)   state_n = `STATE_R3;
            `STATE_R3:      if (miso_cnt == max_mosi)   state_n = `STATE_IDLE;
            // write states
            `STATE_TCMD24:  if (mosi_cnt == max_mosi)   state_n = `STATE_R1D;
            `STATE_R1D:     if (miso_cnt == max_mosi)   state_n = `STATE_TDATA;
            `STATE_TDATA:   if (mosi_cnt == max_mosi)   state_n = `STATE_RESP;
            `STATE_RESP:    if (miso_cnt == max_mosi)   state_n = `STATE_IDLE;
            // read states
            `STATE_TCMD17:  if (mosi_cnt == max_mosi)   state_n = `STATE_R1E;
            `STATE_R1E:     if (miso_cnt == max_mosi)   state_n = `STATE_RDATA;
            `STATE_RDATA:   if (miso_cnt == max_mosi)   state_n = `STATE_IDLE;
            default:
                state_n = state_q;
        endcase

        load_cmd_reg = state_n[6]; // next state is transmitting

        cmd_reg_n = 'dx;
        case(state_n)
            `STATE_TCMD0:   cmd_reg_n = `CMD0;
            `STATE_TCMD8:   cmd_reg_n = `CMD8;
            `STATE_TCMD55:  cmd_reg_n = `CMD55;
            `STATE_TACMD41: cmd_reg_n = `ACMD41;
            `STATE_TCMD58:  cmd_reg_n = `CMD58;
            `STATE_TCMD24:  cmd_reg_n = `CMD24_A0;
            `STATE_TDATA:   cmd_reg_n = 48'hfeedbabebeef;
            `STATE_TCMD17:  cmd_reg_n = `CMD17_A0;
        endcase
    end

    ff_ar #(.W(7), .RESET_VAL(`STATE_TCMD0)) state_ff(.clk(clk), .rst(rst), .d(state_n), .q(state_q));

    piso_shift_register #(
        .W(48),
        .RESET_VAL(`CMD0)
    ) cmd_reg (
        .clk(clk),
        .rst(rst),
        .shift(transmit | receive),
        .x(cmd_reg_q[47]),
        .load(load_cmd_reg),
        .d(cmd_reg_n),
        .q(cmd_reg_q)
    );

    spi_flash spi_flash(
        .sck(sck),
        .miso(miso),
        .mosi(mosi),
        .cs_l(cs_l)
    );

endmodule
