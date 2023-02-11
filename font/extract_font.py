#!/usr/bin/env python3

import sys
import argparse
import png

def print_png(data):
    for row in data:
        for i in range(0, len(row)//4):
            sys.stdout.write(f"{row[i*4]:02x} {row[i*4+1]:02x} {row[i*4+2]:02x} {row[i*4+3]:02x} ;")
        sys.stdout.write("\n")


def print_output(data, char_width, char_height):
    num_char_rows = len(data)//char_height
    num_char_cols = len(data[0])//(char_width*4)
    num_chars = num_char_rows*num_char_cols
    output = [["0" for i in range(0, 16*char_width)] for j in range(0, char_height*num_chars//16)]
    i = 0
    for char_row in range(0, num_char_rows):
        for char_col in range(0, num_char_cols):
            for row in range(0, char_height):
                for col in range(0, char_width):
                    data_row = char_row*char_height + row
                    data_col = char_col*char_width + col
                    px = data[data_row][data_col*4:(data_col + 1)*4]
                    bit = "0" if px[0:3] == bytearray([0x0, 0x0, 0x0]) else "1"
                    out_row = (i // 16)*char_height + row
                    out_col = (i % 16)*char_width + col
                    output[out_row][out_col] = bit
            i += 1
    for row in output:
        print("".join(row))


def main(filename, char_width, char_height):
    reader = png.Reader(filename=filename)
    img = reader.read()
    data = list(img[2])
    print_output(data, char_width, char_height)
    #print_png(data)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument('--help', action="help")
    parser.add_argument('filename')
    parser.add_argument('-w', '--width', type=int)
    parser.add_argument('-h', '--height', type=int)
    args = parser.parse_args()
    main(args.filename, args.width, args.height)
