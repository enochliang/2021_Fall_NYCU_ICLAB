`timescale 1ns/1ps
`include "PATTERN.v"

`ifdef RTL
`include "CDC.v"
`include "syn_XOR.v"
`include "synchronizer.v"
`elsif GATE
`include "CDC_SYN.v"
`endif

module TESTBED();


wire	clk_1,clk_2,clk_3,rst_n,in_valid;
wire	[59:0] message;
wire 	mode;
wire	out_valid;
wire 	[59:0]out;
wire CRC;

initial begin
  `ifdef RTL
    $fsdbDumpfile("CDC.fsdb");
//	  $fsdbDumpvars();
	  $fsdbDumpvars(0,"+mda");
  `elsif GATE
    $fsdbDumpfile("CDC_SYN.fsdb");
	  $sdf_annotate("CDC_SYN_pt.sdf",I_CDC,,,"maximum");      
	  $fsdbDumpvars(0,"+mda");
//	  $fsdbDumpvars();
  `endif
end

CDC I_CDC
(
  // Input signals
	.clk_1(clk_1),
	.clk_2(clk_2),
	.clk_3(clk_3),
	.in_valid(in_valid),
	.mode(mode),
	.rst_n(rst_n),
	.message(message),
	.CRC(CRC),
  // Output signals
	.out_valid(out_valid),
	.out(out)
);


PATTERN I_PATTERN
(
   // Input signals
	.clk_1(clk_1),
	.clk_2(clk_2),
	.clk_3(clk_3),
	.in_valid(in_valid),
	.mode(mode),
	.rst_n(rst_n),
	.message(message),
	.CRC(CRC),
  // Output signals
	.out_valid(out_valid),
	.out(out)
);

endmodule