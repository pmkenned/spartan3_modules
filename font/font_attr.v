`timescale 1ns / 1ps
`default_nettype none

module font_attr(
    output wire [2:0] rgb,
    input wire [7:0] ascii,
    input wire [7:0] attr,
    input wire [3:0] row,
    input wire [2:0] col
);

    wire px;

    assign rgb[0] = px ? attr[0] : attr[4];
    assign rgb[1] = px ? attr[1] : attr[5];
    assign rgb[2] = px ? attr[2] : attr[6];

    font_lut font_lut(
        .px(px),
        .ascii(ascii),
        .row(row),
        .col(col)
    );

endmodule
