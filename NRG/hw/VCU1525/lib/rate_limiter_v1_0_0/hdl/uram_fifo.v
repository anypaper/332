`timescale 1ns/1ns
module uram_fifo #(
	parameter WIDTH = 32,  // 1 to 4096
	parameter DEPTH = 1024 // 16 to 4194304
)(
	input	clk,
	input	rst,

	input	wr_en,
	input [WIDTH-1:0]	din,
	
	input	rd_en,
	output [WIDTH-1:0]	dout,
	output 	empty,
	output 	full,
	output	almost_empty,	 
	output	almost_full
);

xpm_fifo_sync #(
	.FIFO_MEMORY_TYPE     ("uram"),
	.ECC_MODE             ("no_ecc"),
	.FIFO_WRITE_DEPTH     (DEPTH),
	.WRITE_DATA_WIDTH     (WIDTH),
	.WR_DATA_COUNT_WIDTH  (1),
	.PROG_FULL_THRESH     (10),
	.FULL_RESET_VALUE     (0),
	.USE_ADV_FEATURES     ("0707"),
	.READ_MODE            ("fwft"),
	.FIFO_READ_LATENCY    (1),
	.READ_DATA_WIDTH      (WIDTH),
	.RD_DATA_COUNT_WIDTH  (1),
	.PROG_EMPTY_THRESH    (10),
	.DOUT_RESET_VALUE     ("0"),
	.WAKEUP_TIME          (0)
) u_xpm_fifo_sync (
	// Common module ports
	.sleep           (),
	.rst             (rst),
	
	// Write Domain ports
	.wr_clk          (clk),
	.wr_en           (wr_en),
	.din             (din),
	.full            (full),
	.prog_full       (),
	.wr_data_count   (),
	.overflow        (),
	.wr_rst_busy     (),
	.almost_full     (almost_full),
	.wr_ack          (),
	
	// Read Domain ports
	.rd_en           (rd_en),
	.dout            (dout),
	.empty           (empty),
	.prog_empty      (),
	.rd_data_count   (),
	.underflow       (),
	.rd_rst_busy     (),
	.almost_empty    (almost_empty),
	.data_valid      (),
	
	// ECC Related ports
	.injectsbiterr   (),
	.injectdbiterr   (),
	.sbiterr         (),
	.dbiterr         () 
);

endmodule

