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


    // Slave Stream Ports (interface to RX queues)
    input [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_tuser,
    input  s_axis_tvalid,
    input s_axis_tready,
    input  s_axis_tlast,

   
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
    reg      [`REG_BURSTGAP_BITS]    ip2cpu_burstgap_reg;
    wire     [`REG_BURSTGAP_BITS]    cpu2ip_burstgap_reg;
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
   wire clear_counters;
   wire reset_registers;

    reg new_packet;

     
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
         .wr_en                          (s_axis_tvalid & ~nearly_full),
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
		pktsize_next_rd_reply <= #1 empty? 1'b0 : pktsizemem_cmd_valid & pktsizemem_rd_wrn ? 1'b0 : ip2cpu_testtrigger_reg & new_packet;
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
		ipg_counter <= #1 (!ip2cpu_testtrigger_reg) | (new_packet & !empty) ? 32'h0 : (ipg_counter==32'hFFFFFFFF) ? ipg_counter : ipg_counter+1;
		ipg_we <= #1 ipg_next_rd_reply3;
		ipg_addra <= #1 ipg_addrb3;
		ipg_addrb2 <= #1 ipg_addrb;
		ipg_addrb3 <= #1 ipg_addrb2;
		ipg_addrb <= #1 new_packet & !empty? (ipg_counter < 32'h400 ? ipg_counter : ipg_counter < 32'h100000 ? 13'h400+(ipg_counter>>10) : 
				ipg_counter < 32'h40000000 ? 13'h800+(ipg_counter>>20) : 13'h1FFF) 
		 	       : ipg_addrb; // fix: new packet (last was tlast)
		ipg_din   <= #1 ipg_next_rd_reply3 ? ipg_mem_dout +1 : ipg_din;
		ipg_next_rd_reply <= #1 empty? 1'b0 : ipgmem_cmd_valid & ipgmem_rd_wrn ? 1'b0 : ip2cpu_testtrigger_reg & new_packet;
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
		burst_counter <= #1 (!ip2cpu_testtrigger_reg) ? 32'h1 :
				    (new_packet & !empty) ?
                                       ((ipg_counter<cpu2ip_burstgap_reg) ? ((burst_counter==32'hFFFFFFFF) ? burst_counter : burst_counter+1) : 32'h1) :
				     burst_counter;
                burst_counter_prev <= #1 (!ip2cpu_testtrigger_reg) ? 32'h1:
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
   .ip2cpu_burstgap_reg          (ip2cpu_burstgap_reg),
   .cpu2ip_burstgap_reg          (cpu2ip_burstgap_reg),
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
	end
	else begin
		id_reg <= #1    `REG_ID_DEFAULT;
		version_reg <= #1    `REG_VERSION_DEFAULT;
		ip2cpu_flip_reg <= #1    ~cpu2ip_flip_reg;
		pktin_reg[`REG_PKTIN_WIDTH -2: 0] <= #1  clear_counters | pktin_reg_clear ? 'h0  : pktin_reg[`REG_PKTIN_WIDTH-2:0] + (s_axis_tlast && s_axis_tvalid && s_axis_tready )  ;
                pktin_reg[`REG_PKTIN_WIDTH-1] <= #1 clear_counters | pktin_reg_clear ? 1'h0 : (pktin_reg[`REG_PKTIN_WIDTH-2:0] + (s_axis_tlast && s_axis_tvalid && s_axis_tready ))  > {(`REG_PKTIN_WIDTH-1){1'b1}} ? 1'b1 : pktin_reg[`REG_PKTIN_WIDTH-1];
                                                               
                ip2cpu_debug_reg[28:16] <= #1 ipg_addra;
	        ip2cpu_debug_reg[12:0]  <= #1 pktsize_addra;
	        ip2cpu_testtrigger_reg <= #1    1'b1; //cpu2ip_testtrigger_reg;
                ip2cpu_bwgranularity_reg <= #1    cpu2ip_bwgranularity_reg;
	        ip2cpu_burstgap_reg <= #1 cpu2ip_burstgap_reg;
        end



endmodule
