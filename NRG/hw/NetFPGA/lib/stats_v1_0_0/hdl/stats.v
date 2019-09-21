//-
// Copyright (C) 2016 
// All rights reserved.
//
//
// @NETFPGA_LICENSE_HEADER_START@
//
// Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
// license agreements.  See the NOTICE file distributed with this work for
// additional information regarding copyright ownership.  NetFPGA licenses this
// file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
// "License"); you may not use this file except in compliance with the
// License.  You may obtain a copy of the License at:
//
//   http://www.netfpga-cic.org
//
// Unless required by applicable law or agreed to in writing, Work distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations under the License.
//
// @NETFPGA_LICENSE_HEADER_END@
//
/*******************************************************************************
 *  File:
 *        stats.v
 *
 *  Library:
 *        hw/std/cores/stats
 *
 *  Module:
 *        stats
 *
 *  Author:
* 		
 *  Description:
 *        A simple statsitics collection module
 *
 */

`include "stats_cpu_regs_defines.v"

module stats
#(
    // Master AXI Stream Data Width
    parameter C_M_AXIS_DATA_WIDTH=256,
    parameter C_S_AXIS_DATA_WIDTH=256,
    parameter C_M_AXIS_TUSER_WIDTH=128,
    parameter C_S_AXIS_TUSER_WIDTH=128,
    
    // AXI Registers Data Width
    parameter C_S_AXI_DATA_WIDTH    = 32,          
    parameter C_S_AXI_ADDR_WIDTH    = 12,          
    parameter C_BASEADDR            = 32'h00000000
 
)
(
    // Part 1: System side signals
    // Global Ports
    input axis_aclk,
    input axis_resetn,


    // Slave Stream Ports 0
    input [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_0_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_0_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_0_tuser,
    input  s_axis_0_tvalid,
    input s_axis_0_tready,
    input  s_axis_0_tlast,


    // Slave Stream Ports 1
    input [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_1_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_1_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_1_tuser,
    input  s_axis_1_tvalid,
    input s_axis_1_tready,
    input  s_axis_1_tlast,

   
    // Slave AXI Ports
    input                                     S_AXI_ACLK,
    input                                     S_AXI_ARESETN,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_AWADDR,
    input                                     S_AXI_AWVALID,
    input      [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_WDATA,
    input      [C_S_AXI_DATA_WIDTH/8-1 : 0]   S_AXI_WSTRB,
    input                                     S_AXI_WVALID,
    input                                     S_AXI_BREADY,
    input      [C_S_AXI_ADDR_WIDTH-1 : 0]     S_AXI_ARADDR,
    input                                     S_AXI_ARVALID,
    input                                     S_AXI_RREADY,
    output                                    S_AXI_ARREADY,
    output     [C_S_AXI_DATA_WIDTH-1 : 0]     S_AXI_RDATA,
    output     [1 : 0]                        S_AXI_RRESP,
    output                                    S_AXI_RVALID,
    output                                    S_AXI_WREADY,
    output     [1 :0]                         S_AXI_BRESP,
    output                                    S_AXI_BVALID,
    output                                    S_AXI_AWREADY
    
);

   function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
   endfunction // log2

   // ------------ Internal Params --------


   localparam MAX_PKT_SIZE = 2000; // In bytes
   localparam IN_FIFO_DEPTH_BIT = log2(MAX_PKT_SIZE/(C_M_AXIS_DATA_WIDTH / 8));

   // ------------- Regs/ wires -----------

   wire                nearly_full;
   wire                empty;
   wire                 rd_en;

  reg				       pkt_fwd_next;

    wire [C_S_AXIS_DATA_WIDTH - 1:0] fifo_tdata;
    wire [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] fifo_tkeep;
    wire [C_S_AXIS_TUSER_WIDTH-1:0] fifo_tuser;
    wire  fifo_tvalid;
    wire fifo_tready;
    wire  fifo_tlast;

  //Selected slave interface
    wire [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_tdata;
    wire [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_tkeep;
    wire [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_tuser;
    wire s_axis_tvalid;
    wire s_axis_tready;
    wire s_axis_tlast;

   
    // define registers
   reg      [`REG_ID_BITS]    id_reg;
    reg      [`REG_VERSION_BITS]    version_reg;
    wire     [`REG_RESET_BITS]    reset_reg;
    reg      [`REG_FLIP_BITS]    ip2cpu_flip_reg;
    wire     [`REG_FLIP_BITS]    cpu2ip_flip_reg;
    reg      [`REG_DEBUG_BITS]    ip2cpu_debug_reg;
    wire     [`REG_DEBUG_BITS]    cpu2ip_debug_reg;
    reg      [`REG_PKTIN_BITS]    pktin_reg;
    wire                             pktin_reg_clear;
    reg      [`REG_PKTOUT_BITS]    pktout_reg;
    wire                             pktout_reg_clear;
    reg      [`REG_TESTTRIGGER_BITS]    ip2cpu_testtrigger_reg;
    wire     [`REG_TESTTRIGGER_BITS]    cpu2ip_testtrigger_reg;
    reg      [`REG_BWGRANULARITY_BITS]    ip2cpu_bwgranularity_reg;
    wire     [`REG_BWGRANULARITY_BITS]    cpu2ip_bwgranularity_reg;
    reg      [`REG_BWDIVISOR_BITS]    ip2cpu_bwdivisor_reg;
    wire     [`REG_BWDIVISOR_BITS]    cpu2ip_bwdivisor_reg;
    reg      [`REG_BURSTGAP_BITS]    ip2cpu_burstgap_reg;
    wire     [`REG_BURSTGAP_BITS]    cpu2ip_burstgap_reg;
    reg      [`REG_TESTEND_BITS]    ip2cpu_testend_reg;
    wire     [`REG_TESTEND_BITS]    cpu2ip_testend_reg;
    reg      [`REG_FIRSTTIME_BITS]    ip2cpu_firsttime_reg;
    wire     [`REG_FIRSTTIME_BITS]    cpu2ip_firsttime_reg;
    reg      [`REG_LASTTIME_BITS]    ip2cpu_lasttime_reg;
    wire     [`REG_LASTTIME_BITS]    cpu2ip_lasttime_reg;
    reg      [`REG_LASTBW_BITS]    ip2cpu_lastbw_reg;
    wire     [`REG_LASTBW_BITS]    cpu2ip_lastbw_reg;
    wire     [`REG_INPUTSEL_BITS]    inputsel_reg;
       reg      [`REG_ARPCOUNT_BITS]    ip2cpu_arpcount_reg;
    wire     [`REG_ARPCOUNT_BITS]    cpu2ip_arpcount_reg;
    reg      [`REG_IP4COUNT_BITS]    ip2cpu_ip4count_reg;
    wire     [`REG_IP4COUNT_BITS]    cpu2ip_ip4count_reg;
    reg      [`REG_IP6COUNT_BITS]    ip2cpu_ip6count_reg;
    wire     [`REG_IP6COUNT_BITS]    cpu2ip_ip6count_reg;
    reg      [`REG_TCPCOUNT_BITS]    ip2cpu_tcpcount_reg;
    wire     [`REG_TCPCOUNT_BITS]    cpu2ip_tcpcount_reg;
    reg      [`REG_UDPCOUNT_BITS]    ip2cpu_udpcount_reg;
    wire     [`REG_UDPCOUNT_BITS]    cpu2ip_udpcount_reg;
    reg      [`REG_SYNCOUNT_BITS]    ip2cpu_syncount_reg;
    wire     [`REG_SYNCOUNT_BITS]    cpu2ip_syncount_reg;
    reg      [`REG_FINCOUNT_BITS]    ip2cpu_fincount_reg;
    wire     [`REG_FINCOUNT_BITS]    cpu2ip_fincount_reg;
    reg      [`REG_FLOWIDCOUNT_BITS]    ip2cpu_flowidcount_reg;
    wire     [`REG_FLOWIDCOUNT_BITS]    cpu2ip_flowidcount_reg;
    wire     [`REG_PATTERNMATCH1_BITS]    patternmatch1_reg;
    wire     [`REG_PATTERNMATCH2_BITS]    patternmatch2_reg;
    wire     [`REG_PATTERNMATCH3_BITS]    patternmatch3_reg;
    wire     [`REG_PATTERNMATCH4_BITS]    patternmatch4_reg;
    wire     [`REG_PATTERNMATCH5_BITS]    patternmatch5_reg;
    wire     [`REG_PATTERNMATCH6_BITS]    patternmatch6_reg;
    wire     [`REG_PATTERNMATCH7_BITS]    patternmatch7_reg;
    wire     [`REG_PATTERNMATCH8_BITS]    patternmatch8_reg;
    wire     [`REG_PATTERNMATCH9_BITS]    patternmatch9_reg;
    wire     [`REG_PATTERNMATCH10_BITS]    patternmatch10_reg;
    wire     [`REG_PATTERNMATCH11_BITS]    patternmatch11_reg;
    wire     [`REG_PATTERNMATCH12_BITS]    patternmatch12_reg;
    wire     [`REG_PATTERNMATCH13_BITS]    patternmatch13_reg;
    wire     [`REG_PATTERNMATCH14_BITS]    patternmatch14_reg;
    wire     [`REG_PATTERNMATCH15_BITS]    patternmatch15_reg;
    wire     [`REG_PATTERNMATCH16_BITS]    patternmatch16_reg;
    wire     [`REG_PATTERNMASK1_BITS]    patternmask1_reg;
    wire     [`REG_PATTERNMASK2_BITS]    patternmask2_reg;
    wire     [`REG_PATTERNMASK3_BITS]    patternmask3_reg;
    wire     [`REG_PATTERNMASK4_BITS]    patternmask4_reg;
    wire     [`REG_PATTERNMASK5_BITS]    patternmask5_reg;
    wire     [`REG_PATTERNMASK6_BITS]    patternmask6_reg;
    wire     [`REG_PATTERNMASK7_BITS]    patternmask7_reg;
    wire     [`REG_PATTERNMASK8_BITS]    patternmask8_reg;
    wire     [`REG_PATTERNMASK9_BITS]    patternmask9_reg;
    wire     [`REG_PATTERNMASK10_BITS]    patternmask10_reg;
    wire     [`REG_PATTERNMASK11_BITS]    patternmask11_reg;
    wire     [`REG_PATTERNMASK12_BITS]    patternmask12_reg;
    wire     [`REG_PATTERNMASK13_BITS]    patternmask13_reg;
    wire     [`REG_PATTERNMASK14_BITS]    patternmask14_reg;
    wire     [`REG_PATTERNMASK15_BITS]    patternmask15_reg;
    wire     [`REG_PATTERNMASK16_BITS]    patternmask16_reg;
    reg      [`REG_MATCHCOUNT_BITS]    ip2cpu_matchcount_reg;
    wire     [`REG_MATCHCOUNT_BITS]    cpu2ip_matchcount_reg;
    wire      [`MEM_PKTSIZEMEM_ADDR_BITS]    pktsizemem_addr;
    wire      [`MEM_PKTSIZEMEM_DATA_BITS]    pktsizemem_data;
    wire                              pktsizemem_rd_wrn;
    wire                              pktsizemem_cmd_valid;
    reg       [`MEM_PKTSIZEMEM_DATA_BITS]    pktsizemem_reply;
    reg                               pktsizemem_reply_valid;
    wire      [`MEM_IPGMEM_ADDR_BITS]    ipgmem_addr;
    wire      [`MEM_IPGMEM_DATA_BITS]    ipgmem_data;
    wire                              ipgmem_rd_wrn;
    wire                              ipgmem_cmd_valid;
    reg       [`MEM_IPGMEM_DATA_BITS]    ipgmem_reply;
    reg                               ipgmem_reply_valid;
    wire      [`MEM_BURSTMEM_ADDR_BITS]    burstmem_addr;
    wire      [`MEM_BURSTMEM_DATA_BITS]    burstmem_data;
    wire                              burstmem_rd_wrn;
    wire                              burstmem_cmd_valid;
    reg       [`MEM_BURSTMEM_DATA_BITS]    burstmem_reply;
    reg                               burstmem_reply_valid;
    wire      [`MEM_BWMEM_ADDR_BITS]    bwmem_addr;
    wire      [`MEM_BWMEM_DATA_BITS]    bwmem_data;
    wire                              bwmem_rd_wrn;
    wire                              bwmem_cmd_valid;
    reg       [`MEM_BWMEM_DATA_BITS]    bwmem_reply;
    reg                               bwmem_reply_valid;
    wire      [`MEM_BWTSMEM_ADDR_BITS]    bwtsmem_addr;
    wire      [`MEM_BWTSMEM_DATA_BITS]    bwtsmem_data;
    wire                              bwtsmem_rd_wrn;
    wire                              bwtsmem_cmd_valid;
    reg       [`MEM_BWTSMEM_DATA_BITS]    bwtsmem_reply;
    reg                               bwtsmem_reply_valid;
    wire      [`MEM_PPSMEM_ADDR_BITS]    ppsmem_addr;
    wire      [`MEM_PPSMEM_DATA_BITS]    ppsmem_data;
    wire                              ppsmem_rd_wrn;
    wire                              ppsmem_cmd_valid;
    reg       [`MEM_PPSMEM_DATA_BITS]    ppsmem_reply;
    reg                               ppsmem_reply_valid;
    wire      [`MEM_BWCDFMEM_ADDR_BITS]    bwcdfmem_addr;
    wire      [`MEM_BWCDFMEM_DATA_BITS]    bwcdfmem_data;
    wire                              bwcdfmem_rd_wrn;
    wire                              bwcdfmem_cmd_valid;
    reg       [`MEM_BWCDFMEM_DATA_BITS]    bwcdfmem_reply;
    reg                               bwcdfmem_reply_valid;
    wire      [`MEM_PPSCDFMEM_ADDR_BITS]    ppscdfmem_addr;
    wire      [`MEM_PPSCDFMEM_DATA_BITS]    ppscdfmem_data;
    wire                              ppscdfmem_rd_wrn;
    wire                              ppscdfmem_cmd_valid;
    reg       [`MEM_PPSCDFMEM_DATA_BITS]    ppscdfmem_reply;
    reg                               ppscdfmem_reply_valid;
    wire      [`MEM_FLOWIDMEM_ADDR_BITS]    flowidmem_addr;
    wire      [`MEM_FLOWIDMEM_DATA_BITS]    flowidmem_data;
    wire                              flowidmem_rd_wrn;
    wire                              flowidmem_cmd_valid;
    reg       [`MEM_FLOWIDMEM_DATA_BITS]    flowidmem_reply;
    reg                               flowidmem_reply_valid;
    wire      [`MEM_WINDOWSIZEMEM_ADDR_BITS]    windowsizemem_addr;
    wire      [`MEM_WINDOWSIZEMEM_DATA_BITS]    windowsizemem_data;
    wire                              windowsizemem_rd_wrn;
    wire                              windowsizemem_cmd_valid;
    reg       [`MEM_WINDOWSIZEMEM_DATA_BITS]    windowsizemem_reply;
    reg                               windowsizemem_reply_valid;


  // define and assign default little endian
    wire                                      reg_patternmatch1_default_little;
    wire                                      reg_patternmatch2_default_little;
    wire                                      reg_patternmatch3_default_little;
    wire                                      reg_patternmatch4_default_little;
    wire                                      reg_patternmatch5_default_little;
    wire                                      reg_patternmatch6_default_little;
    wire                                      reg_patternmatch7_default_little;
    wire                                      reg_patternmatch8_default_little;
    wire                                      reg_patternmatch9_default_little;
    wire                                      reg_patternmatch10_default_little;
    wire                                      reg_patternmatch11_default_little;
    wire                                      reg_patternmatch12_default_little;
    wire                                      reg_patternmatch13_default_little;
    wire                                      reg_patternmatch14_default_little;
    wire                                      reg_patternmatch15_default_little;
    wire                                      reg_patternmatch16_default_little;
    wire                                      reg_patternmask1_default_little;
    wire                                      reg_patternmask2_default_little;
    wire                                      reg_patternmask3_default_little;
    wire                                      reg_patternmask4_default_little;
    wire                                      reg_patternmask5_default_little;
    wire                                      reg_patternmask6_default_little;
    wire                                      reg_patternmask7_default_little;
    wire                                      reg_patternmask8_default_little;
    wire                                      reg_patternmask9_default_little;
    wire                                      reg_patternmask10_default_little;
    wire                                      reg_patternmask11_default_little;
    wire                                      reg_patternmask12_default_little;
    wire                                      reg_patternmask13_default_little;
    wire                                      reg_patternmask14_default_little;
    wire                                      reg_patternmask15_default_little;
    wire                                      reg_patternmask16_default_little;
    assign  reg_patternmatch1_default_little = `REG_PATTERNMATCH1_DEFAULT;
    assign  reg_patternmatch2_default_little = `REG_PATTERNMATCH2_DEFAULT;
    assign  reg_patternmatch3_default_little = `REG_PATTERNMATCH3_DEFAULT;
    assign  reg_patternmatch4_default_little = `REG_PATTERNMATCH4_DEFAULT;
    assign  reg_patternmatch5_default_little = `REG_PATTERNMATCH5_DEFAULT;
    assign  reg_patternmatch6_default_little = `REG_PATTERNMATCH6_DEFAULT;
    assign  reg_patternmatch7_default_little = `REG_PATTERNMATCH7_DEFAULT;
    assign  reg_patternmatch8_default_little = `REG_PATTERNMATCH8_DEFAULT;
    assign  reg_patternmatch9_default_little = `REG_PATTERNMATCH9_DEFAULT;
    assign  reg_patternmatch10_default_little = `REG_PATTERNMATCH10_DEFAULT;
    assign  reg_patternmatch11_default_little = `REG_PATTERNMATCH11_DEFAULT;
    assign  reg_patternmatch12_default_little = `REG_PATTERNMATCH12_DEFAULT;
    assign  reg_patternmatch13_default_little = `REG_PATTERNMATCH13_DEFAULT;
    assign  reg_patternmatch14_default_little = `REG_PATTERNMATCH14_DEFAULT;
    assign  reg_patternmatch15_default_little = `REG_PATTERNMATCH15_DEFAULT;
    assign  reg_patternmatch16_default_little = `REG_PATTERNMATCH16_DEFAULT;
    assign  reg_patternmask1_default_little = `REG_PATTERNMASK1_DEFAULT;
    assign  reg_patternmask2_default_little = `REG_PATTERNMASK2_DEFAULT;
    assign  reg_patternmask3_default_little = `REG_PATTERNMASK3_DEFAULT;
    assign  reg_patternmask4_default_little = `REG_PATTERNMASK4_DEFAULT;
    assign  reg_patternmask5_default_little = `REG_PATTERNMASK5_DEFAULT;
    assign  reg_patternmask6_default_little = `REG_PATTERNMASK6_DEFAULT;
    assign  reg_patternmask7_default_little = `REG_PATTERNMASK7_DEFAULT;
    assign  reg_patternmask8_default_little = `REG_PATTERNMASK8_DEFAULT;
    assign  reg_patternmask9_default_little = `REG_PATTERNMASK9_DEFAULT;
    assign  reg_patternmask10_default_little = `REG_PATTERNMASK10_DEFAULT;
    assign  reg_patternmask11_default_little = `REG_PATTERNMASK11_DEFAULT;
    assign  reg_patternmask12_default_little = `REG_PATTERNMASK12_DEFAULT;
    assign  reg_patternmask13_default_little = `REG_PATTERNMASK13_DEFAULT;
    assign  reg_patternmask14_default_little = `REG_PATTERNMASK14_DEFAULT;
    assign  reg_patternmask15_default_little = `REG_PATTERNMASK15_DEFAULT;
    assign  reg_patternmask16_default_little = `REG_PATTERNMASK16_DEFAULT;


   wire clear_counters;
   wire reset_registers;

    reg new_packet;

assign s_axis_tdata  = inputsel_reg[0] ? s_axis_1_tdata : s_axis_0_tdata;
assign s_axis_tkeep  = inputsel_reg[0] ? s_axis_1_tkeep : s_axis_0_tkeep;
assign s_axis_tuser  = inputsel_reg[0] ? s_axis_1_tuser : s_axis_0_tuser;
assign s_axis_tvalid = inputsel_reg[0] ? s_axis_1_tvalid : s_axis_0_tvalid;
assign s_axis_tready = inputsel_reg[0] ? s_axis_1_tready : s_axis_0_tready;
assign s_axis_tlast  = inputsel_reg[0] ? s_axis_1_tlast : s_axis_0_tlast;
     
fallthrough_small_fifo
        #( .WIDTH(C_M_AXIS_DATA_WIDTH+C_M_AXIS_TUSER_WIDTH+C_M_AXIS_DATA_WIDTH/8+1+1),
           .MAX_DEPTH_BITS(IN_FIFO_DEPTH_BIT))
      in_fifo
        (// Outputs
         .dout                           ({fifo_tready,fifo_tlast, fifo_tuser, fifo_tkeep, fifo_tdata}),
         .full                           (),
         .nearly_full                    (nearly_full),
	 .prog_full                      (),
         .empty                          (empty),
         // Inputs
         .din                            ({s_axis_tready,s_axis_tlast, s_axis_tuser, s_axis_tkeep, s_axis_tdata}),
         .wr_en                          (s_axis_tvalid & s_axis_tready & ~nearly_full),
         .rd_en                          (rd_en),
         .reset                          (~axis_resetn),
         .clk                            (axis_aclk)
       );


  assign rd_en = !empty ;

always @(posedge axis_aclk)
	if (~resetn_sync) begin
		new_packet <= #1 1'b1;
	end
	else begin
		new_packet <= #1 !empty & fifo_tlast ? 1'b1: empty ? new_packet : 1'b0;
        end
  


  // ------------- Logic ------------

  
/* 
   stats_mem your_instance_name (
    .clka(clka),    // input wire clka
    .ena(ena),      // input wire ena
    .wea(wea),      // input wire [0 : 0] wea
    .addra(addra),  // input wire [12 : 0] addra
    .dina(dina),    // input wire [31 : 0] dina
    .clkb(clkb),    // input wire clkb
    .enb(enb),      // input wire enb
    .addrb(addrb),  // input wire [12 : 0] addrb
    .doutb(doutb)  // output wire [31 : 0] doutb
  ); 
  
*/

  wire is_arp_pkt;
  wire is_ip_pkt;
  wire is_ip6_pkt;
  wire is_tcp_pkt;
  wire is_udp_pkt;
  wire is_broadcast;
  wire is_syn;
  wire is_fin;
  wire[15:0] window_size;
  wire [95:0] flow_id;
  wire parser_valid;

  header_parser
    #(.C_S_AXIS_DATA_WIDTH (C_S_AXIS_DATA_WIDTH)
      )
   header_parser_stats(// --- Interface to the previous stage
    .tdata (fifo_tdata),
    .tvalid (!empty),
    .tlast (fifo_tlast),
   
    .is_arp_pkt (is_arp_pkt),
    .is_ip_pkt  (is_ip_pkt),
    .is_ip6_pkt (is_ip6_pkt),
    .is_tcp_pkt (is_tcp_pkt),
    .is_udp_pkt (is_udp_pkt),
    .is_broadcast (is_broadcast),
    .is_syn (is_syn),
    .is_fin (is_fin),
    .window_size (window_size),
    .flow_id (flow_id),
    .parser_info_vld (parser_valid),

     .reset (~resetn_sync),
    .clk (axis_aclk)
   );


/////////////////////////////////////
//packet size statistics
/////////////////////////////////////

wire pktsize_mem_we;
wire [12:0] pktsize_mem_addra;
wire [12:0] pktsize_mem_addrb;
wire [31:0] pktsize_mem_din;
wire [31:0] pktsize_mem_dout;

reg pktsize_we;
reg [12:0] pktsize_addra;
reg [12:0] pktsize_addrb,pktsize_addrb2,pktsize_addrb3;
reg [31:0] pktsize_din;
wire [31:0] pktsize_dout;
reg pktsize_next_rd_reply,pktsize_next_rd_reply2,pktsize_next_rd_reply3;
reg pktsizemem_next_rd_reply,pktsizemem_next_rd_reply2;

 stats_mem pktsize_mem (
    .clka(axis_aclk),    // input wire clka
    .ena(axis_resetn),      // input wire ena
    .wea(pktsize_mem_we),      // input wire [0 : 0] wea
    .addra(pktsize_mem_addra),  // input wire [12 : 0] addra
    .dina(pktsize_mem_din),    // input wire [31 : 0] dina
    .clkb(axis_aclk),    // input wire clkb
    .enb(axis_resetn),      // input wire enb
    .addrb(pktsize_mem_addrb),  // input wire [12 : 0] addrb
    .doutb(pktsize_mem_dout)  // output wire [31 : 0] doutb
  ); 


assign pktsize_mem_we    = pktsizemem_cmd_valid & !pktsizemem_rd_wrn ? 1'b1 : pktsize_we;
assign pktsize_mem_addra = pktsizemem_cmd_valid & !pktsizemem_rd_wrn ? pktsizemem_addr : pktsize_addra;
assign pktsize_mem_din   = pktsizemem_cmd_valid & !pktsizemem_rd_wrn ? pktsizemem_data : pktsize_din;
assign pktsize_mem_addrb = pktsizemem_cmd_valid & pktsizemem_rd_wrn ? pktsizemem_addr : pktsize_addrb;

//indirect memory access read reply
always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
		pktsizemem_reply <= #1 0;
		pktsizemem_reply_valid	  <= #1 1'b0;
		pktsizemem_next_rd_reply  <= 1'b0;
		pktsizemem_next_rd_reply2 <= #1 1'b0;
	end
	else begin
		pktsizemem_next_rd_reply <= #1 pktsizemem_cmd_valid & pktsizemem_rd_wrn;
		pktsizemem_next_rd_reply2 <= #1 pktsizemem_next_rd_reply;
		pktsizemem_reply_valid <= #1 pktsizemem_next_rd_reply2;
		pktsizemem_reply <= #1 pktsizemem_next_rd_reply2 ? pktsize_mem_dout : pktsizemem_reply;
        end

//packet size statistics update
//note: this design currently does not support concurrent register access and packet count (will miss a packet)
always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
		pktsize_we <= #1 1'b0;
		pktsize_addra <= #1 0;
		pktsize_addrb <= #1 0;
		pktsize_addrb2 <= #1 0;
		pktsize_addrb3 <= #1 0;
		pktsize_din   <= #1 0;
		pktsize_next_rd_reply <= #1 1'b0;
		pktsize_next_rd_reply2 <= #1 1'b0;
		pktsize_next_rd_reply3 <= #1 1'b0;
	end
	else begin
		pktsize_we <= #1 pktsize_next_rd_reply3;
		pktsize_addra <= #1 pktsize_addrb3;
		pktsize_addrb <= #1 new_packet & !empty? fifo_tuser[12:0] : pktsize_addrb; // fix: new packet (last was tlast)
		pktsize_addrb2 <= #1 pktsize_addrb;
		pktsize_addrb3 <= #1 pktsize_addrb2;
		pktsize_din   <= #1 pktsize_next_rd_reply3 ? pktsize_mem_dout +1 : pktsize_din;
		pktsize_next_rd_reply <= #1 empty? 1'b0 : pktsizemem_cmd_valid & pktsizemem_rd_wrn ? 1'b0 : ip2cpu_testtrigger_reg[0] & new_packet;
		pktsize_next_rd_reply2 <= #1 pktsize_next_rd_reply;
		pktsize_next_rd_reply3 <= #1 pktsize_next_rd_reply2;
        end

/////////////////////////////////////
//packet gap statistics
/////////////////////////////////////

wire ipg_mem_we;
wire [12:0] ipg_mem_addra;
wire [12:0] ipg_mem_addrb;
wire [31:0] ipg_mem_din;
wire [31:0] ipg_mem_dout;

reg ipg_we;
reg [12:0] ipg_addra;
reg [12:0] ipg_addrb,ipg_addrb2,ipg_addrb3;
reg [31:0] ipg_din;
wire [31:0] ipg_dout;
reg ipg_next_rd_reply,ipg_next_rd_reply2,ipg_next_rd_reply3;
reg ipgmem_next_rd_reply,ipgmem_next_rd_reply2;
reg [31:0] ipg_counter;

 stats_mem ipg_mem (
    .clka(axis_aclk),    // input wire clka
    .ena(axis_resetn),      // input wire ena
    .wea(ipg_mem_we),      // input wire [0 : 0] wea
    .addra(ipg_mem_addra),  // input wire [12 : 0] addra
    .dina(ipg_mem_din),    // input wire [31 : 0] dina
    .clkb(axis_aclk),    // input wire clkb
    .enb(axis_resetn),      // input wire enb
    .addrb(ipg_mem_addrb),  // input wire [12 : 0] addrb
    .doutb(ipg_mem_dout)  // output wire [31 : 0] doutb
  ); 


assign ipg_mem_we    = ipgmem_cmd_valid & !ipgmem_rd_wrn ? 1'b1 : ipg_we;
assign ipg_mem_addra = ipgmem_cmd_valid & !ipgmem_rd_wrn ? ipgmem_addr : ipg_addra;
assign ipg_mem_din   = ipgmem_cmd_valid & !ipgmem_rd_wrn ? ipgmem_data : ipg_din;
assign ipg_mem_addrb = ipgmem_cmd_valid & ipgmem_rd_wrn ? ipgmem_addr : ipg_addrb;

//indirect memory access read reply
always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
		ipgmem_reply <= #1 0;
		ipgmem_reply_valid	<= #1 1'b0;
		ipgmem_next_rd_reply <= 1'b0;
		ipgmem_next_rd_reply2 <= 1'b0;
	end
	else begin
		ipgmem_next_rd_reply <= #1 ipgmem_cmd_valid & ipgmem_rd_wrn;
		ipgmem_next_rd_reply2 <= #1 ipgmem_next_rd_reply;
		ipgmem_reply_valid <= #1 ipgmem_next_rd_reply2;
		ipgmem_reply <= #1 ipgmem_next_rd_reply2 ? ipg_mem_dout : ipgmem_reply;
        end

//packet size statistics update
//note: this design currently does not support concurrent register access and packet count (will miss a packet)
always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
		ipg_we <= #1 1'b0;
		ipg_addra <= #1 0;
		ipg_addrb <= #1 0;
		ipg_addrb2 <= #1 0;
		ipg_addrb3 <= #1 0;
		ipg_din   <= #1 0;
		ipg_next_rd_reply <= #1 1'b0;
		ipg_next_rd_reply2<= #1 1'b0;
		ipg_next_rd_reply3<= #1 1'b0;
		ipg_counter <= #1 32'h0;
	end
	else begin
		ipg_counter <= #1 (!ip2cpu_testtrigger_reg[0]) | (new_packet & !empty) ? 32'h0 : (ipg_counter==32'hFFFFFFFF) ? ipg_counter : new_packet? ipg_counter+1 : 32'h0;
		ipg_we <= #1 ipg_next_rd_reply3;
		ipg_addra <= #1 ipg_addrb3;
		ipg_addrb2 <= #1 ipg_addrb;
		ipg_addrb3 <= #1 ipg_addrb2;
		ipg_addrb <= #1 new_packet & !empty? (ipg_counter < 32'h400 ? ipg_counter : ipg_counter < 32'h100000 ? 13'h400+(ipg_counter>>10) : 
				ipg_counter < 32'h40000000 ? 13'h800+(ipg_counter>>20) : 13'h1FFF) 
		 	       : ipg_addrb; // fix: new packet (last was tlast)
		ipg_din   <= #1 ipg_next_rd_reply3 ? ipg_mem_dout +1 : ipg_din;
		ipg_next_rd_reply <= #1 empty? 1'b0 : ipgmem_cmd_valid & ipgmem_rd_wrn ? 1'b0 : ip2cpu_testtrigger_reg[0] & new_packet;
		ipg_next_rd_reply2 <= #1 ipg_next_rd_reply;
		ipg_next_rd_reply3 <= #1 ipg_next_rd_reply2;
        end

/////////////////////////////////////
//burst size statistics
/////////////////////////////////////

wire burst_mem_we;
wire [12:0] burst_mem_addra;
wire [12:0] burst_mem_addrb;
wire [31:0] burst_mem_din;
wire [31:0] burst_mem_dout;

reg burst_we;
reg [12:0] burst_addra;
reg [12:0] burst_addrb,burst_addrb2,burst_addrb3;
reg [31:0] burst_din;
wire [31:0] burst_dout;
reg burst_next_rd_reply,burst_next_rd_reply2,burst_next_rd_reply3;
reg burstmem_next_rd_reply,burstmem_next_rd_reply2;
reg [31:0] burst_counter, burst_counter_prev;

 stats_mem burst_mem (
    .clka(axis_aclk),    // input wire clka
    .ena(axis_resetn),      // input wire ena
    .wea(burst_mem_we),      // input wire [0 : 0] wea
    .addra(burst_mem_addra),  // input wire [12 : 0] addra
    .dina(burst_mem_din),    // input wire [31 : 0] dina
    .clkb(axis_aclk),    // input wire clkb
    .enb(axis_resetn),      // input wire enb
    .addrb(burst_mem_addrb),  // input wire [12 : 0] addrb
    .doutb(burst_mem_dout)  // output wire [31 : 0] doutb
  ); 


assign burst_mem_we    = burstmem_cmd_valid & !burstmem_rd_wrn ? 1'b1 : burst_we;
assign burst_mem_addra = burstmem_cmd_valid & !burstmem_rd_wrn ? burstmem_addr : burst_addra;
assign burst_mem_din   = burstmem_cmd_valid & !burstmem_rd_wrn ? burstmem_data : burst_din;
assign burst_mem_addrb = burstmem_cmd_valid & burstmem_rd_wrn ? burstmem_addr : burst_addrb;

//indirect memory access read reply
always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
		burstmem_reply <= #1 0;
		burstmem_reply_valid	<= #1 1'b0;
		burstmem_next_rd_reply <= 1'b0;
		burstmem_next_rd_reply2 <= 1'b0;
	end
	else begin
		burstmem_next_rd_reply <= #1 burstmem_cmd_valid & burstmem_rd_wrn;
		burstmem_next_rd_reply2 <= #1 burstmem_next_rd_reply;
		burstmem_reply_valid <= #1 burstmem_next_rd_reply2;
		burstmem_reply <= #1 burstmem_next_rd_reply2 ? burst_mem_dout : burstmem_reply;
        end

//packet size statistics update
//note: this design currently does not support concurrent register access and packet count (will miss a packet)
always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
		burst_we <= #1 1'b0;
		burst_addra <= #1 0;
		burst_addrb <= #1 0;
		burst_addrb2 <= #1 0;
		burst_addrb3 <= #1 0;
		burst_din   <= #1 0;
		burst_next_rd_reply <= #1 1'b0;
		burst_next_rd_reply2<= #1 1'b0;
		burst_next_rd_reply3<= #1 1'b0;
		burst_counter <= #1 32'h1;
		burst_counter_prev <= #1 32'h1;
	end
	else begin
                //note that it is not an error: ipg_counter is used by burst statistics
		//limitation: does not count the last burst
		burst_counter <= #1 (!ip2cpu_testtrigger_reg[0]) ? 32'h1 :
				    (new_packet & !empty) ?
                                       ((ipg_counter<cpu2ip_burstgap_reg) ? ((burst_counter==32'hFFFFFFFF) ? burst_counter : burst_counter+1) : 32'h1) :
				     burst_counter;
                burst_counter_prev <= #1 (!ip2cpu_testtrigger_reg[0]) ? 32'h1:
				    (new_packet & !empty) & (ipg_counter>cpu2ip_burstgap_reg) ? burst_counter : burst_counter_prev;
		burst_we <= #1 burst_next_rd_reply3;
		burst_addra <= #1 burst_addrb3;
		burst_addrb2 <= #1 burst_addrb;
		burst_addrb3 <= #1 burst_addrb2;
		burst_addrb <= #1 (new_packet & !empty) & (ipg_counter>cpu2ip_burstgap_reg) ? burst_counter :  burst_addrb; // fix: new packet (last was tlast)
		burst_din   <= #1 burst_next_rd_reply3 ? burst_mem_dout +1 : burst_din;
		burst_next_rd_reply <= #1 empty? 1'b0 : burstmem_cmd_valid & burstmem_rd_wrn ? 1'b0 : (new_packet & !empty) & (ipg_counter>cpu2ip_burstgap_reg);
		burst_next_rd_reply2 <= #1 burst_next_rd_reply;
		burst_next_rd_reply3 <= #1 burst_next_rd_reply2;
        end

/////////////////////////////////////
//Bandwidth statistics
/////////////////////////////////////

wire bw_mem_we;
wire [12:0] bw_mem_addra;
wire [12:0] bw_mem_addrb;
wire [31:0] bw_mem_din;
wire [31:0] bw_mem_dout;

wire bw_cdf_mem_we;
wire [12:0] bw_cdf_mem_addra;
wire [12:0] bw_cdf_mem_addrb;
wire [31:0] bw_cdf_mem_din;
wire [31:0] bw_cdf_mem_dout;

wire pps_mem_we;
wire [12:0] pps_mem_addra;
wire [12:0] pps_mem_addrb;
wire [31:0] pps_mem_din;
wire [31:0] pps_mem_dout;

wire pps_cdf_mem_we;
wire [12:0] pps_cdf_mem_addra;
wire [12:0] pps_cdf_mem_addrb;
wire [31:0] pps_cdf_mem_din;
wire [31:0] pps_cdf_mem_dout;

reg bw_we;
reg [12:0] bw_addra;
reg [12:0] bw_addrb;//,bw_addrb2,bw_addrb3;
reg [31:0] bw_din;
wire [31:0] bw_dout;
reg bw_next_rd_reply;///,bw_next_rd_reply2,bw_next_rd_reply3;
reg bwmem_next_rd_reply,bwmem_next_rd_reply2;
reg [31:0] bw_timer;
reg [63:0] bytes_counter;
reg bw_update;
reg bw_go;

//reg pps_we;
reg [12:0] pps_addra;
reg [12:0] pps_addrb;
reg [31:0] pps_din;
wire [31:0] pps_dout;
//reg pps_next_rd_reply;
reg ppsmem_next_rd_reply,ppsmem_next_rd_reply2;
reg [31:0] pps_counter;

reg bw_cdf_we; 
reg [12:0] bw_cdf_addra;
reg [12:0] bw_cdf_addrb,bw_cdf_addrb2,bw_cdf_addrb3;
reg [31:0] bw_cdf_din;
wire [31:0] bw_cdf_dout;
reg bw_cdf_next_rd_reply,bw_cdf_next_rd_reply2,bw_cdf_next_rd_reply3;
reg bwcdfmem_next_rd_reply,bwcdfmem_next_rd_reply2;

reg pps_cdf_we;
reg [12:0] pps_cdf_addra;
reg [12:0] pps_cdf_addrb,pps_cdf_addrb2,pps_cdf_addrb3;
reg [31:0] pps_cdf_din;
wire [31:0] pps_cdf_dout;
reg pps_cdf_next_rd_reply,pps_cdf_next_rd_reply2,pps_cdf_next_rd_reply3;
reg ppscdfmem_next_rd_reply,ppscdfmem_next_rd_reply2;



wire bw_tsmem_we;
wire [12:0] bw_tsmem_addra;
wire [12:0] bw_tsmem_addrb;
wire [31:0] bw_tsmem_din;
wire [31:0] bw_tsmem_dout;
reg bwtsmem_next_rd_reply,bwtsmem_next_rd_reply2;

reg [31:0] bw_tsdin;
reg [31:0] bw_ts_counter;
reg [33:0] bw_delay;


 stats_mem bw_mem (
    .clka(axis_aclk),    // input wire clka
    .ena(axis_resetn),      // input wire ena
    .wea(bw_mem_we),      // input wire [0 : 0] wea
    .addra(bw_mem_addra),  // input wire [12 : 0] addra
    .dina(bw_mem_din),    // input wire [31 : 0] dina
    .clkb(axis_aclk),    // input wire clkb
    .enb(axis_resetn),      // input wire enb
    .addrb(bw_mem_addrb),  // input wire [12 : 0] addrb
    .doutb(bw_mem_dout)  // output wire [31 : 0] doutb
  ); 

 stats_mem pps_mem (
    .clka(axis_aclk),    // input wire clka
    .ena(axis_resetn),      // input wire ena
    .wea(pps_mem_we),      // input wire [0 : 0] wea
    .addra(pps_mem_addra),  // input wire [12 : 0] addra
    .dina(pps_mem_din),    // input wire [31 : 0] dina
    .clkb(axis_aclk),    // input wire clkb
    .enb(axis_resetn),      // input wire enb
    .addrb(pps_mem_addrb),  // input wire [12 : 0] addrb
    .doutb(pps_mem_dout)  // output wire [31 : 0] doutb
  ); 


 stats_mem bw_cdf_mem (
    .clka(axis_aclk),    // input wire clka
    .ena(axis_resetn),      // input wire ena
    .wea(bw_cdf_mem_we),      // input wire [0 : 0] wea
    .addra(bw_cdf_mem_addra),  // input wire [12 : 0] addra
    .dina(bw_cdf_mem_din),    // input wire [31 : 0] dina
    .clkb(axis_aclk),    // input wire clkb
    .enb(axis_resetn),      // input wire enb
    .addrb(bw_cdf_mem_addrb),  // input wire [12 : 0] addrb
    .doutb(bw_cdf_mem_dout)  // output wire [31 : 0] doutb
  ); 

 stats_mem pps_cdf_mem (
    .clka(axis_aclk),    // input wire clka
    .ena(axis_resetn),      // input wire ena
    .wea(pps_cdf_mem_we),      // input wire [0 : 0] wea
    .addra(pps_cdf_mem_addra),  // input wire [12 : 0] addra
    .dina(pps_cdf_mem_din),    // input wire [31 : 0] dina
    .clkb(axis_aclk),    // input wire clkb
    .enb(axis_resetn),      // input wire enb
    .addrb(pps_cdf_mem_addrb),  // input wire [12 : 0] addrb
    .doutb(pps_cdf_mem_dout)  // output wire [31 : 0] doutb
  ); 



 stats_mem bw_tsmem (
    .clka(axis_aclk),    // input wire clka
    .ena(axis_resetn),      // input wire ena
    .wea(bw_tsmem_we),      // input wire [0 : 0] wea
    .addra(bw_tsmem_addra),  // input wire [12 : 0] addra
    .dina(bw_tsmem_din),    // input wire [31 : 0] dina
    .clkb(axis_aclk),    // input wire clkb
    .enb(axis_resetn),      // input wire enb
    .addrb(bw_tsmem_addrb),  // input wire [12 : 0] addrb
    .doutb(bw_tsmem_dout)  // output wire [31 : 0] doutb
  ); 


assign bw_mem_we    = bwmem_cmd_valid & !bwmem_rd_wrn ? 1'b1 : bw_we;
assign bw_mem_addra = bwmem_cmd_valid & !bwmem_rd_wrn ? bwmem_addr : bw_addra;
assign bw_mem_din   = bwmem_cmd_valid & !bwmem_rd_wrn ? bwmem_data : bw_din;
assign bw_mem_addrb = bwmem_cmd_valid & bwmem_rd_wrn ? bwmem_addr : bw_addrb;

assign pps_mem_we    = ppsmem_cmd_valid & !ppsmem_rd_wrn ? 1'b1 : bw_we;
assign pps_mem_addra = ppsmem_cmd_valid & !ppsmem_rd_wrn ? ppsmem_addr : bw_addra;
assign pps_mem_din   = ppsmem_cmd_valid & !ppsmem_rd_wrn ? ppsmem_data : pps_din;
assign pps_mem_addrb = ppsmem_cmd_valid & ppsmem_rd_wrn ? ppsmem_addr : bw_addrb;

assign bw_cdf_mem_we    = bwcdfmem_cmd_valid & !bwcdfmem_rd_wrn ? 1'b1 : bw_cdf_we;
assign bw_cdf_mem_addra = bwcdfmem_cmd_valid & !bwcdfmem_rd_wrn ? bwcdfmem_addr : bw_cdf_addra;
assign bw_cdf_mem_din   = bwcdfmem_cmd_valid & !bwcdfmem_rd_wrn ? bwcdfmem_data : bw_cdf_din;
assign bw_cdf_mem_addrb = bwcdfmem_cmd_valid & bwcdfmem_rd_wrn ? bwcdfmem_addr : bw_cdf_addrb;

assign pps_cdf_mem_we    = ppscdfmem_cmd_valid & !ppscdfmem_rd_wrn ? 1'b1 : bw_we;
assign pps_cdf_mem_addra = ppscdfmem_cmd_valid & !ppscdfmem_rd_wrn ? ppscdfmem_addr : pps_cdf_addra;
assign pps_cdf_mem_din   = ppscdfmem_cmd_valid & !ppscdfmem_rd_wrn ? ppscdfmem_data : pps_cdf_din;
assign pps_cdf_mem_addrb = ppscdfmem_cmd_valid & ppscdfmem_rd_wrn ? ppscdfmem_addr : pps_cdf_addrb;


assign bw_tsmem_we    = bwtsmem_cmd_valid & !bwtsmem_rd_wrn ? 1'b1 : bw_we;
assign bw_tsmem_addra = bwtsmem_cmd_valid & !bwtsmem_rd_wrn ? bwtsmem_addr : bw_addra;
assign bw_tsmem_din   = bwtsmem_cmd_valid & !bwtsmem_rd_wrn ? bwtsmem_data : bw_tsdin;
assign bw_tsmem_addrb = bwtsmem_cmd_valid & bwtsmem_rd_wrn ? bwtsmem_addr : bw_addrb;

//indirect memory access read reply
always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
		bwmem_reply <= #1 0;
		bwmem_reply_valid	  <= #1 1'b0;
		bwmem_next_rd_reply  <= 1'b0;
		bwmem_next_rd_reply2 <= #1 1'b0;
	end
	else begin
		bwmem_next_rd_reply <= #1 bwmem_cmd_valid & bwmem_rd_wrn;
		bwmem_next_rd_reply2 <= #1 bwmem_next_rd_reply;
		bwmem_reply_valid <= #1 bwmem_next_rd_reply2;
		bwmem_reply <= #1 bwmem_next_rd_reply2 ? bw_mem_dout : bwmem_reply;
        end

//indirect pps memory access read reply
always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
		ppsmem_reply <= #1 0;
		ppsmem_reply_valid	  <= #1 1'b0;
		ppsmem_next_rd_reply  <= 1'b0;
		ppsmem_next_rd_reply2 <= #1 1'b0;
	end
	else begin
		ppsmem_next_rd_reply <= #1 ppsmem_cmd_valid & ppsmem_rd_wrn;
		ppsmem_next_rd_reply2 <= #1 ppsmem_next_rd_reply;
		ppsmem_reply_valid <= #1 ppsmem_next_rd_reply2;
		ppsmem_reply <= #1 ppsmem_next_rd_reply2 ? pps_mem_dout : ppsmem_reply;
        end

//indirect bw cdf memory access read reply
always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
		bwcdfmem_reply <= #1 0;
		bwcdfmem_reply_valid	<= #1 1'b0;
		bwcdfmem_next_rd_reply <= 1'b0;
		bwcdfmem_next_rd_reply2 <= 1'b0;
	end
	else begin
		bwcdfmem_next_rd_reply <= #1 bwcdfmem_cmd_valid & bwcdfmem_rd_wrn;
		bwcdfmem_next_rd_reply2 <= #1 bwcdfmem_next_rd_reply;
		bwcdfmem_reply_valid <= #1 bwcdfmem_next_rd_reply2;
		bwcdfmem_reply <= #1 bwcdfmem_next_rd_reply2 ? bw_cdf_mem_dout : bwcdfmem_reply;
        end

//indirect pps cdf memory access read reply
always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
		ppscdfmem_reply <= #1 0;
		ppscdfmem_reply_valid	<= #1 1'b0;
		ppscdfmem_next_rd_reply <= 1'b0;
		ppscdfmem_next_rd_reply2 <= 1'b0;
	end
	else begin
		ppscdfmem_next_rd_reply <= #1 ppscdfmem_cmd_valid & ppscdfmem_rd_wrn;
		ppscdfmem_next_rd_reply2 <= #1 ppscdfmem_next_rd_reply;
		ppscdfmem_reply_valid <= #1 ppscdfmem_next_rd_reply2;
		ppscdfmem_reply <= #1 ppscdfmem_next_rd_reply2 ? pps_cdf_mem_dout : ppscdfmem_reply;
        end


//indirect timestamp memory access read reply
always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
		bwtsmem_reply <= #1 0;
		bwtsmem_reply_valid	  <= #1 1'b0;
		bwtsmem_next_rd_reply  <= 1'b0;
		bwtsmem_next_rd_reply2 <= #1 1'b0;
	end
	else begin
		bwtsmem_next_rd_reply <= #1 bwtsmem_cmd_valid & bwtsmem_rd_wrn;
		bwtsmem_next_rd_reply2 <= #1 bwtsmem_next_rd_reply;
		bwtsmem_reply_valid <= #1 bwtsmem_next_rd_reply2;
		bwtsmem_reply <= #1 bwtsmem_next_rd_reply2 ? bw_tsmem_dout : bwtsmem_reply;
        end

//BW statistics update
//note: this design currently does not support concurrent register access and bw measurement (will miss an entry)
always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
		bw_we <= #1 1'b0;
		bw_addra <= #1 0;
		bw_addrb <= #1 0;
		bw_din   <= #1 0;
		bw_next_rd_reply <= #1 1'b0;
		bw_timer <= #1 32'h0;
		bytes_counter <= #1 64'h0;
		pps_counter <= #1 32'h0;
		bw_update <= #1 1'b0;
		bw_go <= #1 1'b0;
		bw_tsdin <= #1 32'b0;
		bw_ts_counter <= #1 32'b0;
		bw_delay <= #1 34'h0;
		pps_din <= #1 32'h0;
	end
	else begin
		bw_update <= #1 (bw_timer == ip2cpu_bwgranularity_reg) & (bytes_counter > 0) ;
		bw_we <= #1 (bw_timer == ip2cpu_bwgranularity_reg) & (bytes_counter > 0) ;
		bw_addra <= #1 reset_registers | clear_counters ? 13'h0 :  bw_addra == 13'h1FFF ? bw_addra : bw_go & (bw_delay==0) & ip2cpu_testtrigger_reg[0] & bw_update ? bw_addra+1 : bw_addra ;
		bw_addrb <= #1 bw_addrb; // Unused
		//bw_din   <= #1  (bw_timer == ip2cpu_bwgranularity_reg) ? (bytes_counter >> ip2cpu_bwdivisor_reg): bw_din;
		bw_din   <= #1  (bw_timer == ip2cpu_bwgranularity_reg) & (bytes_counter > 0) ? (bytes_counter >> ip2cpu_bwdivisor_reg): bw_din;
		pps_din  <= #1  (bw_timer == ip2cpu_bwgranularity_reg) & (bytes_counter > 0) ? pps_counter : pps_din;
		bw_next_rd_reply <= #1 1'h0; // Unused
		bw_timer <= #1 (ip2cpu_testtrigger_reg[0] == 0) | (bw_go==1'b0)| !(bw_delay==0) | reset_registers | clear_counters ? 32'h0 :  (bw_timer == ip2cpu_bwgranularity_reg) ? 32'h0: bw_timer + 1;
		bytes_counter <= #1 (ip2cpu_testtrigger_reg[0] == 0) | (bw_go==1'b0)| !(bw_delay==0) | reset_registers | clear_counters ? 32'h0 :  bw_update ? 32'h0 :
				    new_packet & !empty? (fifo_tuser[12:0]+bytes_counter < 65'h10000000000000000 ? fifo_tuser[12:0]+bytes_counter :  64'hFFFFFFFFFFFFFFFF) 
                                   : bytes_counter;
		pps_counter <= #1 (ip2cpu_testtrigger_reg[0] == 0) | (bw_go==1'b0)| !(bw_delay==0) | reset_registers | clear_counters ? 32'h0 :  bw_update ? 32'h0 :
				    new_packet & !empty? ((pps_counter<32'hFFFFFFFF) ? pps_counter+32'h1 :  32'hFFFFFFFF) 
                                   : pps_counter;
		bw_go <= #1 (ip2cpu_testtrigger_reg[0] == 0) | reset_registers | clear_counters ? 1'b0 : (ip2cpu_testtrigger_reg[4] == 0) ? 1'b1 : new_packet & !empty ? 1'b1 : bw_go;
		bw_delay <= #1 (ip2cpu_testtrigger_reg[0] == 0) | reset_registers | clear_counters ? ip2cpu_testtrigger_reg[31:8]<<10 : 
			       bw_go ? (bw_delay == 34'h0 ? 34'h0 : bw_delay-1) : ip2cpu_testtrigger_reg[31:8]<<10; 
		bw_tsdin <= #1 (bw_timer == ip2cpu_bwgranularity_reg) & (bytes_counter > 0) ? bw_ts_counter : bw_tsdin;
		bw_ts_counter <= #1 (ip2cpu_testtrigger_reg[0] == 0) | (bw_go==1'b0)| !(bw_delay==0) | reset_registers | clear_counters ? 32'h0 :  (bw_timer == ip2cpu_bwgranularity_reg) ? bw_ts_counter + 1: bw_ts_counter;
        end


//BW CDF statistics update
always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
		bw_cdf_we <= #1 1'b0;
		bw_cdf_addra <= #1 0;
		bw_cdf_addrb <= #1 0;
		bw_cdf_addrb2 <= #1 0;
		bw_cdf_addrb3 <= #1 0;
		bw_cdf_din   <= #1 0;
		bw_cdf_next_rd_reply <= #1 1'b0;
		bw_cdf_next_rd_reply2<= #1 1'b0;
		bw_cdf_next_rd_reply3<= #1 1'b0;
		
	end
	else begin
		bw_cdf_we <= #1 bw_cdf_next_rd_reply3;
		bw_cdf_addra <= #1 bw_cdf_addrb3;
		bw_cdf_addrb2 <= #1 bw_cdf_addrb;
		bw_cdf_addrb3 <= #1 bw_cdf_addrb2;
		bw_cdf_addrb <= #1 bw_go & (bw_delay==0) ?( (bytes_counter < 32'h400) ? bytes_counter : bytes_counter < 32'h100000 ? 13'h400+(bytes_counter>>10) : 
				bytes_counter < 32'h40000000 ? 13'h800+(bytes_counter>>20) : 13'h1FFF) :  bw_cdf_addrb; 
		bw_cdf_din   <= #1 bw_cdf_next_rd_reply3 ? bw_cdf_mem_dout +1 : bw_cdf_din;
		bw_cdf_next_rd_reply <= #1 bwcdfmem_cmd_valid & bwcdfmem_rd_wrn ? 1'b0 : bw_update;
		bw_cdf_next_rd_reply2 <= #1 bw_cdf_next_rd_reply;
		bw_cdf_next_rd_reply3 <= #1 bw_cdf_next_rd_reply2;
        end

//PPSs CDF statistics update
always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
		pps_cdf_we <= #1 1'b0;
		pps_cdf_addra <= #1 0;
		pps_cdf_addrb <= #1 0;
		pps_cdf_addrb2 <= #1 0;
		pps_cdf_addrb3 <= #1 0;
		pps_cdf_din   <= #1 0;
		pps_cdf_next_rd_reply <= #1 1'b0;
		pps_cdf_next_rd_reply2<= #1 1'b0;
		pps_cdf_next_rd_reply3<= #1 1'b0;
		
	end
	else begin
		pps_cdf_we <= #1 pps_cdf_next_rd_reply3;
		pps_cdf_addra <= #1 pps_cdf_addrb3;
		pps_cdf_addrb2 <= #1 pps_cdf_addrb; 
		pps_cdf_addrb3 <= #1 pps_cdf_addrb2;
		pps_cdf_addrb <= #1 bw_go & (bw_delay==0)? ((pps_counter < 32'h400) ? pps_counter : pps_counter < 32'h100000 ? 13'h400+(pps_counter>>10) : 
				pps_counter < 32'h40000000 ? 13'h800+(pps_counter>>20) : 13'h1FFF) :  pps_cdf_addrb; 
		pps_cdf_din   <= #1 pps_cdf_next_rd_reply3 ? pps_cdf_mem_dout +1 : pps_cdf_din;
		pps_cdf_next_rd_reply <= #1 ppscdfmem_cmd_valid & ppscdfmem_rd_wrn ? 1'b0 : bw_update ;
		pps_cdf_next_rd_reply2 <= #1 pps_cdf_next_rd_reply;
		pps_cdf_next_rd_reply3 <= #1 pps_cdf_next_rd_reply2;
        end

/////////////////////////////////////
//Window size statistics
/////////////////////////////////////

wire windowsize_mem_we;
wire [12:0] windowsize_mem_addra;
wire [12:0] windowsize_mem_addrb;
wire [31:0] windowsize_mem_din;
wire [31:0] windowsize_mem_dout;

reg windowsize_we;
reg [12:0] windowsize_addra;
reg [12:0] windowsize_addrb,windowsize_addrb2,windowsize_addrb3;
reg [31:0] windowsize_din;
wire [31:0] windowsize_dout;
reg windowsize_next_rd_reply,windowsize_next_rd_reply2,windowsize_next_rd_reply3;
reg windowsizemem_next_rd_reply,windowsizemem_next_rd_reply2;

 stats_mem windowsize_mem (
    .clka(axis_aclk),    // input wire clka
    .ena(axis_resetn),      // input wire ena
    .wea(windowsize_mem_we),      // input wire [0 : 0] wea
    .addra(windowsize_mem_addra),  // input wire [12 : 0] addra
    .dina(windowsize_mem_din),    // input wire [31 : 0] dina
    .clkb(axis_aclk),    // input wire clkb
    .enb(axis_resetn),      // input wire enb
    .addrb(windowsize_mem_addrb),  // input wire [12 : 0] addrb
    .doutb(windowsize_mem_dout)  // output wire [31 : 0] doutb
  ); 


assign windowsize_mem_we    = windowsizemem_cmd_valid & !windowsizemem_rd_wrn ? 1'b1 : windowsize_we;
assign windowsize_mem_addra = windowsizemem_cmd_valid & !windowsizemem_rd_wrn ? windowsizemem_addr : windowsize_addra;
assign windowsize_mem_din   = windowsizemem_cmd_valid & !windowsizemem_rd_wrn ? windowsizemem_data : windowsize_din;
assign windowsize_mem_addrb = windowsizemem_cmd_valid & windowsizemem_rd_wrn ? windowsizemem_addr : windowsize_addrb;

//indirect memory access read reply
always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
		windowsizemem_reply <= #1 0;
		windowsizemem_reply_valid	  <= #1 1'b0;
		windowsizemem_next_rd_reply  <= 1'b0;
		windowsizemem_next_rd_reply2 <= #1 1'b0;
	end
	else begin
		windowsizemem_next_rd_reply <= #1 windowsizemem_cmd_valid & windowsizemem_rd_wrn;
		windowsizemem_next_rd_reply2 <= #1 windowsizemem_next_rd_reply;
		windowsizemem_reply_valid <= #1 windowsizemem_next_rd_reply2;
		windowsizemem_reply <= #1 windowsizemem_next_rd_reply2 ? windowsize_mem_dout : windowsizemem_reply;
        end

//packet size statistics update
//note: this design currently does not support concurrent register access and packet count (will miss a packet)
always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
		windowsize_we <= #1 1'b0;
		windowsize_addra <= #1 0;
		windowsize_addrb <= #1 0;
		windowsize_addrb2 <= #1 0;
		windowsize_addrb3 <= #1 0;
		windowsize_din   <= #1 0;
		windowsize_next_rd_reply <= #1 1'b0;
		windowsize_next_rd_reply2 <= #1 1'b0;
		windowsize_next_rd_reply3 <= #1 1'b0;
	end
	else begin
		windowsize_we <= #1 windowsize_next_rd_reply3;
		windowsize_addra <= #1 windowsize_addrb3;
		windowsize_addrb <= #1 parser_valid & is_ip_pkt & is_tcp_pkt ? window_size [15:4] : windowsize_addrb; // note that window size is /16 for 4K enties
		windowsize_addrb2 <= #1 windowsize_addrb;
		windowsize_addrb3 <= #1 windowsize_addrb2;
		windowsize_din   <= #1 windowsize_next_rd_reply3 ? windowsize_mem_dout +1 : windowsize_din;
		windowsize_next_rd_reply <= #1 empty? 1'b0 : windowsizemem_cmd_valid & windowsizemem_rd_wrn ? 1'b0 : ip2cpu_testtrigger_reg[0] & parser_valid & is_ip_pkt & is_tcp_pkt;
		windowsize_next_rd_reply2 <= #1 windowsize_next_rd_reply;
		windowsize_next_rd_reply3 <= #1 windowsize_next_rd_reply2;
        end


/////////////////////////////////
//Registers section
/////////////////////////////////
 stats_cpu_regs
 #(
     .C_BASE_ADDRESS        (C_BASEADDR ),
     .C_S_AXI_DATA_WIDTH    (C_S_AXI_DATA_WIDTH),
     .C_S_AXI_ADDR_WIDTH    (C_S_AXI_ADDR_WIDTH)
 ) stats_cpu_regs_inst
 (  
   // General ports
    .clk                    (axis_aclk),
    .resetn                 (axis_resetn),
   // AXI Lite ports
    .S_AXI_ACLK             (S_AXI_ACLK),
    .S_AXI_ARESETN          (S_AXI_ARESETN),
    .S_AXI_AWADDR           (S_AXI_AWADDR),
    .S_AXI_AWVALID          (S_AXI_AWVALID),
    .S_AXI_WDATA            (S_AXI_WDATA),
    .S_AXI_WSTRB            (S_AXI_WSTRB),
    .S_AXI_WVALID           (S_AXI_WVALID),
    .S_AXI_BREADY           (S_AXI_BREADY),
    .S_AXI_ARADDR           (S_AXI_ARADDR),
    .S_AXI_ARVALID          (S_AXI_ARVALID),
    .S_AXI_RREADY           (S_AXI_RREADY),
    .S_AXI_ARREADY          (S_AXI_ARREADY),
    .S_AXI_RDATA            (S_AXI_RDATA),
    .S_AXI_RRESP            (S_AXI_RRESP),
    .S_AXI_RVALID           (S_AXI_RVALID),
    .S_AXI_WREADY           (S_AXI_WREADY),
    .S_AXI_BRESP            (S_AXI_BRESP),
    .S_AXI_BVALID           (S_AXI_BVALID),
    .S_AXI_AWREADY          (S_AXI_AWREADY),

   // Register ports
   .id_reg          (id_reg),
   .version_reg          (version_reg),
   .reset_reg          (reset_reg),
   .ip2cpu_flip_reg          (ip2cpu_flip_reg),
   .cpu2ip_flip_reg          (cpu2ip_flip_reg),
   .ip2cpu_debug_reg          (ip2cpu_debug_reg),
   .cpu2ip_debug_reg          (cpu2ip_debug_reg),
   .pktin_reg          (pktin_reg),
   .pktin_reg_clear    (pktin_reg_clear),
   .pktout_reg          (pktout_reg),
   .pktout_reg_clear    (pktout_reg_clear),
   .ip2cpu_testtrigger_reg          (ip2cpu_testtrigger_reg),
   .cpu2ip_testtrigger_reg          (cpu2ip_testtrigger_reg),
   .ip2cpu_bwgranularity_reg          (ip2cpu_bwgranularity_reg),
   .cpu2ip_bwgranularity_reg          (cpu2ip_bwgranularity_reg),
   .ip2cpu_bwdivisor_reg          (ip2cpu_bwdivisor_reg),
   .cpu2ip_bwdivisor_reg          (cpu2ip_bwdivisor_reg),
   .ip2cpu_burstgap_reg          (ip2cpu_burstgap_reg),
   .cpu2ip_burstgap_reg          (cpu2ip_burstgap_reg),
   .ip2cpu_testend_reg          (ip2cpu_testend_reg),
   .cpu2ip_testend_reg          (cpu2ip_testend_reg),
   .ip2cpu_firsttime_reg          (ip2cpu_firsttime_reg),
   .cpu2ip_firsttime_reg          (cpu2ip_firsttime_reg),
   .ip2cpu_lasttime_reg          (ip2cpu_lasttime_reg),
   .cpu2ip_lasttime_reg          (cpu2ip_lasttime_reg),
   .ip2cpu_lastbw_reg          (ip2cpu_lastbw_reg),
   .cpu2ip_lastbw_reg          (cpu2ip_lastbw_reg),
   .inputsel_reg          (inputsel_reg),
   .ip2cpu_arpcount_reg          (ip2cpu_arpcount_reg),
   .cpu2ip_arpcount_reg          (cpu2ip_arpcount_reg),
   .ip2cpu_ip4count_reg          (ip2cpu_ip4count_reg),
   .cpu2ip_ip4count_reg          (cpu2ip_ip4count_reg),
   .ip2cpu_ip6count_reg          (ip2cpu_ip6count_reg),
   .cpu2ip_ip6count_reg          (cpu2ip_ip6count_reg),
   .ip2cpu_tcpcount_reg          (ip2cpu_tcpcount_reg),
   .cpu2ip_tcpcount_reg          (cpu2ip_tcpcount_reg),
   .ip2cpu_udpcount_reg          (ip2cpu_udpcount_reg),
   .cpu2ip_udpcount_reg          (cpu2ip_udpcount_reg),
   .ip2cpu_syncount_reg          (ip2cpu_syncount_reg),
   .cpu2ip_syncount_reg          (cpu2ip_syncount_reg),
   .ip2cpu_fincount_reg          (ip2cpu_fincount_reg),
   .cpu2ip_fincount_reg          (cpu2ip_fincount_reg),
   .ip2cpu_flowidcount_reg          (ip2cpu_flowidcount_reg),
   .cpu2ip_flowidcount_reg          (cpu2ip_flowidcount_reg),
   .patternmatch1_reg          (patternmatch1_reg),
   .patternmatch2_reg          (patternmatch2_reg),
   .patternmatch3_reg          (patternmatch3_reg),
   .patternmatch4_reg          (patternmatch4_reg),
   .patternmatch5_reg          (patternmatch5_reg),
   .patternmatch6_reg          (patternmatch6_reg),
   .patternmatch7_reg          (patternmatch7_reg),
   .patternmatch8_reg          (patternmatch8_reg),
   .patternmatch9_reg          (patternmatch9_reg),
   .patternmatch10_reg          (patternmatch10_reg),
   .patternmatch11_reg          (patternmatch11_reg),
   .patternmatch12_reg          (patternmatch12_reg),
   .patternmatch13_reg          (patternmatch13_reg),
   .patternmatch14_reg          (patternmatch14_reg),
   .patternmatch15_reg          (patternmatch15_reg),
   .patternmatch16_reg          (patternmatch16_reg),
   .patternmask1_reg          (patternmask1_reg),
   .patternmask2_reg          (patternmask2_reg),
   .patternmask3_reg          (patternmask3_reg),
   .patternmask4_reg          (patternmask4_reg),
   .patternmask5_reg          (patternmask5_reg),
   .patternmask6_reg          (patternmask6_reg),
   .patternmask7_reg          (patternmask7_reg),
   .patternmask8_reg          (patternmask8_reg),
   .patternmask9_reg          (patternmask9_reg),
   .patternmask10_reg          (patternmask10_reg),
   .patternmask11_reg          (patternmask11_reg),
   .patternmask12_reg          (patternmask12_reg),
   .patternmask13_reg          (patternmask13_reg),
   .patternmask14_reg          (patternmask14_reg),
   .patternmask15_reg          (patternmask15_reg),
   .patternmask16_reg          (patternmask16_reg),
   .ip2cpu_matchcount_reg          (ip2cpu_matchcount_reg),
   .cpu2ip_matchcount_reg          (cpu2ip_matchcount_reg),
    .pktsizemem_addr          (pktsizemem_addr),
    .pktsizemem_data          (pktsizemem_data),
    .pktsizemem_rd_wrn        (pktsizemem_rd_wrn),
    .pktsizemem_cmd_valid     (pktsizemem_cmd_valid ),
    .pktsizemem_reply         (pktsizemem_reply),
    .pktsizemem_reply_valid   (pktsizemem_reply_valid),
    .ipgmem_addr          (ipgmem_addr),
    .ipgmem_data          (ipgmem_data),
    .ipgmem_rd_wrn        (ipgmem_rd_wrn),
    .ipgmem_cmd_valid     (ipgmem_cmd_valid ),
    .ipgmem_reply         (ipgmem_reply),
    .ipgmem_reply_valid   (ipgmem_reply_valid),
    .burstmem_addr          (burstmem_addr),
    .burstmem_data          (burstmem_data),
    .burstmem_rd_wrn        (burstmem_rd_wrn),
    .burstmem_cmd_valid     (burstmem_cmd_valid ),
    .burstmem_reply         (burstmem_reply),
    .burstmem_reply_valid   (burstmem_reply_valid),
    .bwmem_addr          (bwmem_addr),
    .bwmem_data          (bwmem_data),
    .bwmem_rd_wrn        (bwmem_rd_wrn),
    .bwmem_cmd_valid     (bwmem_cmd_valid ),
    .bwmem_reply         (bwmem_reply),
    .bwmem_reply_valid   (bwmem_reply_valid),
    .bwtsmem_addr          (bwtsmem_addr),
    .bwtsmem_data          (bwtsmem_data),
    .bwtsmem_rd_wrn        (bwtsmem_rd_wrn),
    .bwtsmem_cmd_valid     (bwtsmem_cmd_valid ),
    .bwtsmem_reply         (bwtsmem_reply),
    .bwtsmem_reply_valid   (bwtsmem_reply_valid),
    .ppsmem_addr          (ppsmem_addr),
    .ppsmem_data          (ppsmem_data),
    .ppsmem_rd_wrn        (ppsmem_rd_wrn),
    .ppsmem_cmd_valid     (ppsmem_cmd_valid ),
    .ppsmem_reply         (ppsmem_reply),
    .ppsmem_reply_valid   (ppsmem_reply_valid),
   .bwcdfmem_addr          (bwcdfmem_addr),
    .bwcdfmem_data          (bwcdfmem_data),
    .bwcdfmem_rd_wrn        (bwcdfmem_rd_wrn),
    .bwcdfmem_cmd_valid     (bwcdfmem_cmd_valid ),
    .bwcdfmem_reply         (bwcdfmem_reply),
    .bwcdfmem_reply_valid   (bwcdfmem_reply_valid),
    .ppscdfmem_addr          (ppscdfmem_addr),
    .ppscdfmem_data          (ppscdfmem_data),
    .ppscdfmem_rd_wrn        (ppscdfmem_rd_wrn),
    .ppscdfmem_cmd_valid     (ppscdfmem_cmd_valid ),
    .ppscdfmem_reply         (ppscdfmem_reply),
    .ppscdfmem_reply_valid   (ppscdfmem_reply_valid),
    .flowidmem_addr          (flowidmem_addr),
    .flowidmem_data          (flowidmem_data),
    .flowidmem_rd_wrn        (flowidmem_rd_wrn),
    .flowidmem_cmd_valid     (flowidmem_cmd_valid ),
    .flowidmem_reply         (flowidmem_reply),
    .flowidmem_reply_valid   (flowidmem_reply_valid),
    .windowsizemem_addr          (windowsizemem_addr),
    .windowsizemem_data          (windowsizemem_data),
    .windowsizemem_rd_wrn        (windowsizemem_rd_wrn),
    .windowsizemem_cmd_valid     (windowsizemem_cmd_valid ),
    .windowsizemem_reply         (windowsizemem_reply),
    .windowsizemem_reply_valid   (windowsizemem_reply_valid),

   // Global Registers - user can select if to use
   .cpu_resetn_soft(),//software reset, after cpu module
   .resetn_soft    (),//software reset to cpu module (from central reset management)
   .resetn_sync    (resetn_sync)//synchronized reset, use for better timing
);

assign clear_counters = reset_reg[0];
assign reset_registers = reset_reg[4];



always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
id_reg <= #1    `REG_ID_DEFAULT;
        version_reg <= #1    `REG_VERSION_DEFAULT;
        ip2cpu_flip_reg <= #1    `REG_FLIP_DEFAULT;
        ip2cpu_debug_reg <= #1    `REG_DEBUG_DEFAULT;
        pktin_reg <= #1    `REG_PKTIN_DEFAULT;
        pktout_reg <= #1    `REG_PKTOUT_DEFAULT;
        ip2cpu_testtrigger_reg <= #1    `REG_TESTTRIGGER_DEFAULT;
        ip2cpu_bwgranularity_reg <= #1    `REG_BWGRANULARITY_DEFAULT;
        ip2cpu_burstgap_reg <= #1    `REG_BURSTGAP_DEFAULT;
        ip2cpu_bwdivisor_reg <= #1    `REG_BWDIVISOR_DEFAULT;
        ip2cpu_testend_reg <= #1    `REG_TESTEND_DEFAULT;
        ip2cpu_firsttime_reg <= #1    `REG_FIRSTTIME_DEFAULT;
        ip2cpu_lasttime_reg <= #1    `REG_LASTTIME_DEFAULT;
        ip2cpu_lastbw_reg <= #1    `REG_LASTBW_DEFAULT;
       ip2cpu_arpcount_reg <= #1    `REG_ARPCOUNT_DEFAULT;
        ip2cpu_ip4count_reg <= #1    `REG_IP4COUNT_DEFAULT;
        ip2cpu_ip6count_reg <= #1    `REG_IP6COUNT_DEFAULT;
        ip2cpu_tcpcount_reg <= #1    `REG_TCPCOUNT_DEFAULT;
        ip2cpu_udpcount_reg <= #1    `REG_UDPCOUNT_DEFAULT;
        ip2cpu_syncount_reg <= #1    `REG_SYNCOUNT_DEFAULT;
        ip2cpu_fincount_reg <= #1    `REG_FINCOUNT_DEFAULT;
        ip2cpu_flowidcount_reg <= #1    `REG_FLOWIDCOUNT_DEFAULT;
        ip2cpu_matchcount_reg <= #1    `REG_MATCHCOUNT_DEFAULT;
	end
	else begin
		id_reg <= #1    `REG_ID_DEFAULT;
		version_reg <= #1    `REG_VERSION_DEFAULT;
		ip2cpu_flip_reg <= #1    ~cpu2ip_flip_reg;
		pktin_reg[`REG_PKTIN_WIDTH -2: 0] <= #1  clear_counters | pktin_reg_clear ? 'h0  : pktin_reg[`REG_PKTIN_WIDTH-2:0] + (s_axis_tlast && s_axis_tvalid && s_axis_tready )  ;
                pktin_reg[`REG_PKTIN_WIDTH-1] <= #1 clear_counters | pktin_reg_clear ? 1'h0 : (pktin_reg[`REG_PKTIN_WIDTH-2:0] + (s_axis_tlast && s_axis_tvalid && s_axis_tready ))  > {(`REG_PKTIN_WIDTH-1){1'b1}} ? 1'b1 : pktin_reg[`REG_PKTIN_WIDTH-1];
                                                               
                ip2cpu_debug_reg[15:0] <= #1 clear_counters  ? 16'h0 : parser_valid ? window_size : ip2cpu_debug_reg[15:0];
		ip2cpu_debug_reg[31:16] <= #1 clear_counters  ? 16'h0 : !empty ? fifo_tdata [143:128] : ip2cpu_debug_reg[31:16] ;
	        ip2cpu_testtrigger_reg <= #1    cpu2ip_testtrigger_reg;
                ip2cpu_bwgranularity_reg <= #1    cpu2ip_bwgranularity_reg;
		ip2cpu_bwdivisor_reg <= #1 cpu2ip_bwdivisor_reg;
	        ip2cpu_burstgap_reg <= #1 cpu2ip_burstgap_reg;
                ip2cpu_testend_reg <= #1  clear_counters ? 32'h0 : cpu2ip_testtrigger_reg & !ip2cpu_testtrigger_reg[0] ? 32'h0 : 
					  ip2cpu_testtrigger_reg[0] ? ip2cpu_testend_reg+1 : ip2cpu_testend_reg  ;
                ip2cpu_firsttime_reg <= #1 clear_counters ? 32'h0 : cpu2ip_testtrigger_reg & !ip2cpu_testtrigger_reg[0] ? 32'h0 :
					   (ip2cpu_firsttime_reg==0) & new_packet & !empty ? ip2cpu_testend_reg : ip2cpu_firsttime_reg ; 
                ip2cpu_lasttime_reg <= #1  clear_counters ? 32'h0 : cpu2ip_testtrigger_reg & !ip2cpu_testtrigger_reg[0] ? 32'h0 :
				           new_packet & !empty ? ip2cpu_testend_reg : ip2cpu_lasttime_reg ;  ;
                 ip2cpu_lastbw_reg[12:0] <= #1    bw_addra;
		ip2cpu_arpcount_reg <= #1 clear_counters ? 32'h0 : cpu2ip_testtrigger_reg & !ip2cpu_testtrigger_reg[0] ? 32'h0 :
                                          ip2cpu_arpcount_reg==32'hFFFFFFFF ? ip2cpu_arpcount_reg : is_arp_pkt & parser_valid ? ip2cpu_arpcount_reg+1 : ip2cpu_arpcount_reg;
		ip2cpu_ip4count_reg <= #1 clear_counters ? 32'h0 : cpu2ip_testtrigger_reg & !ip2cpu_testtrigger_reg[0] ? 32'h0 :
                                          ip2cpu_ip4count_reg==32'hFFFFFFFF ? ip2cpu_ip4count_reg : is_ip_pkt & parser_valid ? ip2cpu_ip4count_reg+1 : ip2cpu_ip4count_reg;
		ip2cpu_ip6count_reg <= #1 clear_counters ? 32'h0 : cpu2ip_testtrigger_reg & !ip2cpu_testtrigger_reg[0] ? 32'h0 :
                                          ip2cpu_ip6count_reg==32'hFFFFFFFF ? ip2cpu_ip6count_reg : is_ip6_pkt & parser_valid ? ip2cpu_ip6count_reg+1 : ip2cpu_ip6count_reg;
		ip2cpu_tcpcount_reg <= #1 clear_counters ? 32'h0 : cpu2ip_testtrigger_reg & !ip2cpu_testtrigger_reg[0] ? 32'h0 :
                                          ip2cpu_tcpcount_reg==32'hFFFFFFFF ? ip2cpu_tcpcount_reg : is_tcp_pkt & parser_valid ? ip2cpu_tcpcount_reg+1 : ip2cpu_tcpcount_reg;
		ip2cpu_udpcount_reg <= #1 clear_counters ? 32'h0 : cpu2ip_testtrigger_reg & !ip2cpu_testtrigger_reg[0] ? 32'h0 :
                                          ip2cpu_udpcount_reg==32'hFFFFFFFF ? ip2cpu_udpcount_reg : is_udp_pkt & parser_valid ? ip2cpu_udpcount_reg+1 : ip2cpu_udpcount_reg;
		ip2cpu_syncount_reg <= #1 clear_counters ? 32'h0 : cpu2ip_testtrigger_reg & !ip2cpu_testtrigger_reg[0] ? 32'h0 :
                                          ip2cpu_syncount_reg==32'hFFFFFFFF ? ip2cpu_syncount_reg : is_syn & parser_valid ? ip2cpu_syncount_reg+1 : ip2cpu_syncount_reg;
		ip2cpu_fincount_reg <= #1 clear_counters ? 32'h0 : cpu2ip_testtrigger_reg & !ip2cpu_testtrigger_reg[0] ? 32'h0 :
                                          ip2cpu_fincount_reg==32'hFFFFFFFF ? ip2cpu_fincount_reg : is_fin & parser_valid ? ip2cpu_fincount_reg+1 : ip2cpu_fincount_reg;
		ip2cpu_flowidcount_reg <= #1 cpu2ip_flowidcount_reg;
		ip2cpu_matchcount_reg <= #1 cpu2ip_matchcount_reg;

        end



endmodule
