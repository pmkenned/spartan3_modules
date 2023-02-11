`timescale 1ns / 1ps
`default_nettype none

`define assert(condition) if (!(condition)) begin $display("ASSERTION FAILED"); $stop; end

`define SZ_1B 2'b00
`define SZ_2B 2'b01
`define SZ_4B 2'b11

module sram(
    input wire [17:0] addr,
    inout wire [15:0] data,
    input wire oe_l, we_l, 
    input wire ce_l, ub_l, lb_l
);

    parameter filename = "";

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

    initial begin
        $display("loading %s", filename);
        $readmemh(filename, mem);
    end

endmodule

module sram_testbench;

    reg [31:0] data_reg;
    wire [15:0] data1, data2;
    reg [15:0] data1_out, data2_out;
    reg [17:0] addr;
    reg oe_l, we_l;
    reg ce1_l, ub1_l, lb1_l, ce2_l, ub2_l, lb2_l;

    assign data1 = ~we_l ? data1_out : 'bz;
    assign data2 = ~we_l ? data2_out : 'bz;

    sram #("ram1.txt") sram1(.addr(addr), .data(data1), .oe_l(oe_l), .we_l(we_l), .ce_l(ce1_l), .ub_l(ub1_l), .lb_l(lb1_l));
    sram #("ram2.txt") sram2(.addr(addr), .data(data2), .oe_l(oe_l), .we_l(we_l), .ce_l(ce2_l), .ub_l(ub2_l), .lb_l(lb2_l));

    task clear_sram_control_signals();
        begin
            we_l = 'b1;
            oe_l = 'b1;
            ce1_l = 'b1;
            ce2_l = 'b1;
            ub1_l = 'b1;
            lb1_l = 'b1;
            ub2_l = 'b1;
            lb2_l = 'b1;
        end
    endtask

    task set_sram_control_signals(input [19:0] addr_byte_addr, input [1:0] size);
        reg [1:0] addr_aligned;
        begin
            addr_aligned = addr_byte_addr[1:0] & ~size;
            addr = addr_byte_addr[19:2];
            ce1_l = addr_aligned[1];
            ce2_l = ~(addr_aligned[1] | size[1]);
            lb1_l = addr_aligned[0];
            ub1_l = ~(addr_aligned[0] | size[0]);
            lb2_l = addr_aligned[0];
            ub2_l = ~(addr_aligned[0] | size[0]);
        end
    endtask

    task load(input [19:0] addr_byte_addr, input [1:0] size, output [31:0] data, input sign_extend);
        begin
            oe_l = 1'b0;
            we_l = 1'b1;
            set_sram_control_signals(addr_byte_addr, size);
            #10;
            case (size)
                `SZ_1B: begin
                    case (addr_byte_addr[1:0])
                        'b00: data = {sign_extend ? {24{data1[7]}}  : 24'b0, data1[7:0]};
                        'b01: data = {sign_extend ? {24{data1[15]}} : 24'b0, data1[15:8]};
                        'b10: data = {sign_extend ? {24{data2[7]}}  : 24'b0, data2[7:0]};
                        'b11: data = {sign_extend ? {24{data2[15]}} : 24'b0, data2[15:8]};
                    endcase
                end
                `SZ_2B: begin
                    case (addr_byte_addr[1])
                        'b0: data = {sign_extend ? {16{data1[15]}} : 16'b0, data1};
                        'b1: data = {sign_extend ? {16{data2[15]}} : 16'b0, data2};
                    endcase
                end
                `SZ_4B: data = {data2, data1};
            endcase
            clear_sram_control_signals();
        end
    endtask

    task store(input [19:0] addr_byte_addr, input [1:0] size, input [31:0] data);
        reg [1:0] addr_aligned;
        begin
            data1_out = data[15:0];
            data2_out = data[31:16];
            oe_l = 1'b1;
            we_l = 1'b0;
            set_sram_control_signals(addr_byte_addr, size);
            #10;
            clear_sram_control_signals();
        end
    endtask

    initial begin
        addr = 'b0;
        data1_out = 'b0;
        data2_out = 'b0;
        clear_sram_control_signals();

        // STORES

        //// *0x0 = 0x33221100;
        //$display("%0t storing 0x33221100 to 0x0", $time);
        //store('h0, `SZ_4B, 'h33221100);

        //// *0x4 = 0x77665544;
        //$display("%0t storing 0x77665544 to 0x4", $time);
        //store('h4, `SZ_4B, 'h77665544);

        //// *0x8 = 0xbbaa9988;
        //$display("%0t storing 0xbbaa9988 to 0x8", $time);
        //store('h8, `SZ_4B, 'hbbaa9988);

        //// *0x8 = 0xffeeddcc;
        //$display("%0t storing 0xffeeddcc to 0xc", $time);
        //store('hc, `SZ_4B, 'hffeeddcc);

        // LOADS

        // *0x0 == 0x33221100;
        load('h0, `SZ_4B, data_reg, 0);
        $display("%0t loaded %x from 0x0", $time, data_reg);
        `assert(data_reg == 'h33221100);
 
        // *0x4 == 0x77665544;
        load('h4, `SZ_4B, data_reg, 0);
        $display("%0t loaded %x from 0x4", $time, data_reg);
        `assert(data_reg == 'h77665544);
 
        // *0x8 == 0xbbaa9988;
        load('h8, `SZ_4B, data_reg, 0);
        $display("%0t loaded %x from 0x8", $time, data_reg);
        `assert(data_reg == 'hbbaa9988);
 
        // *0xc == 0xffeeddcc;
        load('hc, `SZ_4B, data_reg, 0);
        $display("%0t loaded %x from 0xc", $time, data_reg);
        `assert(data_reg == 'hffeeddcc);

        // STORES
 
        $display("%0t storing 0xdeadbeef to 0x4", $time);
        store('h4, `SZ_4B, 'hdeadbeef);

        $display("%0t storing 0xfeedbabe to 0xc", $time);
        store('hc, `SZ_4B, 'hfeedbabe);

        // LOADS

        load('h4, `SZ_1B, data_reg, 0);
        $display("%0t loaded %x from 0x4", $time, data_reg);
        `assert(data_reg == 'hef);

        load('h5, `SZ_1B, data_reg, 0);
        $display("%0t loaded %x from 0x5", $time, data_reg);
        `assert(data_reg == 'hbe);

        load('h6, `SZ_1B, data_reg, 1);
        $display("%0t loaded %x from 0x6", $time, data_reg);
        `assert(data_reg == 'hffffffad);

        load('h7, `SZ_1B, data_reg, 1);
        $display("%0t loaded %x from 0x7", $time, data_reg);
        `assert(data_reg == 'hffffffde);

        load('hc, `SZ_4B, data_reg, 0);
        $display("%0t loaded %x from 0xc", $time, data_reg);
        `assert(data_reg == 'hfeedbabe);

        $finish;
    end

endmodule
