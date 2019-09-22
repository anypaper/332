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
// File       : xilinx_qdma_pcie_ep.sv
// Version    : 5.0
//-----------------------------------------------------------------------------
`timescale 1ps / 1ps

`include "qdma_stm_defines.svh"
module xilinx_qdma_pcie_ep #
(
	parameter NF_C_S_AXI_DATA_WIDTH        = 32,    
	parameter NF_C_S_AXI_ADDR_WIDTH        = 32, 
  parameter PL_LINK_CAP_MAX_LINK_WIDTH  = 16,  // 1- X1; 2 - X2; 4 - X4; 8 - X8
  parameter PL_SIM_FAST_LINK_TRAINING   = "FALSE",  // Simulation Speedup
  parameter PL_LINK_CAP_MAX_LINK_SPEED  = 4,  // 1- GEN1; 2 - GEN2; 4 - GEN3
  parameter C_DATA_WIDTH                = 512 ,
  parameter EXT_PIPE_SIM                = "FALSE",  // This Parameter has effect on selecting Enable External PIPE Interface in GUI.
  parameter C_ROOT_PORT                 = "FALSE",  // PCIe block is in root port mode
  parameter C_DEVICE_NUMBER             = 0,        // Device number for Root Port configurations only
  parameter AXIS_CCIX_RX_TDATA_WIDTH    = 256,
  parameter AXIS_CCIX_TX_TDATA_WIDTH    = 256,
  parameter AXIS_CCIX_RX_TUSER_WIDTH    = 46,
  parameter AXIS_CCIX_TX_TUSER_WIDTH    = 46
)
(
	output  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]   S0_AXI_AWADDR,
	output                                  S0_AXI_AWVALID,
	output  [NF_C_S_AXI_DATA_WIDTH-1 : 0]   S0_AXI_WDATA,
	output  [NF_C_S_AXI_DATA_WIDTH/8-1 : 0] S0_AXI_WSTRB,
	output                                  S0_AXI_WVALID,
	output                                  S0_AXI_BREADY,
	output  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]   S0_AXI_ARADDR,
	output                                  S0_AXI_ARVALID,
	output                                  S0_AXI_RREADY,
	input                                 S0_AXI_ARREADY,
	input [NF_C_S_AXI_DATA_WIDTH-1 : 0]   S0_AXI_RDATA,
	input [1 : 0]                         S0_AXI_RRESP,
	input                                 S0_AXI_RVALID,
	input                                 S0_AXI_WREADY,
	input [1 :0]                          S0_AXI_BRESP,
	input                                 S0_AXI_BVALID,
	input                                 S0_AXI_AWREADY,

	output  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]   S1_AXI_AWADDR,
	output                                  S1_AXI_AWVALID,
	output  [NF_C_S_AXI_DATA_WIDTH-1 : 0]   S1_AXI_WDATA,
	output  [NF_C_S_AXI_DATA_WIDTH/8-1 : 0] S1_AXI_WSTRB,
	output                                  S1_AXI_WVALID,
	output                                  S1_AXI_BREADY,
	output  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]   S1_AXI_ARADDR,
	output                                  S1_AXI_ARVALID,
	output                                  S1_AXI_RREADY,
	input                                 S1_AXI_ARREADY,
	input [NF_C_S_AXI_DATA_WIDTH-1 : 0]   S1_AXI_RDATA,
	input [1 : 0]                         S1_AXI_RRESP,
	input                                 S1_AXI_RVALID,
	input                                 S1_AXI_WREADY,
	input [1 :0]                          S1_AXI_BRESP,
	input                                 S1_AXI_BVALID,
	input                                 S1_AXI_AWREADY,

	output  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]   S2_AXI_AWADDR,
	output                                  S2_AXI_AWVALID,
	output  [NF_C_S_AXI_DATA_WIDTH-1 : 0]   S2_AXI_WDATA,
	output  [NF_C_S_AXI_DATA_WIDTH/8-1 : 0] S2_AXI_WSTRB,
	output                                  S2_AXI_WVALID,
	output                                  S2_AXI_BREADY,
	output  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]   S2_AXI_ARADDR,
	output                                  S2_AXI_ARVALID,
	output                                  S2_AXI_RREADY,
	input                                 S2_AXI_ARREADY,
	input [NF_C_S_AXI_DATA_WIDTH-1 : 0]   S2_AXI_RDATA,
	input [1 : 0]                         S2_AXI_RRESP,
	input                                 S2_AXI_RVALID,
	input                                 S2_AXI_WREADY,
	input [1 :0]                          S2_AXI_BRESP,
	input                                 S2_AXI_BVALID,
	input                                 S2_AXI_AWREADY,

	output  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]   S3_AXI_AWADDR,
	output                                  S3_AXI_AWVALID,
	output  [NF_C_S_AXI_DATA_WIDTH-1 : 0]   S3_AXI_WDATA,
	output  [NF_C_S_AXI_DATA_WIDTH/8-1 : 0] S3_AXI_WSTRB,
	output                                  S3_AXI_WVALID,
	output                                  S3_AXI_BREADY,
	output  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]   S3_AXI_ARADDR,
	output                                  S3_AXI_ARVALID,
	output                                  S3_AXI_RREADY,
	input                                 S3_AXI_ARREADY,
	input [NF_C_S_AXI_DATA_WIDTH-1 : 0]   S3_AXI_RDATA,
	input [1 : 0]                         S3_AXI_RRESP,
	input                                 S3_AXI_RVALID,
	input                                 S3_AXI_WREADY,
	input [1 :0]                          S3_AXI_BRESP,
	input                                 S3_AXI_BVALID,
	input                                 S3_AXI_AWREADY,

	output  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]   S4_AXI_AWADDR,
	output                                  S4_AXI_AWVALID,
	output  [NF_C_S_AXI_DATA_WIDTH-1 : 0]   S4_AXI_WDATA,
	output  [NF_C_S_AXI_DATA_WIDTH/8-1 : 0] S4_AXI_WSTRB,
	output                                  S4_AXI_WVALID,
	output                                  S4_AXI_BREADY,
	output  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]   S4_AXI_ARADDR,
	output                                  S4_AXI_ARVALID,
	output                                  S4_AXI_RREADY,
	input                                 S4_AXI_ARREADY,
	input [NF_C_S_AXI_DATA_WIDTH-1 : 0]   S4_AXI_RDATA,
	input [1 : 0]                         S4_AXI_RRESP,
	input                                 S4_AXI_RVALID,
	input                                 S4_AXI_WREADY,
	input [1 :0]                          S4_AXI_BRESP,
	input                                 S4_AXI_BVALID,
	input                                 S4_AXI_AWREADY,

	output  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]   S5_AXI_AWADDR,
	output                                  S5_AXI_AWVALID,
	output  [NF_C_S_AXI_DATA_WIDTH-1 : 0]   S5_AXI_WDATA,
	output  [NF_C_S_AXI_DATA_WIDTH/8-1 : 0] S5_AXI_WSTRB,
	output                                  S5_AXI_WVALID,
	output                                  S5_AXI_BREADY,
	output  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]   S5_AXI_ARADDR,
	output                                  S5_AXI_ARVALID,
	output                                  S5_AXI_RREADY,
	input                                 S5_AXI_ARREADY,
	input [NF_C_S_AXI_DATA_WIDTH-1 : 0]   S5_AXI_RDATA,
	input [1 : 0]                         S5_AXI_RRESP,
	input                                 S5_AXI_RVALID,
	input                                 S5_AXI_WREADY,
	input [1 :0]                          S5_AXI_BRESP,
	input                                 S5_AXI_BVALID,
	input                                 S5_AXI_AWREADY,

  output [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]   pci_exp_txp,
  output [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]   pci_exp_txn,
  input  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]   pci_exp_rxp,
  input  [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]   pci_exp_rxn,


	output axi_aclk,
	output axi_aresetn,
	output axi_aclk_100,
	output axi_aresetn_100,


  output  led_0,
  output  led_1,
  output  led_2,
  input   sys_clk_p,
  input   sys_clk_n,
  input   sys_rst_n
);
 
  //-----------------------------------------------------------------------------------------------------------------------
  // Local Parameters derived from user selection
  localparam integer USER_CLK_FREQ = ((PL_LINK_CAP_MAX_LINK_SPEED == 3'h4) ? 5 : 4);
  localparam TCQ = 1;
  localparam C_S_AXI_ID_WIDTH   = 4;
  localparam C_M_AXI_ID_WIDTH   = 4;
  localparam C_S_AXI_DATA_WIDTH = C_DATA_WIDTH;
  localparam C_M_AXI_DATA_WIDTH = C_DATA_WIDTH;
  localparam C_S_AXI_ADDR_WIDTH = 64;
  localparam C_M_AXI_ADDR_WIDTH = 64;
  localparam C_NUM_USR_IRQ  = 16;
  localparam MULTQ_EN               = 1;
  localparam C_DSC_MAGIC_EN	        = 1;
  localparam C_H2C_NUM_RIDS	        = 64;
  localparam C_H2C_NUM_CHNL	        = MULTQ_EN ? 4 : 4;
  localparam C_C2H_NUM_CHNL	        = MULTQ_EN ? 4 : 4;
  localparam C_C2H_NUM_RIDS	        = 32;
  localparam C_NUM_PCIE_TAGS	      = 256;
  localparam C_S_AXI_NUM_READ 	    = 32;
  localparam C_S_AXI_NUM_WRITE	    = 8;
  localparam C_H2C_TUSER_WIDTH	    = 55;
  localparam C_C2H_TUSER_WIDTH	    = 64;
  localparam C_MDMA_DSC_IN_NUM_CHNL = 3;   // only 2 interface are userd. 0 is for MM and 2 is for ST. 1 is not used
  localparam C_MAX_NUM_QUEUE        = 128;
  localparam TM_DSC_BITS            = 16;
  wire user_lnk_up;

  //----------------------------------------------------------------------------------------------------------------//
  //  AXI Interface                                                                                                 //
  //----------------------------------------------------------------------------------------------------------------//
  wire user_clk;

  // Wires for Avery HOT/WARM and COLD RESET
  wire avy_sys_rst_n_c;
  wire avy_cfg_hot_reset_out;
  reg  avy_sys_rst_n_g;
  reg  avy_cfg_hot_reset_out_g;

  assign avy_sys_rst_n_c = avy_sys_rst_n_g;
  assign avy_cfg_hot_reset_out = avy_cfg_hot_reset_out_g;

  initial begin
    avy_sys_rst_n_g = 1;
    avy_cfg_hot_reset_out_g =0;
  end

  assign user_clk = axi_aclk;



  //----------------------------------------------------------------------------------------------------------------//
  //    System(SYS) Interface                                                                                       //
  //----------------------------------------------------------------------------------------------------------------//

  wire  sys_clk;
  wire  sys_rst_n_c;
  

  // User Clock LED Heartbeat
  reg [25:0] user_clk_heartbeat;

  //-- AXI Master Write Address Channel
  wire [C_M_AXI_ADDR_WIDTH-1:0]  m_axi_awaddr;
  wire [C_M_AXI_ID_WIDTH-1:0]    m_axi_awid;
  wire [2:0]                     m_axi_awprot;
  wire [1:0]                     m_axi_awburst;
  wire [2:0]                     m_axi_awsize;
  wire [3:0]                     m_axi_awcache;
  wire [7:0]                     m_axi_awlen;
  wire                           m_axi_awlock;
  wire                           m_axi_awvalid;
  wire                           m_axi_awready;

  //-- AXI Master Write Data Channel
  wire [C_M_AXI_DATA_WIDTH-1:0]     m_axi_wdata;
  wire [(C_M_AXI_DATA_WIDTH/8)-1:0] m_axi_wstrb;
  wire                              m_axi_wlast;
  wire                              m_axi_wvalid;
  wire                              m_axi_wready;

  //-- AXI Master Write Response Channel
  wire                           m_axi_bvalid;
  wire                           m_axi_bready;
  wire [C_M_AXI_ID_WIDTH-1 : 0]  m_axi_bid ;
  wire [1:0]                     m_axi_bresp ;

  //-- AXI Master Read Address Channel
  wire [C_M_AXI_ID_WIDTH-1 : 0]  m_axi_arid;
  wire [C_M_AXI_ADDR_WIDTH-1:0]  m_axi_araddr;
  wire [7:0]                     m_axi_arlen;
  wire [2:0]                     m_axi_arsize;
  wire [1:0]                     m_axi_arburst;
  wire [2:0]                     m_axi_arprot;
  wire                           m_axi_arvalid;
  wire                           m_axi_arready;
  wire                           m_axi_arlock;
  wire [3:0]                     m_axi_arcache;

  //-- AXI Master Read Data Channel
  wire [C_M_AXI_ID_WIDTH-1 : 0]  m_axi_rid;
  wire [C_M_AXI_DATA_WIDTH-1:0]  m_axi_rdata;
  wire [1:0]                     m_axi_rresp;
  wire                           m_axi_rvalid;
  wire                           m_axi_rready;
  wire                           m_axi_rlast;


  //////////////////////////////////////////////////  LITE
wire [31:0] conv_m_axil_awaddr;
wire [2:0]  conv_m_axil_awprot;
wire        conv_m_axil_awvalid;
wire        conv_m_axil_awready;

//-- AXI Master Write Data Channel
wire [31:0] conv_m_axil_wdata;
wire [3:0]  conv_m_axil_wstrb;
wire        conv_m_axil_wvalid;
wire        conv_m_axil_wready;
//-- AXI Master Write Response Channel
wire        conv_m_axil_bvalid;
wire        conv_m_axil_bready;
//-- AXI Master Read Address Channel
wire [31:0] conv_m_axil_araddr;
wire [2:0]  conv_m_axil_arprot;
wire        conv_m_axil_arvalid;
wire        conv_m_axil_arready;
//-- AXI Master Read Data Channel
wire [31:0] conv_m_axil_rdata_bram;
wire [31:0] conv_m_axil_rdata;
wire [1:0]  conv_m_axil_rresp;
wire        conv_m_axil_rvalid;
wire        conv_m_axil_rready;
wire [1:0]  conv_m_axil_bresp;
  //-- AXI Master Write Address Channel
  wire [31:0] m_axil_awaddr;
  wire [2:0]  m_axil_awprot;
  wire        m_axil_awvalid;
  wire        m_axil_awready;

  //-- AXI Master Write Data Channel
  wire [31:0] m_axil_wdata;
  wire [3:0]  m_axil_wstrb;
  wire        m_axil_wvalid;
  wire        m_axil_wready;

  //-- AXI Master Write Response Channel
  wire        m_axil_bvalid;
  wire        m_axil_bready;

  //-- AXI Master Read Address Channel
  wire [31:0] m_axil_araddr;
  wire [2:0]  m_axil_arprot;
  wire        m_axil_arvalid;
  wire        m_axil_arready;

  //-- AXI Master Read Data Channel
  wire [31:0] m_axil_rdata;
  wire [1:0]  m_axil_rresp;
  wire        m_axil_rvalid;
  wire        m_axil_rready;
  wire [1:0]  m_axil_bresp;

  wire [2:0]  msi_vector_width;
  wire        msi_enable;

  wire [3:0]  leds;


  wire [5:0]  cfg_ltssm_state;

  wire [7:0]		c2h_sts_0;
  wire [7:0]		h2c_sts_0;
  wire [7:0]		c2h_sts_1;
  wire [7:0]		h2c_sts_1;
  wire [7:0]		c2h_sts_2;
  wire [7:0]		h2c_sts_2;
  wire [7:0]		c2h_sts_3;
  wire [7:0]		h2c_sts_3;

  // MDMA signals
  wire   [C_DATA_WIDTH-1:0]   m_axis_h2c_tdata;
  wire   [C_DATA_WIDTH/8-1:0] m_axis_h2c_dpar;
  wire   [10:0]               m_axis_h2c_tuser_qid;
  wire   [2:0]                m_axis_h2c_tuser_port_id;
  wire                        m_axis_h2c_tuser_err;
  wire   [31:0]               m_axis_h2c_tuser_mdata;
  wire   [5:0]                m_axis_h2c_tuser_mty;
  wire                        m_axis_h2c_tuser_zero_byte;
  wire                        m_axis_h2c_tvalid;
  wire                        m_axis_h2c_tready;
  wire                        m_axis_h2c_tlast;

  wire                        m_axis_h2c_tready_lpbk;
  wire                        m_axis_h2c_tready_int;

  // AXIS C2H packet wire
  wire [C_DATA_WIDTH-1:0]     s_axis_c2h_tdata;
  wire [C_DATA_WIDTH/8-1:0]   s_axis_c2h_dpar;
  wire                        s_axis_c2h_ctrl_marker;
  wire [2:0]                  s_axis_c2h_ctrl_port_id;
  wire [15:0]                 s_axis_c2h_ctrl_len;
  wire [10:0]                 s_axis_c2h_ctrl_qid ;
  wire                        s_axis_c2h_ctrl_has_cmpt ;
  wire [C_DATA_WIDTH-1:0]     s_axis_c2h_tdata_int;
  wire                        s_axis_c2h_ctrl_marker_int;
  wire [15:0]                 s_axis_c2h_ctrl_len_int;
  wire [10:0]                 s_axis_c2h_ctrl_qid_int ;
  wire                        s_axis_c2h_ctrl_has_cmpt_int ;
  wire [C_DATA_WIDTH/8-1:0]   s_axis_c2h_dpar_int;
  wire                        s_axis_c2h_tvalid;
  wire                        s_axis_c2h_tready;
  wire                        s_axis_c2h_tlast;
  wire  [5:0]                 s_axis_c2h_mty;
  wire                        s_axis_c2h_tvalid_lpbk;
  wire                        s_axis_c2h_tlast_lpbk;
  wire  [5:0]                 s_axis_c2h_mty_lpbk;
  wire                        s_axis_c2h_tvalid_int;
  wire                        s_axis_c2h_tlast_int;
  wire  [5:0]                 s_axis_c2h_mty_int;

  // AXIS C2H tuser wire
  wire  [511:0] s_axis_c2h_cmpt_tdata;
  wire  [1:0]   s_axis_c2h_cmpt_size;
  wire  [15:0]  s_axis_c2h_cmpt_dpar;
  wire          s_axis_c2h_cmpt_tvalid;
  wire          s_axis_c2h_cmpt_tvalid_int;
  wire  [511:0] s_axis_c2h_cmpt_tdata_int;
  wire  [1:0]   s_axis_c2h_cmpt_size_int;
  wire  [15:0]  s_axis_c2h_cmpt_dpar_int;
  wire          s_axis_c2h_cmpt_tready_int;
  wire          s_axis_c2h_cmpt_tready;
	wire [10:0]		s_axis_c2h_cmpt_ctrl_qid;
	wire [1:0]		s_axis_c2h_cmpt_ctrl_cmpt_type;
	wire [15:0]		s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id;
	wire 				  s_axis_c2h_cmpt_ctrl_marker;
	wire 				  s_axis_c2h_cmpt_ctrl_user_trig;
	wire [2:0]		s_axis_c2h_cmpt_ctrl_col_idx;
	wire [2:0]		s_axis_c2h_cmpt_ctrl_err_idx;


  
  wire          usr_irq_in_vld;
  wire [4 : 0]  usr_irq_in_vec;
  wire [7 : 0]  usr_irq_in_fnc;
  wire          usr_irq_out_ack;
  wire          usr_irq_out_fail;

  wire          st_rx_msg_rdy;
  wire          st_rx_msg_valid;
  wire          st_rx_msg_last;
  wire [31:0]   st_rx_msg_data;

  wire          tm_dsc_sts_vld;
  wire          tm_dsc_sts_qen;
  wire          tm_dsc_sts_byp;
  wire          tm_dsc_sts_dir;
  wire          tm_dsc_sts_mm;
  wire          tm_dsc_sts_error;
  wire  [10:0]  tm_dsc_sts_qid;
  wire  [15:0]  tm_dsc_sts_avl;
  wire          tm_dsc_sts_qinv;
  wire          tm_dsc_sts_irq_arm;
  wire          tm_dsc_sts_rdy;

  // Descriptor credit In
  wire          dsc_crdt_in_vld;
  wire          dsc_crdt_in_rdy;
  wire          dsc_crdt_in_dir;
  wire          dsc_crdt_in_fence;
  wire [10:0]   dsc_crdt_in_qid;
  wire [15:0]   dsc_crdt_in_crdt;

  // Report the DROP case
  wire          axis_c2h_status_drop;
  wire          axis_c2h_status_last;
  wire          axis_c2h_status_valid;
  wire          axis_c2h_status_cmp;
  wire [10:0]   axis_c2h_status_qid;
  // FLR
  wire [7:0]  usr_flr_fnc;
  wire        usr_flr_set;
  wire        usr_flr_clr;
  wire [7:0]  usr_flr_done_fnc;
  wire        usr_flr_done_vld;
	wire          soft_reset_n;
	wire					st_loopback;

  wire [10:0]   c2h_num_pkt;
  wire [10:0]   c2h_st_qid;
  wire [15:0]   c2h_st_len;
  wire [31:0]   h2c_count;
  wire          h2c_match;
  wire          clr_h2c_match;
  wire 	        c2h_end;
  wire [31:0]   c2h_control;
  wire [10:0]   h2c_qid;
  wire [31:0]   cmpt_size;
  wire [255:0]  wb_dat;

  wire [TM_DSC_BITS-1:0] credit_out;
  wire [TM_DSC_BITS-1:0] credit_needed;
  wire [TM_DSC_BITS-1:0] credit_perpkt_in;
  wire                   credit_updt;
  
  wire [15:0] buf_count;
  wire        sys_clk_gt;


  // Ref clock buffer
  IBUFDS_GTE4 # (.REFCLK_HROW_CK_SEL(2'b00)) refclk_ibuf (.O(sys_clk_gt), .ODIV2(sys_clk), .I(sys_clk_p), .CEB(1'b0), .IB(sys_clk_n));
  // Reset buffer
  IBUF   sys_reset_n_ibuf (.O(sys_rst_n_c), .I(sys_rst_n));
  // LED buffers
  
  OBUF led_0_obuf (.O(led_0), .I(leds[0]));
  
  OBUF led_1_obuf (.O(led_1), .I(leds[1]));
  OBUF led_2_obuf (.O(led_2), .I(leds[2]));  


clk_wiz_0 u_clk_wiz ( 
	.clk_out1(axi_aclk_100),        //  output        
	.reset   (~axi_aresetn), //  input         
	.locked  (axi_aresetn_100),     //  output        
	.clk_in1 (axi_aclk)      //  input         
);

axi_clock_converter_0 u_axi_clk_conv (
	.m_axi_aclk   (axi_aclk_100),
	.m_axi_aresetn(axi_aresetn_100),
	.m_axi_awaddr (m_axil_awaddr ),
	.m_axi_awprot (m_axil_awprot ),
	.m_axi_awvalid(m_axil_awvalid),
	.m_axi_awready(m_axil_awready),
	.m_axi_wdata  (m_axil_wdata  ),
	.m_axi_wstrb  (m_axil_wstrb  ),
	.m_axi_wvalid (m_axil_wvalid ),
	.m_axi_wready (m_axil_wready ),
	.m_axi_bresp  (m_axil_bresp  ),
	.m_axi_bvalid (m_axil_bvalid ),
	.m_axi_bready (m_axil_bready ),
	.m_axi_araddr (m_axil_araddr ),
	.m_axi_arprot (m_axil_arprot ),
	.m_axi_arvalid(m_axil_arvalid),
	.m_axi_arready(m_axil_arready),
	.m_axi_rdata  (m_axil_rdata  ),
	.m_axi_rresp  (m_axil_rresp  ),
	.m_axi_rvalid (m_axil_rvalid ),
	.m_axi_rready (m_axil_rready ),
	.s_axi_aclk   (axi_aclk),
	.s_axi_aresetn(axi_aresetn),
	.s_axi_awaddr (conv_m_axil_awaddr ),
	.s_axi_awprot (conv_m_axil_awprot ),
	.s_axi_awvalid(conv_m_axil_awvalid),
	.s_axi_awready(conv_m_axil_awready),
	.s_axi_wdata  (conv_m_axil_wdata  ),
	.s_axi_wstrb  (conv_m_axil_wstrb  ),
	.s_axi_wvalid (conv_m_axil_wvalid ),
	.s_axi_wready (conv_m_axil_wready ),
	.s_axi_bresp  (conv_m_axil_bresp  ),
	.s_axi_bvalid (conv_m_axil_bvalid ),
	.s_axi_bready (conv_m_axil_bready ),
	.s_axi_araddr (conv_m_axil_araddr ),
	.s_axi_arprot (conv_m_axil_arprot ),
	.s_axi_arvalid(conv_m_axil_arvalid),
	.s_axi_arready(conv_m_axil_arready),
	.s_axi_rdata  (conv_m_axil_rdata  ),
	.s_axi_rresp  (conv_m_axil_rresp  ),
	.s_axi_rvalid (conv_m_axil_rvalid ),
	.s_axi_rready (conv_m_axil_rready ) 
);




  // Core Top Level Wrapper
  qdma_0 qdma_0_i
     (
      //---------------------------------------------------------------------------------------//
      //  PCI Express (pci_exp) Interface                                                      //
      //---------------------------------------------------------------------------------------//
      .sys_rst_n       ( sys_rst_n_c ),
      .sys_clk (sys_clk),
      .sys_clk_gt (sys_clk_gt),
      // Tx
      .pci_exp_txn (pci_exp_txn),
      .pci_exp_txp (pci_exp_txp),

      // Rx
      .pci_exp_rxn (pci_exp_rxn),
      .pci_exp_rxp (pci_exp_rxp),
      // LITE interface
      //-- AXI Master Write Address Channel
      .m_axil_awaddr    (conv_m_axil_awaddr),
      .m_axil_awprot    (conv_m_axil_awprot),
      .m_axil_awvalid   (conv_m_axil_awvalid),
      .m_axil_awready   (conv_m_axil_awready),
      //-- AXI Master Write Data Channel
      .m_axil_wdata     (conv_m_axil_wdata),
      .m_axil_wstrb     (conv_m_axil_wstrb),
      .m_axil_wvalid    (conv_m_axil_wvalid),
      .m_axil_wready    (conv_m_axil_wready),
      //-- AXI Master Write Response Channel
      .m_axil_bvalid    (conv_m_axil_bvalid),
      .m_axil_bresp     (conv_m_axil_bresp),
      .m_axil_bready    (conv_m_axil_bready),
      //-- AXI Master Read Address Channel
      .m_axil_araddr    (conv_m_axil_araddr),
      .m_axil_arprot    (conv_m_axil_arprot),
      .m_axil_arvalid   (conv_m_axil_arvalid),
      .m_axil_arready   (conv_m_axil_arready),
      .m_axil_rdata     (conv_m_axil_rdata),
      //-- AXI Master Read Data Channel
      .m_axil_rresp     (conv_m_axil_rresp),
      .m_axil_rvalid    (conv_m_axil_rvalid),
      .m_axil_rready    (conv_m_axil_rready),

      //-- AXI Global
      .axi_aclk(axi_aclk),
      .phy_ready   (phy_ready),
      .axi_aresetn (axi_aresetn ),
      .soft_reset_n(soft_reset_n ),

      .s_axis_c2h_tdata        (s_axis_c2h_tdata ),
      .s_axis_c2h_dpar         (s_axis_c2h_dpar),
      .s_axis_c2h_ctrl_marker  (s_axis_c2h_ctrl_marker),
      .s_axis_c2h_ctrl_len     (s_axis_c2h_ctrl_len), // c2h_st_len),
      .s_axis_c2h_ctrl_port_id (3'b000),
      .s_axis_c2h_ctrl_qid     (s_axis_c2h_ctrl_qid ), // st_qid),
      .s_axis_c2h_ctrl_has_cmpt(s_axis_c2h_ctrl_has_cmpt),   //write back is valid
      .s_axis_c2h_tvalid       (s_axis_c2h_tvalid),
      .s_axis_c2h_tready       (s_axis_c2h_tready),
      .s_axis_c2h_tlast        (s_axis_c2h_tlast),
      .s_axis_c2h_mty          (s_axis_c2h_mty),                   // no empthy bytes at EOP

      .m_axis_h2c_tready         (m_axis_h2c_tready),
      .m_axis_h2c_tvalid         (m_axis_h2c_tvalid),
      .m_axis_h2c_tlast          (m_axis_h2c_tlast),
      .m_axis_h2c_tuser_qid      (m_axis_h2c_tuser_qid),
      .m_axis_h2c_tuser_port_id  (m_axis_h2c_tuser_port_id),
      .m_axis_h2c_tuser_err      (m_axis_h2c_tuser_err),
      .m_axis_h2c_tuser_mdata    (m_axis_h2c_tuser_mdata),
      .m_axis_h2c_tuser_mty      (m_axis_h2c_tuser_mty),
      .m_axis_h2c_tuser_zero_byte(m_axis_h2c_tuser_zero_byte),
      .m_axis_h2c_tdata          (m_axis_h2c_tdata),
      .m_axis_h2c_dpar           (m_axis_h2c_dpar),

      .axis_c2h_status_drop  (axis_c2h_status_drop),
      .axis_c2h_status_last  (axis_c2h_status_last),
      .axis_c2h_status_cmp   (axis_c2h_status_cmp),
      .axis_c2h_status_valid (axis_c2h_status_valid),
      .axis_c2h_status_qid   (axis_c2h_status_qid),
      .axis_c2h_dmawr_cmp    (),
      .s_axis_c2h_cmpt_tdata         (s_axis_c2h_cmpt_tdata),
      .s_axis_c2h_cmpt_size          (s_axis_c2h_cmpt_size ),
      .s_axis_c2h_cmpt_dpar          (s_axis_c2h_cmpt_dpar),
      .s_axis_c2h_cmpt_tvalid        (s_axis_c2h_cmpt_tvalid),
      .s_axis_c2h_cmpt_tready        (s_axis_c2h_cmpt_tready),
      .s_axis_c2h_cmpt_ctrl_qid      (s_axis_c2h_cmpt_ctrl_qid ),
      .s_axis_c2h_cmpt_ctrl_cmpt_type(s_axis_c2h_cmpt_ctrl_cmpt_type ),
      .s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id(s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id ),
      .s_axis_c2h_cmpt_ctrl_port_id  (3'b000),
      .s_axis_c2h_cmpt_ctrl_marker   (s_axis_c2h_cmpt_ctrl_marker),
      .s_axis_c2h_cmpt_ctrl_user_trig(s_axis_c2h_cmpt_ctrl_user_trig),
      .s_axis_c2h_cmpt_ctrl_col_idx  (s_axis_c2h_cmpt_ctrl_col_idx),
      .s_axis_c2h_cmpt_ctrl_err_idx  (s_axis_c2h_cmpt_ctrl_err_idx),

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
      .tm_dsc_sts_rdy    (tm_dsc_sts_rdy),

      .dsc_crdt_in_vld  (dsc_crdt_in_vld),
      .dsc_crdt_in_rdy  (dsc_crdt_in_rdy),
      .dsc_crdt_in_dir  (dsc_crdt_in_dir),
      .dsc_crdt_in_fence(dsc_crdt_in_fence),
      .dsc_crdt_in_qid  (dsc_crdt_in_qid),
      .dsc_crdt_in_crdt (dsc_crdt_in_crdt),

      .usr_irq_in_vld   (usr_irq_in_vld),
      .usr_irq_in_vec   (usr_irq_in_vec),
      .usr_irq_in_fnc   (usr_irq_in_fnc),
      .usr_irq_out_ack  (usr_irq_out_ack),
      .usr_irq_out_fail (usr_irq_out_fail),
      .st_rx_msg_rdy    (st_rx_msg_rdy),
      .st_rx_msg_valid  (st_rx_msg_valid),
      .st_rx_msg_last   (st_rx_msg_last),
      .st_rx_msg_data   (st_rx_msg_data),

      .usr_flr_fnc       (usr_flr_fnc),
      .usr_flr_set       (usr_flr_set),
      .usr_flr_clr       (usr_flr_clr),
      .usr_flr_done_fnc  (usr_flr_done_fnc),
      .usr_flr_done_vld  (usr_flr_done_vld),
      .user_lnk_up ( user_lnk_up )
 );


design_1_wrapper u_interconnect (
    .ACLK_1           (axi_aclk_100),
    .resetn           (axi_aresetn_100),

    .m_axi_0_araddr   (S0_AXI_ARADDR),
    .m_axi_0_arprot   (),
    .m_axi_0_arready  (S0_AXI_ARREADY),
    .m_axi_0_arvalid  (S0_AXI_ARVALID),
    .m_axi_0_awaddr   (S0_AXI_AWADDR),
    .m_axi_0_awprot   (),
    .m_axi_0_awready  (S0_AXI_AWREADY),
    .m_axi_0_awvalid  (S0_AXI_AWVALID),
    .m_axi_0_bready   (S0_AXI_BREADY),
    .m_axi_0_bresp    (S0_AXI_BRESP),
    .m_axi_0_bvalid   (S0_AXI_BVALID),
    .m_axi_0_rdata    (S0_AXI_RDATA),
    .m_axi_0_rready   (S0_AXI_RREADY),
    .m_axi_0_rresp    (S0_AXI_RRESP),
    .m_axi_0_rvalid   (S0_AXI_RVALID),
    .m_axi_0_wdata    (S0_AXI_WDATA ),
    .m_axi_0_wready   (S0_AXI_WREADY),
    .m_axi_0_wstrb    (S0_AXI_WSTRB),
    .m_axi_0_wvalid   (S0_AXI_WVALID),

    .m_axi_1_araddr   (S1_AXI_ARADDR),
    .m_axi_1_arprot   (),
    .m_axi_1_arready  (S1_AXI_ARREADY),
    .m_axi_1_arvalid  (S1_AXI_ARVALID),
    .m_axi_1_awaddr   (S1_AXI_AWADDR),
    .m_axi_1_awprot   (),
    .m_axi_1_awready  (S1_AXI_AWREADY),
    .m_axi_1_awvalid  (S1_AXI_AWVALID),
    .m_axi_1_bready   (S1_AXI_BREADY),
    .m_axi_1_bresp    (S1_AXI_BRESP),
    .m_axi_1_bvalid   (S1_AXI_BVALID),
    .m_axi_1_rdata    (S1_AXI_RDATA),
    .m_axi_1_rready   (S1_AXI_RREADY),
    .m_axi_1_rresp    (S1_AXI_RRESP),
    .m_axi_1_rvalid   (S1_AXI_RVALID),
    .m_axi_1_wdata    (S1_AXI_WDATA ),
    .m_axi_1_wready   (S1_AXI_WREADY),
    .m_axi_1_wstrb    (S1_AXI_WSTRB),
    .m_axi_1_wvalid   (S1_AXI_WVALID),

    .m_axi_2_araddr   (S2_AXI_ARADDR),
    .m_axi_2_arprot   (),
    .m_axi_2_arready  (S2_AXI_ARREADY),
    .m_axi_2_arvalid  (S2_AXI_ARVALID),
    .m_axi_2_awaddr   (S2_AXI_AWADDR),
    .m_axi_2_awprot   (),
    .m_axi_2_awready  (S2_AXI_AWREADY),
    .m_axi_2_awvalid  (S2_AXI_AWVALID),
    .m_axi_2_bready   (S2_AXI_BREADY),
    .m_axi_2_bresp    (S2_AXI_BRESP),
    .m_axi_2_bvalid   (S2_AXI_BVALID),
    .m_axi_2_rdata    (S2_AXI_RDATA),
    .m_axi_2_rready   (S2_AXI_RREADY),
    .m_axi_2_rresp    (S2_AXI_RRESP),
    .m_axi_2_rvalid   (S2_AXI_RVALID),
    .m_axi_2_wdata    (S2_AXI_WDATA ),
    .m_axi_2_wready   (S2_AXI_WREADY),
    .m_axi_2_wstrb    (S2_AXI_WSTRB),
    .m_axi_2_wvalid   (S2_AXI_WVALID),

    .m_axi_3_araddr   (S3_AXI_ARADDR),
    .m_axi_3_arprot   (),
    .m_axi_3_arready  (S3_AXI_ARREADY),
    .m_axi_3_arvalid  (S3_AXI_ARVALID),
    .m_axi_3_awaddr   (S3_AXI_AWADDR),
    .m_axi_3_awprot   (),
    .m_axi_3_awready  (S3_AXI_AWREADY),
    .m_axi_3_awvalid  (S3_AXI_AWVALID),
    .m_axi_3_bready   (S3_AXI_BREADY),
    .m_axi_3_bresp    (S3_AXI_BRESP),
    .m_axi_3_bvalid   (S3_AXI_BVALID),
    .m_axi_3_rdata    (S3_AXI_RDATA),
    .m_axi_3_rready   (S3_AXI_RREADY),
    .m_axi_3_rresp    (S3_AXI_RRESP),
    .m_axi_3_rvalid   (S3_AXI_RVALID),
    .m_axi_3_wdata    (S3_AXI_WDATA ),
    .m_axi_3_wready   (S3_AXI_WREADY),
    .m_axi_3_wstrb    (S3_AXI_WSTRB),
    .m_axi_3_wvalid   (S3_AXI_WVALID),

    .m_axi_4_araddr   (S4_AXI_ARADDR),
    .m_axi_4_arprot   (),
    .m_axi_4_arready  (S4_AXI_ARREADY),
    .m_axi_4_arvalid  (S4_AXI_ARVALID),
    .m_axi_4_awaddr   (S4_AXI_AWADDR),
    .m_axi_4_awprot   (),
    .m_axi_4_awready  (S4_AXI_AWREADY),
    .m_axi_4_awvalid  (S4_AXI_AWVALID),
    .m_axi_4_bready   (S4_AXI_BREADY),
    .m_axi_4_bresp    (S4_AXI_BRESP),
    .m_axi_4_bvalid   (S4_AXI_BVALID),
    .m_axi_4_rdata    (S4_AXI_RDATA),
    .m_axi_4_rready   (S4_AXI_RREADY),
    .m_axi_4_rresp    (S4_AXI_RRESP),
    .m_axi_4_rvalid   (S4_AXI_RVALID),
    .m_axi_4_wdata    (S4_AXI_WDATA ),
    .m_axi_4_wready   (S4_AXI_WREADY),
    .m_axi_4_wstrb    (S4_AXI_WSTRB),
    .m_axi_4_wvalid   (S4_AXI_WVALID),

    .m_axi_5_araddr   (S5_AXI_ARADDR),
    .m_axi_5_arprot   (),
    .m_axi_5_arready  (S5_AXI_ARREADY),
    .m_axi_5_arvalid  (S5_AXI_ARVALID),
    .m_axi_5_awaddr   (S5_AXI_AWADDR),
    .m_axi_5_awprot   (),
    .m_axi_5_awready  (S5_AXI_AWREADY),
    .m_axi_5_awvalid  (S5_AXI_AWVALID),
    .m_axi_5_bready   (S5_AXI_BREADY),
    .m_axi_5_bresp    (S5_AXI_BRESP),
    .m_axi_5_bvalid   (S5_AXI_BVALID),
    .m_axi_5_rdata    (S5_AXI_RDATA),
    .m_axi_5_rready   (S5_AXI_RREADY),
    .m_axi_5_rresp    (S5_AXI_RRESP),
    .m_axi_5_rvalid   (S5_AXI_RVALID),
    .m_axi_5_wdata    (S5_AXI_WDATA ),
    .m_axi_5_wready   (S5_AXI_WREADY),
    .m_axi_5_wstrb    (S5_AXI_WSTRB),
    .m_axi_5_wvalid   (S5_AXI_WVALID),

    .s_axi_lite_araddr  (m_axil_araddr[31:0]),
    .s_axi_lite_arburst (),
    .s_axi_lite_arcache (),
    .s_axi_lite_arlen   (),
    .s_axi_lite_arlock  (),
//    .s_axi_lite_arprot  (m_axil_arprot),
    .s_axi_lite_arqos   (),
    .s_axi_lite_arready (m_axil_arready),
    .s_axi_lite_arsize  (),
    .s_axi_lite_arvalid (m_axil_arvalid),
    .s_axi_lite_awaddr  (m_axil_awaddr[31:0]),
    .s_axi_lite_awburst (),
    .s_axi_lite_awcache (),
    .s_axi_lite_awlen   (),
    .s_axi_lite_awlock  (),
//    .s_axi_lite_awprot  (m_axil_awprot),
    .s_axi_lite_awqos   (),
    .s_axi_lite_awready (m_axil_awready),
    .s_axi_lite_awsize  (),
    .s_axi_lite_awvalid (m_axil_awvalid),
    .s_axi_lite_bready  (m_axil_bready),
    .s_axi_lite_bresp   (m_axil_bresp),
    .s_axi_lite_bvalid  (m_axil_bvalid),
    .s_axi_lite_rdata   (m_axil_rdata),
    .s_axi_lite_rlast   (),
    .s_axi_lite_rready  (m_axil_rready),
    .s_axi_lite_rresp   (m_axil_rresp),
    .s_axi_lite_rvalid  (m_axil_rvalid),
    .s_axi_lite_wdata   (m_axil_wdata[31:0]),
    .s_axi_lite_wlast   (),
    .s_axi_lite_wready  (m_axil_wready),
    .s_axi_lite_wstrb   (m_axil_wstrb[3:0]),
    .s_axi_lite_wvalid  (m_axil_wvalid) 
);
  // XDMA taget application
  qdma_app #(
    .C_M_AXI_ID_WIDTH(C_M_AXI_ID_WIDTH),
    .MAX_DATA_WIDTH(C_DATA_WIDTH),
    .TDEST_BITS(16),
    .TCQ(TCQ)
 ) qdma_app_i (
    .clk(axi_aclk),
    .rst_n(axi_aresetn),
    .soft_reset_n(soft_reset_n),

    // AXI Lite Master Interface connections
    //.s_axil_awaddr (m_axil_awaddr[31:0]),
    //.s_axil_awvalid(m_axil_awvalid),
    //.s_axil_awready(m_axil_awready),
    //.s_axil_wdata  (m_axil_wdata[31:0]),    // block fifo for AXI lite only 31 bits.
    //.s_axil_wstrb  (m_axil_wstrb[3:0]),
    //.s_axil_wvalid (m_axil_wvalid),
    //.s_axil_wready (m_axil_wready),
    //.s_axil_bresp  (m_axil_bresp),
    //.s_axil_bvalid (m_axil_bvalid),
    //.s_axil_bready (m_axil_bready),
    //.s_axil_araddr (m_axil_araddr[31:0]),
    //.s_axil_arvalid(m_axil_arvalid),
    //.s_axil_arready(m_axil_arready),
    //.s_axil_rdata  (m_axil_rdata),   // block ram for AXI Lite is only 31 bits
    //.s_axil_rresp  (m_axil_rresp),
    //.s_axil_rvalid (m_axil_rvalid),
    //.s_axil_rready (m_axil_rready),



    .user_clk(axi_aclk),
    .user_resetn(axi_aresetn),
    .user_lnk_up(user_lnk_up),


    .usr_flr_fnc (usr_flr_fnc),
    .usr_flr_set (usr_flr_set),
    .usr_flr_clr (usr_flr_clr) ,
    .usr_flr_done_fnc (usr_flr_done_fnc),
    .usr_flr_done_vld (usr_flr_done_vld),

  .sys_rst_n(sys_rst_n_c),

  .m_axis_h2c_tvalid     (m_axis_h2c_tvalid),
  .m_axis_h2c_tready     (m_axis_h2c_tready),
  .m_axis_h2c_tdata      (m_axis_h2c_tdata),
  .m_axis_h2c_dpar       (m_axis_h2c_dpar),
  .m_axis_h2c_tlast      (m_axis_h2c_tlast),
  .m_axis_h2c_tuser_qid  (m_axis_h2c_tuser_qid),
  .m_axis_h2c_tuser_port_id(m_axis_h2c_tuser_port_id),
  .m_axis_h2c_tuser_err  (m_axis_h2c_tuser_err),
  .m_axis_h2c_tuser_mdata(m_axis_h2c_tuser_mdata),
  .m_axis_h2c_tuser_mty  (m_axis_h2c_tuser_mty),
  .m_axis_h2c_tuser_zero_byte(m_axis_h2c_tuser_zero_byte),

  .axis_c2h_status_drop  (axis_c2h_status_drop),
  .axis_c2h_status_valid (axis_c2h_status_valid),

  .s_axis_c2h_tdata      (s_axis_c2h_tdata ),
  .s_axis_c2h_dpar       (s_axis_c2h_dpar ),
  .s_axis_c2h_ctrl_marker(s_axis_c2h_ctrl_marker),
  .s_axis_c2h_ctrl_len   (s_axis_c2h_ctrl_len), // c2h_st_len,
  .s_axis_c2h_ctrl_qid   (s_axis_c2h_ctrl_qid ), // st_qid,
  .s_axis_c2h_ctrl_has_cmpt (s_axis_c2h_ctrl_has_cmpt),   // write back is valid
  .s_axis_c2h_tvalid     (s_axis_c2h_tvalid),
  .s_axis_c2h_tready     (s_axis_c2h_tready),
  .s_axis_c2h_tlast      (s_axis_c2h_tlast ),
  .s_axis_c2h_mty        (s_axis_c2h_mty),  // no empthy bytes at EOP

  .s_axis_c2h_cmpt_tdata    (s_axis_c2h_cmpt_tdata),
  .s_axis_c2h_cmpt_size     (s_axis_c2h_cmpt_size),
  .s_axis_c2h_cmpt_dpar     (s_axis_c2h_cmpt_dpar),
  .s_axis_c2h_cmpt_tvalid   (s_axis_c2h_cmpt_tvalid),
  .s_axis_c2h_cmpt_tready   (s_axis_c2h_cmpt_tready),
  .s_axis_c2h_cmpt_ctrl_qid (s_axis_c2h_cmpt_ctrl_qid),
  .s_axis_c2h_cmpt_ctrl_cmpt_type (s_axis_c2h_cmpt_ctrl_cmpt_type),
  .s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id(s_axis_c2h_cmpt_ctrl_wait_pld_pkt_id ),
  .s_axis_c2h_cmpt_ctrl_marker    (s_axis_c2h_cmpt_ctrl_marker),
  .s_axis_c2h_cmpt_ctrl_user_trig (s_axis_c2h_cmpt_ctrl_user_trig),
  .s_axis_c2h_cmpt_ctrl_col_idx   (s_axis_c2h_cmpt_ctrl_col_idx),
  .s_axis_c2h_cmpt_ctrl_err_idx   (s_axis_c2h_cmpt_ctrl_err_idx),

  .usr_irq_in_vld   (usr_irq_in_vld),
  .usr_irq_in_vec   (usr_irq_in_vec),
  .usr_irq_in_fnc   (usr_irq_in_fnc),
  .usr_irq_out_ack  (usr_irq_out_ack),
  .usr_irq_out_fail (usr_irq_out_fail),

  .st_rx_msg_rdy   (st_rx_msg_rdy),
  .st_rx_msg_valid (st_rx_msg_valid),
  .st_rx_msg_last  (st_rx_msg_last),
  .st_rx_msg_data  (st_rx_msg_data),

  .tm_dsc_sts_vld     (tm_dsc_sts_vld),
  .tm_dsc_sts_qen     (tm_dsc_sts_qen),
  .tm_dsc_sts_byp     (tm_dsc_sts_byp),
  .tm_dsc_sts_dir     (tm_dsc_sts_dir),
  .tm_dsc_sts_mm      (tm_dsc_sts_mm),
  .tm_dsc_sts_error   (tm_dsc_sts_error),
  .tm_dsc_sts_qid     (tm_dsc_sts_qid),
  .tm_dsc_sts_avl     (tm_dsc_sts_avl),
  .tm_dsc_sts_qinv    (tm_dsc_sts_qinv),
  .tm_dsc_sts_irq_arm (tm_dsc_sts_irq_arm),
  .tm_dsc_sts_rdy     (tm_dsc_sts_rdy),

  .dsc_crdt_in_vld   (dsc_crdt_in_vld),
  .dsc_crdt_in_rdy   (dsc_crdt_in_rdy),
  .dsc_crdt_in_dir   (dsc_crdt_in_dir),
  .dsc_crdt_in_fence (dsc_crdt_in_fence),
  .dsc_crdt_in_qid   (dsc_crdt_in_qid),
  .dsc_crdt_in_crdt  (dsc_crdt_in_crdt),


    .leds(leds)
 );

endmodule




