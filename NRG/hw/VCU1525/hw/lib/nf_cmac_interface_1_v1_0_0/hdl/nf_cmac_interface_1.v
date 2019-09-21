`timescale 1ns / 1ps
module nf_cmac_interface_1 #(
	parameter C_M_AXIS_DATA_WIDTH=512,
	parameter C_S_AXIS_DATA_WIDTH=512,
	parameter C_M_AXIS_TUSER_WIDTH=128,
	parameter C_S_AXIS_TUSER_WIDTH=128,
	parameter RS_FEC = "DISABLE"
) (

	input        axis_aclk,
	input        axis_resetn,

	input [C_S_AXIS_DATA_WIDTH - 1:0]          s_axis_tdata,
	input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0]  s_axis_tkeep,
	input [C_S_AXIS_TUSER_WIDTH-1:0]           s_axis_tuser,
	input                                      s_axis_tvalid,
	output                                     s_axis_tready,
	input                                      s_axis_tlast,

	output [C_M_AXIS_DATA_WIDTH - 1:0]         m_axis_tdata,
	output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_tkeep,
	output [C_M_AXIS_TUSER_WIDTH-1:0]          m_axis_tuser,
	output                                     m_axis_tvalid,
	input                                      m_axis_tready,
	output                                     m_axis_tlast,

	input        QSFP_CLOCK_P,
	input        QSFP_CLOCK_N,

	output       QSFP_FS0,
	output       QSFP_FS1,

	input        QSFP_INTL,
	output       QSFP_LPMODE,
	input        QSFP_MODPRSL,
	output       QSFP_MODSELL,
	output       QSFP_RESETL,

	output [3:0] QSFP_TX_P,
	output [3:0] QSFP_TX_N,
	input  [3:0] QSFP_RX_P,
	input  [3:0] QSFP_RX_N,
	
	input  [7:0] interface_number,
	input        sys_clk,
	input        sys_rst
);

localparam RS_FEC_BIT = (RS_FEC == "ENABLE") ? 1'b1 :
                        (RS_FEC == "DISABLE") ? 1'b0 : 1'b0;

///* clock infrastracture for cmac */
//wire sysclk_300;
//IBUFDS IBUFDS_sysclk_300 (
//	.I(SYSCLK0_300_P),
//	.IB(SYSCLK0_300_N),
//	.O(sysclk_300)
//);
//
//wire baseclk;
//reg clk_div = 1'b0;
//always @ (posedge sysclk_300)
//	clk_div <= ~clk_div;
//BUFG bufg_clk150 (
//	.I  (clk_div),
//	.O  (baseclk)
//);
//
//reg [13:0] cold_counter = 14'd0;
//reg sys_rst;
//always @ (posedge sysclk_300) begin
//	if (cold_counter != 14'h3fff) begin
//		cold_counter <= cold_counter + 14'd1;
//		sys_rst <= 1'b1;
//	end else begin
//		sys_rst <= 1'b0;
//	end
//end

/* Assignment of QSFP0 and QSFP1 */
assign QSFP_FS1 = 1'b1;
assign QSFP_FS0 = 1'b0;

assign QSFP_LPMODE = 1'b0;
assign QSFP_MODSELL = 1'b0;
assign QSFP_RESETL = 1'b1;

wire [C_S_AXIS_DATA_WIDTH - 1:0]         m_axis_0_tdata; 
wire [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_0_tkeep;
wire                                     m_axis_0_tvalid;
wire                                     m_axis_0_tuser;
wire                                     m_axis_0_tready;
wire                                     m_axis_0_tlast;

wire [C_S_AXIS_DATA_WIDTH - 1:0]         s_axis_0_tdata; 
wire [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_0_tkeep;
wire                                     s_axis_0_tvalid;
wire                                     s_axis_0_tuser;
wire                                     s_axis_0_tready;
wire                                     s_axis_0_tlast;

// wires for QSFP0 and QSFP1
wire tx0usrclk2, tx1usrclk2;

wire usr_rx0_reset, usr_rx1_reset;

wire rx0_reset, rx1_reset;
wire ctl_rx_enable;
wire ctl_rx_force_resync;
wire ctl_rx_test_pattern;

wire stat0_rx_aligned;

wire [55:0] rx0_preambleout, rx1_preambleout;

wire usr_tx0_reset, usr_tx1_reset;
wire tx0_reset, tx1_reset;
wire tx0_rdyout, tx1_rdyout;
wire [55:0] tx0_preamblein, tx1_preamblein;

wire tx0_ovfout, tx1_ovfout;
wire tx0_unfout, tx1_unfout;

wire [11:0] gt0loopback_in = 12'h0, gt1loopback_in = 12'h0; 

wire           ctl0_rx_enable;
wire           ctl0_rx_force_resync;
wire           ctl0_rx_test_pattern;
wire           ctl0_rsfec_ieee_error_indication_mode;
wire           ctl0_rx_rsfec_enable;
wire           ctl0_rx_rsfec_enable_correction;
wire           ctl0_rx_rsfec_enable_indication;

wire           ctl0_tx_enable;
wire           ctl0_tx_send_idle;
wire           ctl0_tx_send_rfi;
wire           ctl0_tx_send_lfi;
wire           ctl0_tx_test_pattern;
wire           ctl0_tx_rsfec_enable;

wire           ctl0_autoneg_enable;
wire           ctl0_autoneg_bypass;
wire [7:0]     ctl0_an_nonce_seed;
wire           ctl0_an_pseudo_sel;
wire           ctl0_restart_negotiation;
wire           ctl0_an_local_fault;
wire           ctl0_an_pause;
wire           ctl0_an_asmdir;
wire           ctl0_an_fec_25g_rs_request;
wire           ctl0_an_loc_np;
wire           ctl0_an_lp_np_ack;
wire           ctl0_an_cl91_fec_request;
wire           ctl0_an_cl91_fec_ability;
wire           ctl0_an_ability_1000base_kx;
wire           ctl0_an_ability_10gbase_kx4;
wire           ctl0_an_ability_10gbase_kr;
wire           ctl0_an_ability_40gbase_kr4;
wire           ctl0_an_ability_40gbase_cr4;
wire           ctl0_an_ability_100gbase_cr10;
wire           ctl0_an_ability_100gbase_kp4;
wire           ctl0_an_ability_100gbase_kr4;
wire           ctl0_an_ability_100gbase_cr4;
wire           ctl0_an_ability_25gbase_krcr_s;
wire           ctl0_an_ability_25gbase_krcr;
wire           ctl0_an_ability_25gbase_kr1;
wire           ctl0_an_ability_25gbase_cr1;
wire           ctl0_an_ability_50gbase_kr2;
wire           ctl0_an_ability_50gbase_cr2;
wire           ctl0_lt_training_enable;
wire           ctl0_lt_restart_training;
wire [3:0]     ctl0_lt_rx_trained;
wire [3:0]     ctl0_lt_preset_to_tx;
wire [3:0]     ctl0_lt_initialize_to_tx;
wire [10:0]    ctl0_lt_pseudo_seed0;
wire [1:0]     ctl0_lt_k_p1_to_tx0;
wire [1:0]     ctl0_lt_k0_to_tx0;
wire [1:0]     ctl0_lt_k_m1_to_tx0;
wire [1:0]     ctl0_lt_stat_p1_to_tx0;
wire [1:0]     ctl0_lt_stat0_to_tx0;
wire [1:0]     ctl0_lt_stat_m1_to_tx0;
wire [10:0]    ctl0_lt_pseudo_seed1;
wire [1:0]     ctl0_lt_k_p1_to_tx1;
wire [1:0]     ctl0_lt_k0_to_tx1;
wire [1:0]     ctl0_lt_k_m1_to_tx1;
wire [1:0]     ctl0_lt_stat_p1_to_tx1;
wire [1:0]     ctl0_lt_stat0_to_tx1;
wire [1:0]     ctl0_lt_stat_m1_to_tx1;
wire [10:0]    ctl0_lt_pseudo_seed2;
wire [1:0]     ctl0_lt_k_p1_to_tx2;
wire [1:0]     ctl0_lt_k0_to_tx2;
wire [1:0]     ctl0_lt_k_m1_to_tx2;
wire [1:0]     ctl0_lt_stat_p1_to_tx2;
wire [1:0]     ctl0_lt_stat0_to_tx2;
wire [1:0]     ctl0_lt_stat_m1_to_tx2;
wire [10:0]    ctl0_lt_pseudo_seed3;
wire [1:0]     ctl0_lt_k_p1_to_tx3;
wire [1:0]     ctl0_lt_k0_to_tx3;
wire [1:0]     ctl0_lt_k_m1_to_tx3;
wire [1:0]     ctl0_lt_stat_p1_to_tx3;
wire [1:0]     ctl0_lt_stat0_to_tx3;
wire [1:0]     ctl0_lt_stat_m1_to_tx3;
wire [1:0]     stat0_an_link_cntl_1000base_kx;
wire [1:0]     stat0_an_link_cntl_10gbase_kx4;
wire [1:0]     stat0_an_link_cntl_10gbase_kr;
wire [1:0]     stat0_an_link_cntl_40gbase_kr4;
wire [1:0]     stat0_an_link_cntl_40gbase_cr4;
wire [1:0]     stat0_an_link_cntl_100gbase_cr10;
wire [1:0]     stat0_an_link_cntl_100gbase_kp4;
wire [1:0]     stat0_an_link_cntl_100gbase_kr4;
wire [1:0]     stat0_an_link_cntl_100gbase_cr4;
wire [1:0]     stat0_an_link_cntl_25gbase_krcr_s;
wire [1:0]     stat0_an_link_cntl_25gbase_krcr;
wire           stat0_an_fec_enable;
wire           stat0_an_tx_pause_enable;
wire           stat0_an_rx_pause_enable;
wire           stat0_an_autoneg_complete;
wire           stat0_an_parallel_detection_fault;
wire           stat0_an_start_tx_disable;
wire           stat0_an_start_an_good_check;
wire           stat0_an_lp_ability_1000base_kx;
wire           stat0_an_lp_ability_10gbase_kx4;
wire           stat0_an_lp_ability_10gbase_kr;
wire           stat0_an_lp_ability_40gbase_kr4;
wire           stat0_an_lp_ability_40gbase_cr4;
wire           stat0_an_lp_ability_100gbase_cr10;
wire           stat0_an_lp_ability_100gbase_kp4;
wire           stat0_an_lp_ability_100gbase_kr4;
wire           stat0_an_lp_ability_100gbase_cr4;
wire           stat0_an_lp_ability_25gbase_krcr_s;
wire           stat0_an_lp_ability_25gbase_krcr;
wire           stat0_an_lp_pause;
wire           stat0_an_lp_asm_dir;
wire           stat0_an_lp_rf;
wire           stat0_an_lp_fec_10g_ability;
wire           stat0_an_lp_fec_10g_request;
wire           stat0_an_lp_fec_25g_rs_request;
wire           stat0_an_lp_fec_25g_baser_request;
wire           stat0_an_lp_autoneg_able;
wire           stat0_an_lp_ability_valid;
wire           stat0_an_loc_np_ack;
wire           stat0_an_lp_np;
wire           stat0_an_rxcdrhold;
wire [1:0]     stat0_an_link_cntl_25gbase_kr1;
wire           stat0_an_lp_ability_25gbase_kr1;
wire [1:0]     stat0_an_link_cntl_25gbase_cr1;
wire           stat0_an_lp_ability_25gbase_cr1;
wire [1:0]     stat0_an_link_cntl_50gbase_kr2;
wire           stat0_an_lp_ability_50gbase_kr2;
wire [1:0]     stat0_an_link_cntl_50gbase_cr2;
wire           stat0_an_lp_ability_50gbase_cr2;
wire [3:0]     stat0_an_lp_ability_extended_fec;
wire           stat0_an_rs_fec_enable;
wire           stat0_an_lp_extended_ability_valid;
wire [3:0]     stat0_lt_signal_detect;
wire [3:0]     stat0_lt_training;
wire [3:0]     stat0_lt_training_fail;
wire [3:0]     stat0_lt_rx_sof;
wire [3:0]     stat0_lt_frame_lock;
wire [3:0]     stat0_lt_preset_from_rx;
wire [3:0]     stat0_lt_initialize_from_rx;
wire [1:0]     stat0_lt_k_p1_from_rx0;
wire [1:0]     stat0_lt_k0_from_rx0;
wire [1:0]     stat0_lt_k_m1_from_rx0;
wire [1:0]     stat0_lt_stat_p1_from_rx0;
wire [1:0]     stat0_lt_stat0_from_rx0;
wire [1:0]     stat0_lt_stat_m1_from_rx0;
wire [1:0]     stat0_lt_k_p1_from_rx1;
wire [1:0]     stat0_lt_k0_from_rx1;
wire [1:0]     stat0_lt_k_m1_from_rx1;
wire [1:0]     stat0_lt_stat_p1_from_rx1;
wire [1:0]     stat0_lt_stat0_from_rx1;
wire [1:0]     stat0_lt_stat_m1_from_rx1;
wire [1:0]     stat0_lt_k_p1_from_rx2;
wire [1:0]     stat0_lt_k0_from_rx2;
wire [1:0]     stat0_lt_k_m1_from_rx2;
wire [1:0]     stat0_lt_stat_p1_from_rx2;
wire [1:0]     stat0_lt_stat0_from_rx2;
wire [1:0]     stat0_lt_stat_m1_from_rx2;
wire [1:0]     stat0_lt_k_p1_from_rx3;
wire [1:0]     stat0_lt_k0_from_rx3;
wire [1:0]     stat0_lt_k_m1_from_rx3;
wire [1:0]     stat0_lt_stat_p1_from_rx3;
wire [1:0]     stat0_lt_stat0_from_rx3;
wire [1:0]     stat0_lt_stat_m1_from_rx3;
wire [47:0]    an0_loc_np_data;
wire [47:0]    an0_lp_np_data;
wire [3:0]     lt0_tx_sof;


cmac_interface_1 u_cmac_1 ( 
	.sys_reset              (sys_rst),
	.init_clk               (sys_clk),

	.gt_ref_clk_p           (QSFP_CLOCK_P),
	.gt_ref_clk_n           (QSFP_CLOCK_N),
	.gt_rxp_in              (QSFP_RX_P),
	.gt_rxn_in              (QSFP_RX_N),
	.gt_txp_out             (QSFP_TX_P),
	.gt_txn_out             (QSFP_TX_N),
	.gt_txusrclk2           (tx0usrclk2),
	.gt_loopback_in         (gt0loopback_in),
	.gt_rxrecclkout         (),
	.gt_powergoodout        (),
	.gt_ref_clk_out         (),
	.gtwiz_reset_tx_datapath(1'b0),
	.gtwiz_reset_rx_datapath(1'b0),
	.rx_axis_tvalid         (s_axis_0_tvalid),
	.rx_axis_tdata          (s_axis_0_tdata),
	.rx_axis_tlast          (s_axis_0_tlast),
	.rx_axis_tkeep          (s_axis_0_tkeep),
	.rx_axis_tuser          (s_axis_0_tuser),
	.rx_otn_bip8_0          (),
	.rx_otn_bip8_1          (),
	.rx_otn_bip8_2          (),
	.rx_otn_bip8_3          (),
	.rx_otn_bip8_4          (),
	.rx_otn_data_0          (),
	.rx_otn_data_1          (),
	.rx_otn_data_2          (),
	.rx_otn_data_3          (),
	.rx_otn_data_4          (),
	.rx_otn_ena             (),
	.rx_otn_lane0           (),
	.rx_otn_vlmarker        (),
	.rx_preambleout         (rx0_preambleout),
	.usr_rx_reset           (usr_rx0_reset),
	.gt_rxusrclk2           (),
	.stat_rx_aligned        (stat0_rx_aligned),
	.stat_rx_aligned_err    (),
	.stat_rx_bad_code       (),
	.stat_rx_bad_fcs        (),
	.stat_rx_bad_preamble   (),
	.stat_rx_bad_sfd        (),
	.stat_rx_bip_err_0      (),
	.stat_rx_bip_err_1      (),
	.stat_rx_bip_err_10     (),
	.stat_rx_bip_err_11     (),
	.stat_rx_bip_err_12     (),
	.stat_rx_bip_err_13     (),
	.stat_rx_bip_err_14     (),
	.stat_rx_bip_err_15     (),
	.stat_rx_bip_err_16     (),
	.stat_rx_bip_err_17     (),
	.stat_rx_bip_err_18     (),
	.stat_rx_bip_err_19     (),
	.stat_rx_bip_err_2      (),
	.stat_rx_bip_err_3      (),
	.stat_rx_bip_err_4      (),
	.stat_rx_bip_err_5      (),
	.stat_rx_bip_err_6      (),
	.stat_rx_bip_err_7      (),
	.stat_rx_bip_err_8      (),
	.stat_rx_bip_err_9      (),
	.stat_rx_block_lock     (),
	.stat_rx_broadcast      (),
	.stat_rx_fragment       (),
	.stat_rx_framing_err_0  (),
	.stat_rx_framing_err_1  (),
	.stat_rx_framing_err_10 (),
	.stat_rx_framing_err_11 (),
	.stat_rx_framing_err_12 (),
	.stat_rx_framing_err_13 (),
	.stat_rx_framing_err_14 (),
	.stat_rx_framing_err_15 (),
	.stat_rx_framing_err_16 (),
	.stat_rx_framing_err_17 (),
	.stat_rx_framing_err_18 (),
	.stat_rx_framing_err_19 (),
	.stat_rx_framing_err_2  (),
	.stat_rx_framing_err_3  (),
	.stat_rx_framing_err_4  (),
	.stat_rx_framing_err_5  (),
	.stat_rx_framing_err_6  (),
	.stat_rx_framing_err_7  (),
	.stat_rx_framing_err_8  (),
	.stat_rx_framing_err_9  (),
	.stat_rx_framing_err_valid_0       (),
	.stat_rx_framing_err_valid_1       (),
	.stat_rx_framing_err_valid_10      (),
	.stat_rx_framing_err_valid_11      (),
	.stat_rx_framing_err_valid_12      (),
	.stat_rx_framing_err_valid_13      (),
	.stat_rx_framing_err_valid_14      (),
	.stat_rx_framing_err_valid_15      (),
	.stat_rx_framing_err_valid_16      (),
	.stat_rx_framing_err_valid_17      (),
	.stat_rx_framing_err_valid_18      (),
	.stat_rx_framing_err_valid_19      (),
	.stat_rx_framing_err_valid_2       (),
	.stat_rx_framing_err_valid_3       (),
	.stat_rx_framing_err_valid_4       (),
	.stat_rx_framing_err_valid_5       (),
	.stat_rx_framing_err_valid_6       (),
	.stat_rx_framing_err_valid_7       (),
	.stat_rx_framing_err_valid_8       (),
	.stat_rx_framing_err_valid_9       (),
	.stat_rx_got_signal_os             (),
	.stat_rx_hi_ber                    (),
	.stat_rx_inrangeerr                (),
	.stat_rx_internal_local_fault      (),
	.stat_rx_jabber                    (),
	.stat_rx_local_fault               (),
	.stat_rx_mf_err                    (),
	.stat_rx_mf_len_err                (),
	.stat_rx_mf_repeat_err             (),
	.stat_rx_misaligned                (),
	.stat_rx_multicast                 (),
	.stat_rx_oversize                  (),
	.stat_rx_packet_1024_1518_bytes    (),
	.stat_rx_packet_128_255_bytes      (),
	.stat_rx_packet_1519_1522_bytes    (),
	.stat_rx_packet_1523_1548_bytes    (),
	.stat_rx_packet_1549_2047_bytes    (),
	.stat_rx_packet_2048_4095_bytes    (),
	.stat_rx_packet_256_511_bytes      (),
	.stat_rx_packet_4096_8191_bytes    (),
	.stat_rx_packet_512_1023_bytes     (),
	.stat_rx_packet_64_bytes           (),
	.stat_rx_packet_65_127_bytes       (),
	.stat_rx_packet_8192_9215_bytes    (),
	.stat_rx_packet_bad_fcs            (),
	.stat_rx_packet_large              (),
	.stat_rx_packet_small              (),
	.core_rx_reset                     (1'b0),
	.rx_clk                            (tx0usrclk2),
	.stat_rx_received_local_fault      (),
	.stat_rx_remote_fault              (),
	.stat_rx_status                    (),
	.stat_rx_stomped_fcs               (),
	.stat_rx_synced                    (),
	.stat_rx_synced_err                (),
	.stat_rx_test_pattern_mismatch     (),
	.stat_rx_toolong                   (),
	.stat_rx_total_bytes               (),
	.stat_rx_total_good_bytes          (),
	.stat_rx_total_good_packets        (),
	.stat_rx_total_packets             (),
	.stat_rx_truncated                 (),
	.stat_rx_undersize                 (),
	.stat_rx_unicast                   (),
	.stat_rx_vlan                      (),
	.stat_rx_pcsl_demuxed              (),
	.stat_rx_pcsl_number_0             (),
	.stat_rx_pcsl_number_1             (),
	.stat_rx_pcsl_number_10            (),
	.stat_rx_pcsl_number_11            (),
	.stat_rx_pcsl_number_12            (),
	.stat_rx_pcsl_number_13            (),
	.stat_rx_pcsl_number_14            (),
	.stat_rx_pcsl_number_15            (),
	.stat_rx_pcsl_number_16            (),
	.stat_rx_pcsl_number_17            (),
	.stat_rx_pcsl_number_18            (),
	.stat_rx_pcsl_number_19            (),
	.stat_rx_pcsl_number_2             (),
	.stat_rx_pcsl_number_3             (),
	.stat_rx_pcsl_number_4             (),
	.stat_rx_pcsl_number_5             (),
	.stat_rx_pcsl_number_6             (),
	.stat_rx_pcsl_number_7             (),
	.stat_rx_pcsl_number_8             (),
	.stat_rx_pcsl_number_9             (),
	.stat_rx_rsfec_am_lock0            (),
	.stat_rx_rsfec_am_lock1            (),
	.stat_rx_rsfec_am_lock2            (),
	.stat_rx_rsfec_am_lock3            (),
	.stat_rx_rsfec_corrected_cw_inc    (),
	.stat_rx_rsfec_cw_inc              (),
	.stat_rx_rsfec_err_count0_inc      (),
	.stat_rx_rsfec_err_count1_inc      (),
	.stat_rx_rsfec_err_count2_inc      (),
	.stat_rx_rsfec_err_count3_inc      (),
	.stat_rx_rsfec_hi_ser              (),
	.stat_rx_rsfec_lane_alignment_status (),
	.stat_rx_rsfec_lane_fill_0           (),
	.stat_rx_rsfec_lane_fill_1           (),
	.stat_rx_rsfec_lane_fill_2           (),
	.stat_rx_rsfec_lane_fill_3           (),
	.stat_rx_rsfec_lane_mapping          (),
	.stat_rx_rsfec_uncorrected_cw_inc    (),
//	.stat_rx_lane0_vlm_bip7              (),
//	.stat_rx_lane0_vlm_bip7_valid        (),
	.stat_tx_bad_fcs                     (),
	.stat_tx_broadcast                   (),
	.stat_tx_frame_error                 (),
	.stat_tx_local_fault                 (),
	.stat_tx_multicast                   (),
	.stat_tx_packet_1024_1518_bytes      (),
	.stat_tx_packet_128_255_bytes        (),
	.stat_tx_packet_1519_1522_bytes      (),
	.stat_tx_packet_1523_1548_bytes      (),
	.stat_tx_packet_1549_2047_bytes      (),
	.stat_tx_packet_2048_4095_bytes      (),
	.stat_tx_packet_256_511_bytes        (),
	.stat_tx_packet_4096_8191_bytes      (),
	.stat_tx_packet_512_1023_bytes       (),
	.stat_tx_packet_64_bytes             (),
	.stat_tx_packet_65_127_bytes         (),
	.stat_tx_packet_8192_9215_bytes      (),
	.stat_tx_packet_large                (),
	.stat_tx_packet_small                (),
	.stat_tx_total_bytes                 (),
	.stat_tx_total_good_bytes            (),
	.stat_tx_total_good_packets          (),
	.stat_tx_total_packets               (),
	.stat_tx_unicast                     (),
	.stat_tx_vlan                        (),

	.ctl_rx_enable                       (ctl0_rx_enable                       ),
	.ctl_rx_force_resync                 (ctl0_rx_force_resync                 ),
	.ctl_rx_test_pattern                 (ctl0_rx_test_pattern                 ),
	.ctl_rsfec_ieee_error_indication_mode(ctl0_rsfec_ieee_error_indication_mode),
	.ctl_rx_rsfec_enable                 (ctl0_rx_rsfec_enable                 ),
	.ctl_rx_rsfec_enable_correction      (ctl0_rx_rsfec_enable_correction      ),
	.ctl_rx_rsfec_enable_indication      (ctl0_rx_rsfec_enable_indication      ),
	.ctl_tx_enable                       (ctl0_tx_enable      ),
	.ctl_tx_send_idle                    (ctl0_tx_send_idle   ),
	.ctl_tx_send_rfi                     (ctl0_tx_send_rfi    ),
	.ctl_tx_send_lfi                     (ctl0_tx_send_lfi    ),
	.ctl_tx_test_pattern                 (ctl0_tx_test_pattern),
	.ctl_tx_rsfec_enable                 (ctl0_tx_rsfec_enable),
	.core_tx_reset                       (1'b0),
	.tx_ovfout                           (tx0_ovfout),
	.tx_unfout                           (tx0_unfout),
	.tx_axis_tready                      (m_axis_0_tready),
	.tx_axis_tvalid                      (m_axis_0_tvalid),
	.tx_axis_tdata                       (m_axis_0_tdata),
	.tx_axis_tlast                       (m_axis_0_tlast),
	.tx_axis_tkeep                       (m_axis_0_tkeep),
	.tx_axis_tuser                       (m_axis_0_tuser),
	.tx_preamblein                       (tx0_preamblein),
	.usr_tx_reset                        (usr_tx0_reset),

	.core_drp_reset                      (1'b0),
	.drp_clk                             (1'b0),
	.drp_addr                            (10'd0),
	.drp_di                              (16'd0),
	.drp_en                              (1'b0),
	.drp_do                              (),
	.drp_rdy                             (),
	.drp_we                              (1'b0) 
);


assign ctl0_rx_rsfec_enable = RS_FEC_BIT;
assign ctl0_tx_rsfec_enable = RS_FEC_BIT;
assign ctl0_rsfec_ieee_error_indication_mode = 1'b0;
assign ctl0_rx_rsfec_enable_correction = 1'b0;
assign ctl0_rx_rsfec_enable_indication = 1'b0;

nf_10g_attachment #(
    // Master AXI Stream Data Width    
	.C_M_AXIS_DATA_WIDTH       (512),
	.C_S_AXIS_DATA_WIDTH       (512),
	.C_M_AXIS_TUSER_WIDTH      (128),
	.C_S_AXIS_TUSER_WIDTH      (128),    
	.C_DEFAULT_VALUE_ENABLE    (1)
) u_att_0 (
  // 10GE block clk & rst 
	.clk156                    (tx0usrclk2), 
	.areset_clk156             (usr_tx0_reset), 
  
  // RX MAC 64b@clk156 (no backpressure) -> rx_queue 64b@axis_clk
	.m_axis_mac_tdata          (s_axis_0_tdata),
	.m_axis_mac_tkeep          (s_axis_0_tkeep),
	.m_axis_mac_tvalid         (s_axis_0_tvalid), 
	.m_axis_mac_tuser          (1'b0/*m_lbus2axis_0_tuser*/),       // valid frame
	.m_axis_mac_tlast          (s_axis_0_tlast),
  

  // tx_queue 64b@axis_clk -> mac 64b@clk156
	.s_axis_mac_tdata          (m_axis_0_tdata),
	.s_axis_mac_tkeep          (m_axis_0_tkeep),
	.s_axis_mac_tvalid         (m_axis_0_tvalid),
	.s_axis_mac_tuser          (m_axis_0_tuser),      //underrun
	.s_axis_mac_tlast          (m_axis_0_tlast),	
	.s_axis_mac_tready         (m_axis_0_tready),
   
   
  // TX/RX DATA channels  
	.interface_number          (8'b00000001),
  
  // SUME pipeline clk & rst 
	.axis_aclk                 (axis_aclk),
	.axis_aresetn              (axis_resetn),
     
  // input from ref pipeline 256b -> MAC
	.s_axis_pipe_tdata         (s_axis_tdata), 
	.s_axis_pipe_tkeep         (s_axis_tkeep), 
	.s_axis_pipe_tlast         (s_axis_tlast), 
	.s_axis_pipe_tuser         (s_axis_tuser), 
	.s_axis_pipe_tvalid        (s_axis_tvalid),
	.s_axis_pipe_tready        (s_axis_tready),
   
  // output to ref pipeline 256b -> DMA
	.m_axis_pipe_tdata         (m_axis_tdata), 
	.m_axis_pipe_tkeep         (m_axis_tkeep), 
	.m_axis_pipe_tlast         (m_axis_tlast), 
	.m_axis_pipe_tuser         (m_axis_tuser), 
	.m_axis_pipe_tvalid        (m_axis_tvalid),
	.m_axis_pipe_tready        (m_axis_tready) 
);

cmac1_startup_seq u_startup_seq (
	.clk                 (tx0usrclk2),
	.rst                 (usr_tx0_reset),
	/* RX */
	.rx_aligned          (stat0_rx_aligned),
	.ctl_rx_force_resync (ctl0_rx_force_resync),
	.ctl_rx_test_pattern (ctl0_rx_test_pattern),
	.rx_reset            (),
	/*TX*/
	.tx_preamblein       (tx0_preamblein),
	.tx_reset            (tx0_reset),
	.ctl_tx_send_idle    (ctl0_tx_send_idle),
	.ctl_tx_test_pattern (ctl0_tx_test_pattern),
	.ctl_rx_enable       (ctl0_rx_enable  ),
	.ctl_tx_enable       (ctl0_tx_enable  ),
	.ctl_tx_send_lfi     (ctl0_tx_send_lfi),
	.ctl_tx_send_rfi     (ctl0_tx_send_rfi)
);

endmodule
