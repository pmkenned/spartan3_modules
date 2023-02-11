module top(
    input wire clk,
    input wire [3:0] buttons,
    output wire vga_hs_l,
    output wire vga_vs_l,
    output reg [2:0] vga_rgb
);
    wire rst;
    assign rst = buttons[3];

    wire [8:0] vga_row;
    wire [9:0] vga_col;
    wire vga_display;

    // vertical colored stripes
    always @(*) begin
        if (vga_display) begin
            if      (vga_col < 'd80)    vga_rgb = 3'b000; // black
            else if (vga_col < 'd160)   vga_rgb = 3'b001; // blue
            else if (vga_col < 'd240)   vga_rgb = 3'b010; // green
            else if (vga_col < 'd320)   vga_rgb = 3'b011; // cyan
            else if (vga_col < 'd400)   vga_rgb = 3'b100; // red
            else if (vga_col < 'd480)   vga_rgb = 3'b101; // magenta
            else if (vga_col < 'd560)   vga_rgb = 3'b110; // yellow
            else                        vga_rgb = 3'b111; // white
        end else begin
            vga_rgb = 3'b000;
        end
    end

    vga_driver vga(
        .clk(clk),
        .rst(rst),
        .vga_row(vga_row),
        .vga_col(vga_col),
        .vga_display(vga_display),
        .vga_hs_l(vga_hs_l),
        .vga_vs_l(vga_vs_l)
    );

endmodule
