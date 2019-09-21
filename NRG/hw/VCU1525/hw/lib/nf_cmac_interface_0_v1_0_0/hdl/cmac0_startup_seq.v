module cmac0_startup_seq (
	input	clk,
	input 	rst,
	/* RX */
	input	rx_aligned,
	output  ctl_rx_force_resync,
	output  ctl_rx_test_pattern,
	output  rx_reset,
	/*TX*/
	output [55:0]	tx_preamblein,
	output 	tx_reset,
	output 	ctl_tx_send_idle,
	output 	ctl_tx_test_pattern,
	output reg	ctl_rx_enable,
	output reg	ctl_tx_enable,
	output reg	ctl_tx_send_lfi,
	output reg	ctl_tx_send_rfi
);

assign tx_preamblein = 56'd0;
assign tx_reset = 1'b0;
assign ctl_tx_send_idle = 1'b0;
assign ctl_tx_test_pattern = 1'b0;

assign ctl_rx_force_resync = 1'b0;
assign ctl_rx_test_pattern = 1'b0;
assign rx_reset = 1'b0;
/*********************************************************
 From pp209 of pg203-cmac-usplus.pdf 
   1. Assert the below signals:
         ctl_rx_enable = 1’b1
         ctl_tx_send_lfi = 1’b1
         ctl_tx_send_rfi = 1’b1
   2. Wait for RX_aligned then deassert/assert the below 
      signals:
         ctl_tx_send_lfi = 1’b0 
         ctl_tx_send_rfi = 1’b0
         ctl_tx_enable = 1’b1
 *********************************************************/
reg [1:0] state;

localparam IDLE    = 0;
localparam DEFAULT = 1;
localparam ALIGNED = 2;
localparam FINISH  = 3;

always @ (posedge clk) begin
	if (rst) begin
		state <= IDLE;
		ctl_rx_enable   <= 1'b0;
		ctl_tx_enable   <= 1'b0;
		ctl_tx_send_lfi <= 1'b0;
		ctl_tx_send_rfi <= 1'b0;
	end else begin
		case(state)
			IDLE   : begin
				state <= DEFAULT;
				ctl_rx_enable   <= 1'b0;
				ctl_tx_enable   <= 1'b0;
				ctl_tx_send_lfi <= 1'b0;
				ctl_tx_send_rfi <= 1'b0;
			end
			DEFAULT    : begin
				if (rx_aligned) 
					state <= ALIGNED;
				ctl_rx_enable   <= 1'b1;
    			ctl_tx_send_lfi <= 1'b1;
    			ctl_tx_send_rfi <= 1'b1;
			end
			ALIGNED: begin
				state <= FINISH;
    			ctl_tx_enable   <= 1'b1;
    			ctl_tx_send_lfi <= 1'b0;
    			ctl_tx_send_rfi <= 1'b0;
			end
			FINISH : state <= FINISH;
		endcase
	end
end

endmodule
