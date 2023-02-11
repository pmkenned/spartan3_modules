`default_nettype none
`timescale 1ns / 1ps

module ff_ar #(
    parameter W=1,
    parameter RESET_VAL=0
)(
    input wire clk,
    input wire rst,
    input wire [W-1:0] d,
    output reg [W-1:0] q
);

    always @(posedge clk, posedge rst) begin
        if (rst) q <= RESET_VAL;
        else     q <= d;
    end

endmodule
