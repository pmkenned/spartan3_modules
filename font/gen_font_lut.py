#!/usr/bin/env python3

import sys

template_header_str = """`timescale 1ns / 1ps
`default_nettype none

module font_lut(
    output wire px,
    input wire [7:0] ascii,
    input wire [3:0] row,
    input wire [2:0] col
);

    wire [127:0] lut_row;
"""

def main():

    with open(sys.argv[1], "r") as fh:
        lines = fh.read().splitlines()

    print(template_header_str)
    print("    always @(*) begin")
    print("        case ({ascii[6:4], row})")
    for i in range(0x20, 0x80):
        print(f"           7'h{i:x}: lut_row = 128'b{lines[i-0x20]};")
    print(f"           default: lut_row = 128'bx;")
    print("        endcase")
    print("    end")
    print("")
    print("    assign px = lut_row[{ascii[3:0], col}];")
    print("")
    print("endmodule")

if __name__ == "__main__":
    main()
