`ifndef VGA_VH
`define VGA_VH

//`define TEST_VGA

`ifdef TEST_VGA

`define VGA_COLS 12
`define VGA_ROWS 10

`define VGA_HFP 5
`define VGA_HSP 10
`define VGA_HBP 8

`define VGA_VFP 5
`define VGA_VSP 2
`define VGA_VBP 8

`else

`define VGA_ROWS 480
`define VGA_COLS 640

`define VGA_HFP 16
`define VGA_HSP 96
`define VGA_HBP 48

`define VGA_VFP 11
`define VGA_VSP 2
`define VGA_VBP 31

`endif

`define VGA_HTOTAL (`VGA_COLS + `VGA_HFP + `VGA_HSP + `VGA_HBP)
`define VGA_VTOTAL (`VGA_ROWS + `VGA_VFP + `VGA_VSP + `VGA_VBP)

`define VGA_START_HS (`VGA_COLS + `VGA_HFP)
`define VGA_END_HS   (`VGA_COLS + `VGA_HFP + `VGA_HSP)
`define VGA_START_VS (`VGA_ROWS + `VGA_VFP)
`define VGA_END_VS   (`VGA_ROWS + `VGA_VFP + `VGA_VSP)

`endif
