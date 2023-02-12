`timescale 1ns / 1ps
`default_nettype none

`define assert(condition) if (!(condition)) begin $display("ASSERTION FAILED"); $stop; end

module testbench;

    reg clk;
    reg rst;
    wire [7:0] leds;
    wire [3:0] buttons;
    reg [7:0] switches;
    reg [2:0] xb_buttons_l;
    wire [35:21] gpio;

    assign buttons[3] = rst;

    wire sck;
    wire miso;
    wire mosi;
    wire cs_l;

    assign sck  = gpio[21];
    assign gpio[23] = miso;
    assign mosi = gpio[25];
    assign cs_l = gpio[27];

    // sram
    wire [15:0] data1, data2;
    wire [17:0] addr;
    wire oe_l, we_l;
    wire ce1_l, ub1_l, lb1_l, ce2_l, ub2_l, lb2_l;

    top top(
        .clk(clk),
        .leds(leds),
        .buttons(buttons),
        .switches(switches),
        .xb_buttons_l(xb_buttons_l),
        .gpio(gpio),
        .data1(data1),
        .data2(data2),
        .addr(addr),
        .oe_l(oe_l),
        .we_l(we_l),
        .ce1_l(ce1_l),
        .ub1_l(ub1_l),
        .lb1_l(lb1_l),
        .ce2_l(ce2_l),
        .ub2_l(ub2_l),
        .lb2_l(lb2_l)
    );

    spi_flash spi_flash(
        .sck(sck),
        .miso(miso),
        .mosi(mosi),
        .cs_l(cs_l)
    );

    sram sram1(.addr(addr), .data(data1), .oe_l(oe_l), .we_l(we_l), .ce_l(ce1_l), .ub_l(ub1_l), .lb_l(lb1_l));
    sram sram2(.addr(addr), .data(data2), .oe_l(oe_l), .we_l(we_l), .ce_l(ce2_l), .ub_l(ub2_l), .lb_l(lb2_l));

    always begin
        #10 clk = ~clk;
    end

    initial begin
        clk = 'b0;
        rst = 'b0;
        switches = 'b0;
        xb_buttons_l = 3'b111;

        // toggle reset
        @(posedge clk) rst <= 'b1;
        @(posedge clk) rst <= 'b0;

        // init sequence
        // 48*5 (transmit) + 3*7 + 48*2 (receive), rounding up: 400
        repeat(400) @(posedge clk);

        // write block
        @(posedge clk) xb_buttons_l[0] <= 1'b0;
        @(posedge clk) xb_buttons_l[0] <= 1'b1;
        repeat(4200) @(posedge clk);

        // read block
        @(posedge clk) xb_buttons_l[1] <= 1'b0;
        @(posedge clk) xb_buttons_l[1] <= 1'b1;
        repeat(4200) @(posedge clk);

        repeat(600) @(posedge clk); // for uart byte
        repeat(600) @(posedge clk); // for uart byte
        repeat(600) @(posedge clk); // for uart byte
        repeat(600) @(posedge clk); // for uart byte

        repeat(600) @(posedge clk); // for uart byte
        repeat(600) @(posedge clk); // for uart byte
        repeat(600) @(posedge clk); // for uart byte
        repeat(600) @(posedge clk); // for uart byte

        $finish;
    end

endmodule

module sram(
    input wire [17:0] addr,
    inout wire [15:0] data,
    input wire oe_l, we_l, 
    input wire ce_l, ub_l, lb_l
);

    reg [15:0] data_out;
    assign data = (~ce_l && ~oe_l) ? data_out : 'bz;

    reg [15:0] mem [0:262143];
    
    always @(*) begin
        if (~ce_l) begin
            if (~we_l) begin
                if (~ub_l) mem[addr] = {data[15:8], mem[addr][7:0]};
                if (~lb_l) mem[addr] = {mem[addr][15:8], data[7:0]};
            end else if (~oe_l) begin
                data_out[15:8] = ~ub_l ? mem[addr][15:8] : 'bz;
                data_out[7:0]  = ~lb_l ? mem[addr][7:0]  : 'bz;
            end
        end
    end

endmodule
