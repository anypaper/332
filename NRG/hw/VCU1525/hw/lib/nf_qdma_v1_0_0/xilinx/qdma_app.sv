//-----------------------------------------------------------------------------
//
// (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : The Xilinx PCI Express DMA 
// File       : qdma_app.sv
// Version    : 5.0
//-----------------------------------------------------------------------------

`timescale 1ps / 1ps
`include "qdma_stm_defines.svh"
module qdma_app #(
  parameter TCQ                        = 1,
  parameter C_M_AXI_ID_WIDTH           = 4,
  parameter PL_LINK_CAP_MAX_LINK_WIDTH = 16,
  parameter C_DATA_WIDTH               = 512,
  parameter C_M_AXI_DATA_WIDTH         = C_DATA_WIDTH,
  parameter C_S_AXI_DATA_WIDTH         = C_DATA_WIDTH,
  parameter C_S_AXIS_DATA_WIDTH        = C_DATA_WIDTH,
  parameter C_M_AXIS_DATA_WIDTH        = C_DATA_WIDTH,
  parameter C_M_AXIS_RQ_USER_WIDTH     = ((C_DATA_WIDTH == 512) ? 137 : 62),
  parameter C_S_AXIS_CQP_USER_WIDTH    = ((C_DATA_WIDTH == 512) ? 183 : 88),
  parameter C_M_AXIS_RC_USER_WIDTH     = ((C_DATA_WIDTH == 512) ? 161 : 75),
  parameter C_S_AXIS_CC_USER_WIDTH     = ((C_DATA_WIDTH == 512) ?  81 : 33),
  parameter C_S_KEEP_WIDTH             = C_S_AXI_DATA_WIDTH / 32,
  parameter C_M_KEEP_WIDTH             = (C_M_AXI_DATA_WIDTH / 32),
  parameter C_XDMA_NUM_CHNL            = 4,

  parameter MAX_DATA_WIDTH    = 512,
  parameter C_H2C_TUSER_WIDTH = 55,
  parameter TM_DSC_BITS       = 16,
  parameter TDEST_BITS        = 16
)
(

  // AXI Lite Master Interface connections
  input  [31:0]   s_axil_awaddr,
  input           s_axil_awvalid,
  output          s_axil_awready,
  input  [31:0]   s_axil_wdata,
  input  [3:0]    s_axil_wstrb,
  input           s_axil_wvalid,
  output          s_axil_wready,
  output [1:0]    s_axil_bresp,
  output          s_axil_bvalid,
  input           s_axil_bready,
  input  [31:0]   s_axil_araddr,
  input           s_axil_arvalid,
  output          s_axil_arready,
  output [31:0]   s_axil_rdata,
  output [1:0]    s_axil_rresp,
  output          s_axil_rvalid,
  input           s_axil_rready,



  // System IO signals
  input         user_resetn,
  input         sys_rst_n,
  output        soft_reset_n,
  input  user_clk,
  input  user_lnk_up,

  input          usr_irq_out_fail,
  input          usr_irq_out_ack,
  output [4:0]   usr_irq_in_vec,
  output [7:0]   usr_irq_in_fnc,
  output reg     usr_irq_in_vld,
  output         st_rx_msg_rdy,
  input          st_rx_msg_valid,
  input          st_rx_msg_last,
  input [31:0]   st_rx_msg_data,

  input          tm_dsc_sts_vld,
  input          tm_dsc_sts_byp,
  input          tm_dsc_sts_qen,
  input          tm_dsc_sts_dir,
  input          tm_dsc_sts_mm,
  input          tm_dsc_sts_error,
  input [10:0]   tm_dsc_sts_qid,
  input [15:0]   tm_dsc_sts_avl,
  input          tm_dsc_sts_qinv,
  input          tm_dsc_sts_irq_arm,
  output         tm_dsc_sts_rdy,

  input          axis_c2h_status_drop,
  input          axis_c2h_status_valid,

  input          clk,
  input          rst_n,

  input  [7:0]     usr_flr_fnc,
  input             usr_flr_set,
  input             usr_flr_clr,
  output  reg [7:0] usr_flr_done_fnc,
  output            usr_flr_done_vld,

  input [C_DATA_WIDTH-1 :0]    m_axis_h2c_tdata /* synthesis syn_keep = 1 */,
  input [C_DATA_WIDTH/8-1 :0]  m_axis_h2c_dpar /* synthesis syn_keep = 1 */,
  input [10:0]                 m_axis_h2c_tuser_qid /* synthesis syn_keep = 1 */,
  input [2:0]                  m_axis_h2c_tuser_port_id,
  input                        m_axis_h2c_tuser_err,
  input [31:0]                 m_axis_h2c_tuser_mdata,
  input [5:0]                  m_axis_h2c_tuser_mty,
  input                        m_axis_h2c_tuser_zero_byte,
  input                        m_axis_h2c_tvalid /* synthesis syn_keep = 1 */,
  output                       m_axis_h2c_tready /* synthesis syn_keep = 1 */,
  input                        m_axis_h2c_tlast /* synthesis syn_keep = 1 */,

  output [C_DATA_WIDTH-1 :0]   s_axis_c2h_tdata /* synthesis syn_keep = 1 */,
  output [C_DATA_WIDTH/8-1 :0] s_axis_c2h_dpar /* synthesis syn_keep = 1 */,
  output                       s_axis_c2h_ctrl_marker /* synthesis syn_keep = 1 */,
  output [15:0]                s_axis_c2h_ctrl_len /* synthesis syn_keep = 1 */,
  output [10:0]                s_axis_c2h_ctrl_qid /* synthesis syn_keep = 1 */,
  output                       s_axis_c2h_ctrl_has_cmpt /* synthesis syn_keep = 1 */,
  output                       s_axis_c2h_tvalid /* synthesis syn_keep = 1 */,
  input                        s_axis_c2h_tready /* synthesis syn_keep = 1 */,
  output                       s_axis_c2h_tlast /* synthesis syn_keep = 1 */,
  output [5:0]                 s_axis_c2h_mty   /* synthesis syn_keep = 1 */ ,
  output [511:0]               s_axis_c2h_cmpt_tdata,
  output [1:0]                 s_axis_c2h_cmpt_size,
  output [15:0]                s_axis_c2h_cmpt_dpar,
  output                       s_axis_c2h_cmpt_tvalid,

  output [10:0] s_axis_c2h_cmpt_ctrl_qid,
  output [1:0]  s_axis_c2h_cmpt_ctrl_cmpt_type,
  output [15:0] s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id,
  output        s_axis_c2h_cmpt_ctrl_marker,
  output        s_axis_c2h_cmpt_ctrl_user_trig,
  output [2:0]  s_axis_c2h_cmpt_ctrl_col_idx,
  output [2:0]  s_axis_c2h_cmpt_ctrl_err_idx,
  input         s_axis_c2h_cmpt_tready,

  output        dsc_crdt_in_vld,
  input         dsc_crdt_in_rdy,
  output        dsc_crdt_in_dir,
  output        dsc_crdt_in_fence,
  output [10:0] dsc_crdt_in_qid,
  output [15:0] dsc_crdt_in_crdt,

  output [3:0]  leds
);

  // wire/reg declarations
  wire            sys_reset;
  reg  [25:0]     user_clk_heartbeat;
  wire [31:0]     s_axil_rdata_bram;

  // MDMA signals
  wire  m_axis_h2c_tready_lpbk;
  wire  m_axis_h2c_tready_int;

  // AXIS C2H packet wire

  wire [C_DATA_WIDTH-1:0]    s_axis_c2h_tdata_int;
  wire                       s_axis_c2h_ctrl_marker_int;
  wire [15:0]                s_axis_c2h_ctrl_len_int;
  wire [10:0]                s_axis_c2h_ctrl_qid_int ;
  wire                       s_axis_c2h_ctrl_has_cmpt_int ;
  wire [C_DATA_WIDTH/8-1:0]  s_axis_c2h_dpar_int;

  wire        s_axis_c2h_tvalid_lpbk;
  wire        s_axis_c2h_tlast_lpbk;
  wire [$clog2(MAX_DATA_WIDTH/8)-1:0]   s_axis_c2h_mty_lpbk;
  wire        s_axis_c2h_tvalid_int;
  wire        s_axis_c2h_tlast_int;
  wire [5:0]  s_axis_c2h_mty_int;

  // AXIS C2H tuser wire
  wire           s_axis_c2h_cmpt_tvalid_int;
  wire  [511:0]  s_axis_c2h_cmpt_tdata_int;
  wire  [1:0]    s_axis_c2h_cmpt_size_int;
  wire  [15:0]   s_axis_c2h_cmpt_dpar_int;
  wire           s_axis_c2h_cmpt_tready_int;

  wire  [10:0]   s_axis_c2h_cmpt_ctrl_qid_int;
  wire  [1:0]    s_axis_c2h_cmpt_ctrl_cmpt_type_int;
  wire  [15:0]   s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id_int;
  wire           s_axis_c2h_cmpt_ctrl_marker_int;
  wire           s_axis_c2h_cmpt_ctrl_user_trig_int;
  wire  [2:0]    s_axis_c2h_cmpt_ctrl_col_idx_int;
  wire  [2:0]    s_axis_c2h_cmpt_ctrl_err_idx_int;

  //HDR output to QDMA
  wire  c2h_stub_std_cmp_t       out_axis_cmp_data;
  wire  c2h_stub_std_cmp_ctrl_t  out_axis_cmp_ctrl;
  wire                           out_axis_cmp_tlast;
  wire                           out_axis_cmp_tvalid;
  wire                           out_axis_cmp_tready;

  //PLD output to QDMA
  wire mdma_c2h_axis_data_exdes_t     out_axis_pld_data;
  wire mdma_c2h_axis_ctrl_exdes_t     out_axis_pld_ctrl;
  wire [$clog2(MAX_DATA_WIDTH/8)-1:0] out_axis_pld_mty;
  wire                                out_axis_pld_tlast;
  wire                                out_axis_pld_tvalid;
  wire                                out_axis_pld_tready;


  wire [10:0]  c2h_num_pkt;
  wire [10:0]  c2h_st_qid;
  wire [15:0]  c2h_st_len;
  wire [31:0]  h2c_count;
  wire         h2c_match;
  wire         clr_h2c_match;
  wire         c2h_end;
  wire [31:0]  c2h_control;
  wire [10:0]  h2c_qid;
  wire [31:0]  cmpt_size;
  wire [255:0] wb_dat;

  wire [TM_DSC_BITS-1:0] credit_out;
  wire [TM_DSC_BITS-1:0] credit_needed;
  wire [TM_DSC_BITS-1:0] credit_perpkt_in;
  wire                   credit_updt;
  wire [15:0]            buf_count;

  wire        st_loopback;
  wire [1:0]  c2h_dsc_bypass;
  wire        h2c_dsc_bypass;
  wire byp_to_cmp;

  // looping back H2C Stream dsc bypass to C2H completion.
  assign byp_to_cmp = &c2h_dsc_bypass[1:0];



  // The sys_rst_n input is active low based on the core configuration
  assign sys_resetn = sys_rst_n;

  // Create a Clock Heartbeat
  always @(posedge user_clk) begin
    if(!sys_resetn) begin
      user_clk_heartbeat <= #TCQ 26'd0;
    end else begin
      user_clk_heartbeat <= #TCQ user_clk_heartbeat + 1'b1;
    end
  end

  //
  // Descriptor Credit in logic
  //
  reg start_c2h_d, start_c2h_d1;
  always @(posedge user_clk) begin
    if(!sys_resetn) begin
      start_c2h_d <= 1'b0;
      start_c2h_d1 <= 1'b0;
    end
    else begin
      start_c2h_d <= c2h_control[1];
      start_c2h_d1 <= start_c2h_d;
    end
   end
  assign dsc_crdt_in_vld   = (start_c2h_d & ~start_c2h_d1) & (c2h_dsc_bypass == 2'b10);
  assign dsc_crdt_in_dir   = start_c2h_d;
  assign dsc_crdt_in_fence = 1'b0;  // fix me
  assign dsc_crdt_in_qid   = c2h_st_qid;
  assign dsc_crdt_in_crdt  = credit_needed;

  user_control
  #(
    .C_DATA_WIDTH (C_DATA_WIDTH),
    .QID_MAX (2048),
    .PF0_M_AXILITE_ADDR_MSK( 32'h00000FFF),
    .PF1_M_AXILITE_ADDR_MSK( 32'h00000FFF),
    .PF2_M_AXILITE_ADDR_MSK( 32'h00000FFF),
    .PF3_M_AXILITE_ADDR_MSK( 32'h00000FFF),
    .PF0_VF_M_AXILITE_ADDR_MSK( 32'h00000FFF),
    .PF1_VF_M_AXILITE_ADDR_MSK( 32'h00000FFF),
    .PF2_VF_M_AXILITE_ADDR_MSK( 32'h00000FFF),
    .PF3_VF_M_AXILITE_ADDR_MSK( 32'h00000FFF),
    .PF0_PCIEBAR2AXIBAR( 32'h0000000000000000),
    .PF1_PCIEBAR2AXIBAR( 32'h0000000010000000),
    .PF2_PCIEBAR2AXIBAR( 32'h0000000020000000),
    .PF3_PCIEBAR2AXIBAR( 32'h0000000030000000),
    .PF0_VF_PCIEBAR2AXIBAR( 32'h0000000040000000),
    .PF1_VF_PCIEBAR2AXIBAR( 32'h0000000050000000),
    .PF2_VF_PCIEBAR2AXIBAR( 32'h0000000060000000),
    .PF3_VF_PCIEBAR2AXIBAR( 32'h0000000070000000),
    .TM_DSC_BITS (TM_DSC_BITS)
  )
  user_control_i
  (
    .axi_aclk (clk),
    .axi_aresetn    (rst_n),
    .single_bit_err_inject_reg (),
    .double_bit_err_inject_reg (),
    .m_axil_wvalid    (s_axil_wvalid),
    .m_axil_wready    (s_axil_wready),
    .m_axil_rvalid    (s_axil_rvalid),
    .m_axil_rready    (s_axil_rready),
    .m_axil_awaddr    (s_axil_awaddr),
    .m_axil_wdata     (s_axil_wdata),
    .m_axil_rdata     (s_axil_rdata),
    .m_axil_rdata_bram(s_axil_rdata_bram),
    .m_axil_araddr    (s_axil_araddr[31:0]),
    .m_axil_arvalid   (s_axil_arvalid),
    
    .soft_reset_n     (soft_reset_n),
    .st_loopback(st_loopback),
    .c2h_st_marker_rsp(c2h_st_marker_rsp),
    
    .axi_mm_h2c_valid (s_axi_wvalid),
    .axi_mm_h2c_ready (s_axi_wready),
    .axi_mm_c2h_valid (s_axi_rvalid),
    .axi_mm_c2h_ready (s_axi_rready),
    
    .axi_st_h2c_valid (m_axis_h2c_tvalid),
    .axi_st_h2c_ready (m_axis_h2c_tready),
    .axi_st_c2h_valid (s_axis_c2h_tvalid),
    .axi_st_c2h_ready (s_axis_c2h_tready),
    
    .c2h_st_qid    (c2h_st_qid),
    .c2h_control   (c2h_control),
    .c2h_num_pkt   (c2h_num_pkt),
    .clr_h2c_match (clr_h2c_match),
    .c2h_st_len    (c2h_st_len),
    .c2h_end       (c2h_end),
    .h2c_count     (h2c_count),
    .h2c_match     (h2c_match),
    .h2c_qid       (h2c_qid),
    .h2c_zero_byte (m_axis_h2c_tuser_zero_byte),
    
    .wb_dat(wb_dat),
    .buf_count(buf_count),
    .cmpt_size(cmpt_size),
    .h2c_dsc_bypass(h2c_dsc_bypass),
    .c2h_dsc_bypass(c2h_dsc_bypass),
    .axis_c2h_drop(axis_c2h_status_drop),
    .axis_c2h_drop_valid(axis_c2h_status_valid),
    
    .credit_out       (credit_out),
    .credit_updt      (credit_updt),
    .credit_perpkt_in (credit_perpkt_in),
    .credit_needed    (credit_needed),
    
    
    .usr_irq_in_vld  (usr_irq_in_vld),
    .usr_irq_in_vec  (usr_irq_in_vec),
    .usr_irq_in_fnc  (usr_irq_in_fnc),
    .usr_irq_out_ack (usr_irq_out_ack),
    .usr_irq_out_fail(usr_irq_out_fail),
    
    .st_rx_msg_rdy   (st_rx_msg_rdy),
    .st_rx_msg_valid (st_rx_msg_valid),
    .st_rx_msg_last  (st_rx_msg_last),
    .st_rx_msg_data  (st_rx_msg_data),
    .c2h_mm_marker_req (c2h_mm_marker_req),
    .c2h_mm_marker_rsp (c2h_mm_marker_rsp),
    .h2c_mm_marker_req (h2c_mm_marker_req),
    .h2c_mm_marker_rsp (h2c_mm_marker_rsp),
    .h2c_st_marker_req (h2c_st_marker_req),
    .h2c_st_marker_rsp (h2c_st_marker_rsp),
    
    .usr_flr_fnc      (usr_flr_fnc),
    .usr_flr_set      (usr_flr_set),
    .usr_flr_clr      (usr_flr_clr),
    .usr_flr_done_fnc (usr_flr_done_fnc),
    .usr_flr_done_vld (usr_flr_done_vld),
    .tm_dsc_sts_vld    (tm_dsc_sts_vld),
    .tm_dsc_sts_qen    (tm_dsc_sts_qen),
    .tm_dsc_sts_byp    (tm_dsc_sts_byp),
    .tm_dsc_sts_dir    (tm_dsc_sts_dir),
    .tm_dsc_sts_mm     (tm_dsc_sts_mm),
    .tm_dsc_sts_error  (tm_dsc_sts_error),
    .tm_dsc_sts_qid    (tm_dsc_sts_qid),
    .tm_dsc_sts_avl    (tm_dsc_sts_avl),
    .tm_dsc_sts_qinv   (tm_dsc_sts_qinv),
    .tm_dsc_sts_irq_arm(tm_dsc_sts_irq_arm),
    .tm_dsc_sts_rdy    (tm_dsc_sts_rdy)
  );

  wire mdma_h2c_axis_tuser_exdes_t   m_axis_h2c_tuser_net;
  assign m_axis_h2c_tuser_net = {m_axis_h2c_tuser_zero_byte,m_axis_h2c_tuser_mty,m_axis_h2c_tuser_mdata,m_axis_h2c_tuser_err,m_axis_h2c_tuser_port_id,m_axis_h2c_tuser_qid};

  assign s_axis_c2h_mty            = (st_loopback == 1'b1) ? s_axis_c2h_mty_lpbk        : s_axis_c2h_mty_int;
  assign s_axis_c2h_tlast          = (st_loopback == 1'b1) ? s_axis_c2h_tlast_lpbk      : s_axis_c2h_tlast_int;
  assign s_axis_c2h_tvalid         = (st_loopback == 1'b1) ? s_axis_c2h_tvalid_lpbk     : s_axis_c2h_tvalid_int;
  assign s_axis_c2h_tdata          = (st_loopback == 1'b1) ? out_axis_pld_data.tdata    : s_axis_c2h_tdata_int;
  assign s_axis_c2h_dpar           = (st_loopback == 1'b1) ? out_axis_pld_data.par      : s_axis_c2h_dpar_int;
  assign s_axis_c2h_ctrl_len       = (st_loopback == 1'b1) ? out_axis_pld_ctrl.len      : s_axis_c2h_ctrl_len_int;
  assign s_axis_c2h_ctrl_qid       = (st_loopback == 1'b1) ? out_axis_pld_ctrl.qid      : s_axis_c2h_ctrl_qid_int;
  assign s_axis_c2h_ctrl_marker    = (st_loopback == 1'b1) ? out_axis_pld_ctrl.marker   : s_axis_c2h_ctrl_marker_int;
  assign s_axis_c2h_ctrl_has_cmpt  = (st_loopback == 1'b1) ? out_axis_pld_ctrl.has_cmpt : s_axis_c2h_ctrl_has_cmpt_int;

  assign m_axis_h2c_tready              = (st_loopback == 1'b1) ? m_axis_h2c_tready_lpbk       : m_axis_h2c_tready_int;
  assign s_axis_c2h_cmpt_size           = (st_loopback == 1'b1) ? out_axis_cmp_data.cmp_size   : s_axis_c2h_cmpt_size_int;
  assign s_axis_c2h_cmpt_dpar           = (st_loopback == 1'b1) ? out_axis_cmp_data.dpar       : s_axis_c2h_cmpt_dpar_int;
  assign s_axis_c2h_cmpt_tdata          = (st_loopback == 1'b1) ? out_axis_cmp_data.cmp_ent    : s_axis_c2h_cmpt_tdata_int;
  assign s_axis_c2h_cmpt_tvalid         = (st_loopback == 1'b1) ? out_axis_cmp_tvalid          : s_axis_c2h_cmpt_tvalid_int;
  assign s_axis_c2h_cmpt_ctrl_qid       = (st_loopback == 1'b1) ? out_axis_cmp_ctrl.qid        : s_axis_c2h_cmpt_ctrl_qid_int;
  assign s_axis_c2h_cmpt_ctrl_marker    = (st_loopback == 1'b1) ? out_axis_cmp_ctrl.marker     : s_axis_c2h_cmpt_ctrl_marker_int;
  assign s_axis_c2h_cmpt_ctrl_col_idx   = (st_loopback == 1'b1) ? out_axis_cmp_ctrl.color_idx  : s_axis_c2h_cmpt_ctrl_col_idx_int;
  assign s_axis_c2h_cmpt_ctrl_err_idx   = (st_loopback == 1'b1) ? out_axis_cmp_ctrl.error_idx  : s_axis_c2h_cmpt_ctrl_err_idx_int;
  assign s_axis_c2h_cmpt_ctrl_cmpt_type = (st_loopback == 1'b1) ? out_axis_cmp_ctrl.cmpt_type  : s_axis_c2h_cmpt_ctrl_cmpt_type_int;
  assign s_axis_c2h_cmpt_ctrl_user_trig = (st_loopback == 1'b1) ? out_axis_cmp_ctrl.user_trig  : s_axis_c2h_cmpt_ctrl_user_trig_int;
  assign s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id = (st_loopback == 1'b1) ? out_axis_cmp_ctrl.wait_pld_pkt_id : s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id_int;



  axi_st_module
  #(
    .C_DATA_WIDTH (C_DATA_WIDTH),
    .C_H2C_TUSER_WIDTH (C_H2C_TUSER_WIDTH),
    .TM_DSC_BITS (TM_DSC_BITS)
  )
  axi_st_module_i
  (
    .axi_aresetn (rst_n & soft_reset_n),
    .axi_aclk (user_clk),
    .c2h_st_qid (c2h_st_qid),
    .c2h_control (c2h_control),
    .clr_h2c_match (clr_h2c_match),
    .c2h_st_len (c2h_st_len),
    .c2h_num_pkt (c2h_num_pkt),
    .c2h_end (c2h_end),
    .h2c_count (h2c_count),
    .h2c_match (h2c_match),
    .h2c_qid (h2c_qid),
    .wb_dat (wb_dat),
    .cmpt_size (cmpt_size),
    .credit_in (credit_out),
    .credit_updt (credit_updt),
    .credit_perpkt_in (credit_perpkt_in),
    .credit_needed (credit_needed),
    .buf_count (buf_count),
    .byp_to_cmp (byp_to_cmp),
    .byp_data_to_cmp (byp_data_to_cmp),
    
    .m_axis_h2c_tvalid          (m_axis_h2c_tvalid),
    .m_axis_h2c_tready          (m_axis_h2c_tready_int),
    .m_axis_h2c_tdata           (m_axis_h2c_tdata),
    .m_axis_h2c_tlast           (m_axis_h2c_tlast),
    .m_axis_h2c_tuser_qid       (m_axis_h2c_tuser_qid),
    .m_axis_h2c_tuser_port_id   (m_axis_h2c_tuser_port_id),
    .m_axis_h2c_tuser_err       (m_axis_h2c_tuser_err),
    .m_axis_h2c_tuser_mdata     (m_axis_h2c_tuser_mdata),
    .m_axis_h2c_tuser_mty       (m_axis_h2c_tuser_mty),
    .m_axis_h2c_tuser_zero_byte (m_axis_h2c_tuser_zero_byte),
    
    .s_axis_c2h_tdata          (s_axis_c2h_tdata_int),
    .s_axis_c2h_dpar           (s_axis_c2h_dpar_int),
    .s_axis_c2h_ctrl_marker    (s_axis_c2h_ctrl_marker_int),
    .s_axis_c2h_ctrl_len       (s_axis_c2h_ctrl_len_int), // c2h_st_len,
    .s_axis_c2h_ctrl_qid       (s_axis_c2h_ctrl_qid_int), // st_qid,
    .s_axis_c2h_ctrl_has_cmpt  (s_axis_c2h_ctrl_has_cmpt_int), // disable write back, write back not valid
    .s_axis_c2h_tvalid         (s_axis_c2h_tvalid_int),
    .s_axis_c2h_tready         (s_axis_c2h_tready),
    .s_axis_c2h_tlast          (s_axis_c2h_tlast_int),
    .s_axis_c2h_mty            (s_axis_c2h_mty_int),  // no empty bytes at EOP
    
    .s_axis_c2h_cmpt_tdata               (s_axis_c2h_cmpt_tdata_int),
    .s_axis_c2h_cmpt_size                (s_axis_c2h_cmpt_size_int),
    .s_axis_c2h_cmpt_dpar                (s_axis_c2h_cmpt_dpar_int),
    .s_axis_c2h_cmpt_tvalid              (s_axis_c2h_cmpt_tvalid_int),
    .s_axis_c2h_cmpt_ctrl_qid            (s_axis_c2h_cmpt_ctrl_qid_int),
    .s_axis_c2h_cmpt_ctrl_cmpt_type      (s_axis_c2h_cmpt_ctrl_cmpt_type_int),
    .s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id(s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id_int),
    .s_axis_c2h_cmpt_ctrl_marker         (s_axis_c2h_cmpt_ctrl_marker_int),
    .s_axis_c2h_cmpt_ctrl_user_trig      (s_axis_c2h_cmpt_ctrl_user_trig_int),
    .s_axis_c2h_cmpt_ctrl_col_idx        (s_axis_c2h_cmpt_ctrl_col_idx_int),
    .s_axis_c2h_cmpt_ctrl_err_idx        (s_axis_c2h_cmpt_ctrl_err_idx_int),
    .s_axis_c2h_cmpt_tready              (s_axis_c2h_cmpt_tready)
  );

  // LED 0 pysically resides in the reconfiguable area for Tandem with
  // Field Updates designs so the OBUF must included in this hierarchy.
  OBUF led_0_obuf (.O(leds[0]), .I(sys_resetn));
  // LEDs 1-3 physically reside in the stage1 region for Tandem with Field
  // Updates designs so the OBUF must be instantiated at the top-level.
  assign leds[1] = user_resetn;
  assign leds[2] = user_lnk_up;
  assign leds[3] = user_clk_heartbeat[25];


  qdma_lpbk #(
    .MAX_DATA_WIDTH(C_DATA_WIDTH),
    .TDEST_BITS(16),
    .TCQ(TCQ)
  )
  qdma_st_lpbk_inst(
    // Clock and Reset
    .clk(clk),
    .rst_n(rst_n & soft_reset_n),

    //Input from QDMA
    .in_axis_tdata(m_axis_h2c_tdata),
    .in_axis_tuser(m_axis_h2c_tuser_net),
    .in_axis_tlast(m_axis_h2c_tlast),
    .in_axis_tvalid(m_axis_h2c_tvalid),
    .in_axis_tready(m_axis_h2c_tready_lpbk),

    //HDR output to QDMA
    .out_axis_cmp_data(out_axis_cmp_data),
    .out_axis_cmp_ctrl(out_axis_cmp_ctrl),
    .out_axis_cmp_tlast(out_axis_cmp_tlast),
    .out_axis_cmp_tvalid(out_axis_cmp_tvalid),
    .out_axis_cmp_tready(s_axis_c2h_cmpt_tready),

    //PLD output to QDMA
    .out_axis_pld_data(out_axis_pld_data),
    .out_axis_pld_ctrl(out_axis_pld_ctrl),
    .out_axis_pld_mty(s_axis_c2h_mty_lpbk),
    .out_axis_pld_tlast(s_axis_c2h_tlast_lpbk),
    .out_axis_pld_tvalid(s_axis_c2h_tvalid_lpbk),
    .out_axis_pld_tready(s_axis_c2h_tready)
  );


  // Block ram for the AXI Lite interface
  blk_mem_gen_0 blk_mem_axiLM_inst (
    .s_aclk        (user_clk),
    .s_aresetn     (user_resetn),
    .s_axi_awaddr  (s_axil_awaddr[31:0]),
    .s_axi_awvalid (s_axil_awvalid),
    .s_axi_awready (s_axil_awready),
    .s_axi_wdata   (s_axil_wdata),
    .s_axi_wstrb   (s_axil_wstrb),
    .s_axi_wvalid  (s_axil_wvalid),
    .s_axi_wready  (s_axil_wready),
    .s_axi_bresp   (s_axil_bresp),
    .s_axi_bvalid  (s_axil_bvalid),
    .s_axi_bready  (s_axil_bready),
    .s_axi_araddr  (s_axil_araddr[31:0]),
    .s_axi_arvalid (s_axil_arvalid),
    .s_axi_arready (s_axil_arready),
    .s_axi_rdata   (s_axil_rdata_bram),
    .s_axi_rresp   (s_axil_rresp),
    .s_axi_rvalid  (s_axil_rvalid),
    .s_axi_rready  (s_axil_rready)
  );






endmodule
