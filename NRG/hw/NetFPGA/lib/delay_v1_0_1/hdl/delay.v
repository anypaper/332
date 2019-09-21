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
 *        delay.v
 *
 *  Library:
 *        hw/std/cores/delay_v1_0_0
 *
 *  Module:
 *        delay
 *
 *  Author:
 * 		
 *  Description:
 *        Additive delay module
 *
 */

`timescale 1ns/1ps
`include "delay_cpu_regs_defines.v"

module delay
#(
    //Master AXI Stream Data Width
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
    // Global Ports
    input axis_aclk,
    input axis_resetn,

    // Master Stream Ports (interface to data path)
    output [C_M_AXIS_DATA_WIDTH - 1:0] m_axis_tdata,
    output [((C_M_AXIS_DATA_WIDTH / 8)) - 1:0] m_axis_tkeep,
    output [C_M_AXIS_TUSER_WIDTH-1:0] m_axis_tuser,
    output m_axis_tvalid,
    input  m_axis_tready,
    output m_axis_tlast,

    // Slave Stream Ports (interface to RX queues)
    input [C_S_AXIS_DATA_WIDTH - 1:0] s_axis_tdata,
    input [((C_S_AXIS_DATA_WIDTH / 8)) - 1:0] s_axis_tkeep,
    input [C_S_AXIS_TUSER_WIDTH-1:0] s_axis_tuser,
    input  s_axis_tvalid,
    output s_axis_tready,
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

   reg      [`REG_ID_BITS]    id_reg;
   reg      [`REG_VERSION_BITS]    version_reg;
   wire     [`REG_RESET_BITS]    reset_reg;
   reg      [`REG_FLIP_BITS]    ip2cpu_flip_reg;
   wire     [`REG_FLIP_BITS]    cpu2ip_flip_reg;
   reg      [`REG_PKTIN_BITS]    pktin_reg;
   wire                             pktin_reg_clear;
   reg      [`REG_PKTOUT_BITS]    pktout_reg;
   wire                             pktout_reg_clear;
   reg      [`REG_DEBUG_BITS]    ip2cpu_debug_reg;
   wire     [`REG_DEBUG_BITS]    cpu2ip_debug_reg; 
   wire     [`REG_DELAYVAL_BITS] delayval_reg;
   wire     [`REG_JITTERVAL_BITS]    jitterval_reg;
   wire     [`REG_JITTERTYPE_BITS]    jittertype_reg;
    wire      [`MEM_DISTMEM_ADDR_BITS]    distmem_addr;
    wire      [`MEM_DISTMEM_DATA_BITS]    distmem_data;
    wire                              distmem_rd_wrn;
    wire                              distmem_cmd_valid;
    reg       [`MEM_DISTMEM_DATA_BITS]    distmem_reply;
    reg                               distmem_reply_valid;
    wire      [`MEM_USERDISTMEM_ADDR_BITS]    userdistmem_addr;
    wire      [`MEM_USERDISTMEM_DATA_BITS]    userdistmem_data;
    wire                              userdistmem_rd_wrn;
    wire                              userdistmem_cmd_valid;
    reg       [`MEM_USERDISTMEM_DATA_BITS]    userdistmem_reply;
    reg                               userdistmem_reply_valid;


   reg      [32:0] time_counter;
   wire     [31:0] fifo_time;
   reg      time_expired;
   reg      [31:0] delay_val_next;
   wire     [31:0] prbs_next;
   reg      [31:0] prbs_current;
   reg      [30:0] uniform_jitter;
   reg      [30:0] normal_jitter;
   reg      [30:0] pareto_jitter;
   reg      [30:0] paretonormal_jitter;
   reg      [30:0] user_jitter;
   wire [15:0] normal_dout;
   wire [15:0] pareto_dout;
   wire [15:0] paretonormal_dout;

   reg new_packet;
    
  
   wire clear_counters;
   wire reset_registers;
   wire [15:0] fifo_data_count;

   wire in_fifo_nearly_full,in_fifo_empty;
   wire   in_fifo_rd_en;

   wire [11:0] ram_entry;
   assign ram_entry = prbs_current [11:0];

  always @(posedge axis_aclk)
	if (~resetn_sync) begin
		new_packet <= #1 1'b1;
	end
	else begin
		new_packet <= #1 !in_fifo_empty & m_axis_tlast ? 1'b1: in_fifo_empty ? new_packet : 1'b0;
        end


   function integer log2;
      input integer number;
      begin
         log2=0;
         while(2**log2<number) begin
            log2=log2+1;
         end
      end
   endfunction // log2

   delay_fifo
     //   #( .WIDTH(C_M_AXIS_DATA_WIDTH+C_M_AXIS_TUSER_WIDTH+C_M_AXIS_DATA_WIDTH/8+32+1),
     //      .MAX_DEPTH_BITS(2))
      delay_fifo
        (// Outputs
         .dout                           ({fifo_time,m_axis_tlast, m_axis_tuser, m_axis_tkeep, m_axis_tdata}),
         .full                           (),

         .almost_full                    (in_fifo_nearly_full),
         .empty                          (in_fifo_empty),
         // Inputs
         .din                            ({time_counter[31:0],s_axis_tlast, s_axis_tuser, s_axis_tkeep, s_axis_tdata}),
         .wr_en                          (s_axis_tvalid & ~in_fifo_nearly_full),
         .rd_en                          (in_fifo_rd_en),
	 .data_count			(fifo_data_count),
	 .srst                          (~axis_resetn),
	 .clk                            (axis_aclk));

    assign s_axis_tready = !in_fifo_nearly_full;

  // Handle output
   assign in_fifo_rd_en = m_axis_tready && !in_fifo_empty && time_expired;
   assign m_axis_tvalid = !in_fifo_empty && time_expired;

normal_dist_mem normal_dist (
  .clka(axis_aclk),    // input wire clka
  .rsta(~axis_resetn),    // input wire rsta
  .wea(1'b0),      // input wire [0 : 0] wea
  .addra(ram_entry),  // input wire [11 : 0] addra
  .dina(16'h0),    // input wire [15 : 0] dina
  .douta(normal_dout)  // output wire [15 : 0] douta
);

pareto_dist_mem pareto_dist (
  .clka(axis_aclk),    // input wire clka
  .rsta(~axis_resetn),    // input wire rsta
  .wea(1'b0),      // input wire [0 : 0] wea
  .addra(ram_entry),  // input wire [11 : 0] addra
  .dina(16'h0),    // input wire [15 : 0] dina
  .douta(pareto_dout)  // output wire [15 : 0] douta
);

paretonormal_dist_mem paretonormal_dist (
  .clka(axis_aclk),    // input wire clka
  .rsta(~axis_resetn),    // input wire rsta
  .wea(1'b0),      // input wire [0 : 0] wea
  .addra(ram_entry),  // input wire [11 : 0] addra
  .dina(16'h0),    // input wire [15 : 0] dina
  .douta(paretonormal_dout)  // output wire [15 : 0] douta
);

//User defined distribution
   wire [15:0] user_dist_dout;
   wire [15:0] user_dist_din;
   wire        user_dist_we;
   wire [11:0] user_dist_addra;

   reg user_dist_next_rd_reply;
   reg userdistmem_next_rd_reply, userdistmem_next_rd_reply2;

user_dist_mem user_dist (
  .clka(axis_aclk),    // input wire clka
  .rsta(~axis_resetn),    // input wire rsta
  .wea(user_dist_we),      // input wire [0 : 0] wea
  .addra(user_dist_addra),  // input wire [11 : 0] addra
  .dina(user_dist_din),    // input wire [15 : 0] dina
  .douta(user_dist_dout)  // output wire [15 : 0] douta
);


assign user_dist_we    = userdistmem_cmd_valid ? !userdistmem_rd_wrn : 1'b0;
assign user_dist_din   = userdistmem_cmd_valid & !userdistmem_rd_wrn ? userdistmem_data : 16'h0;
assign user_dist_addra = userdistmem_cmd_valid ? userdistmem_addr : ram_entry;

//indirect memory access read reply
always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
		userdistmem_reply <= #1 0;
		userdistmem_reply_valid	  <= #1 1'b0;
		userdistmem_next_rd_reply  <= 1'b0;
		userdistmem_next_rd_reply2 <= #1 1'b0;
	end
	else begin
		userdistmem_next_rd_reply <= #1 userdistmem_cmd_valid & userdistmem_rd_wrn;
		userdistmem_next_rd_reply2 <= #1 userdistmem_next_rd_reply;
		userdistmem_reply_valid <= #1 userdistmem_next_rd_reply2;
		userdistmem_reply <= #1 userdistmem_next_rd_reply2 ? user_dist_dout : userdistmem_reply;
        end


//End of user defined distribution

prbs random_gen(
	   .do (prbs_next),
	   .clk (axis_aclk),
	   .advance(in_fifo_rd_en & new_packet),
	   .rstn (axis_resetn)
	   );

/////////////////////////////////////
//Distribution statistics
/////////////////////////////////////

wire dist_mem_we;
wire [15:0] dist_mem_addra;
wire [31:0] dist_mem_din;
wire [31:0] dist_mem_dout;

reg dist_we;
reg [15:0] dist_addra;
reg [31:0] dist_din;
wire [31:0] dist_dout;
reg dist_next_rd_reply;
reg distmem_next_rd_reply,distmem_next_rd_reply2;

dist_log_mem dist_log (
  .clka(axis_aclk),    // input wire clka
  .rsta(~axis_resetn),    // input wire rsta
  .ena(axis_resetn),      // input wire ena
  .wea(dist_mem_we),      // input wire [0 : 0] wea
  .addra(dist_mem_addra),  // input wire [15 : 0] addra
  .dina(dist_mem_din),    // input wire [31 : 0] dina
  .douta(dist_mem_dout)  // output wire [31 : 0] douta
);




assign dist_mem_we    = distmem_cmd_valid ? !distmem_rd_wrn : dist_we;
assign dist_mem_addra = distmem_cmd_valid ? distmem_addr : dist_addra;
assign dist_mem_din   = distmem_cmd_valid & !distmem_rd_wrn ? distmem_data : dist_din;

//indirect memory access read reply
always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
		distmem_reply <= #1 0;
		distmem_reply_valid	  <= #1 1'b0;
		distmem_next_rd_reply  <= 1'b0;
		distmem_next_rd_reply2 <= #1 1'b0;
	end
	else begin
		distmem_next_rd_reply <= #1 distmem_cmd_valid & distmem_rd_wrn;
		distmem_next_rd_reply2 <= #1 distmem_next_rd_reply;
		distmem_reply_valid <= #1 distmem_next_rd_reply2;
		distmem_reply <= #1 distmem_next_rd_reply2 ? dist_mem_dout : distmem_reply;
        end

//latency distibution log
//note: this design currently does not support concurrent register access and memory log (will miss an entry)
always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
		dist_we <= #1 1'b0;
		dist_addra <= #1 0;
		dist_din   <= #1 0;
		dist_next_rd_reply <= #1 1'b0;

	end
	else begin
		dist_we <= #1 new_packet & in_fifo_rd_en;
		dist_addra <= #1 reset_registers | clear_counters ? 16'h0 :  dist_addra == 16'hFFFF ? dist_addra : dist_we ? dist_addra+1 : dist_addra ;
		dist_din   <= #1  delay_val_next;
		dist_next_rd_reply <= #1 1'h0; 
		
        end


//Registers section
 delay_cpu_regs 
 #(
   .C_BASE_ADDRESS        (C_BASEADDR),
   .C_S_AXI_DATA_WIDTH (C_S_AXI_DATA_WIDTH),
   .C_S_AXI_ADDR_WIDTH (C_S_AXI_ADDR_WIDTH)
 ) opl_cpu_regs_inst
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
   .pktin_reg          (pktin_reg),
   .pktin_reg_clear    (pktin_reg_clear),
   .pktout_reg          (pktout_reg),
   .pktout_reg_clear    (pktout_reg_clear),
   .ip2cpu_debug_reg          (ip2cpu_debug_reg),
   .cpu2ip_debug_reg          (cpu2ip_debug_reg),
   .delayval_reg              (delayval_reg),
   .jitterval_reg          (jitterval_reg),
   .jittertype_reg          (jittertype_reg),
   .distmem_addr          (distmem_addr),
    .distmem_data          (distmem_data),
    .distmem_rd_wrn        (distmem_rd_wrn),
    .distmem_cmd_valid     (distmem_cmd_valid ),
    .distmem_reply         (distmem_reply),
    .distmem_reply_valid   (distmem_reply_valid),
    .userdistmem_addr          (userdistmem_addr),
    .userdistmem_data          (userdistmem_data),
    .userdistmem_rd_wrn        (userdistmem_rd_wrn),
    .userdistmem_cmd_valid     (userdistmem_cmd_valid ),
    .userdistmem_reply         (userdistmem_reply),
    .userdistmem_reply_valid   (userdistmem_reply_valid),

   // Global Registers - user can select if to use
   .cpu_resetn_soft(),//software reset, after cpu module
   .resetn_soft    (),//software reset to cpu module (from central reset management)
   .resetn_sync    (resetn_sync)//synchronized reset, use for better timing
);

   assign clear_counters = reset_reg[0];
   assign reset_registers = reset_reg[4];

//a counter used to measure time
always @(posedge axis_aclk)
	if (~resetn_sync | clear_counters) begin
		time_counter <= #1 32'h0;
	end
	else begin
		time_counter <= #1 (time_counter==33'hFFFFFFFF) ? 33'h0 : time_counter+33'h1;
	end
	


////registers logic, current logic is just a placeholder for initial compil, required to be changed by the user
always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
		id_reg <= #1    `REG_ID_DEFAULT;
		version_reg <= #1    `REG_VERSION_DEFAULT;
		ip2cpu_flip_reg <= #1    `REG_FLIP_DEFAULT;
		pktin_reg <= #1    `REG_PKTIN_DEFAULT;
		pktout_reg <= #1    `REG_PKTOUT_DEFAULT;
		ip2cpu_debug_reg <= #1    `REG_DEBUG_DEFAULT;
	end
	else begin
		id_reg <= #1    `REG_ID_DEFAULT;
		version_reg <= #1    `REG_VERSION_DEFAULT;
		ip2cpu_flip_reg <= #1    ~cpu2ip_flip_reg;
		pktin_reg[`REG_PKTIN_WIDTH -2: 0] <= #1  clear_counters | pktin_reg_clear ? 'h0  : pktin_reg[`REG_PKTIN_WIDTH-2:0] + (s_axis_tlast && s_axis_tvalid && s_axis_tready) ;
                pktin_reg[`REG_PKTIN_WIDTH-1] <= #1 clear_counters | pktin_reg_clear ? 1'h0 : pktin_reg_clear ? 'h0  : pktin_reg[`REG_PKTIN_WIDTH-2:0] + (s_axis_tlast && s_axis_tvalid && s_axis_tready) 
                                                     > {(`REG_PKTIN_WIDTH-1){1'b1}} ? 1'b1 : pktin_reg[`REG_PKTIN_WIDTH-1];
                                                               
		pktout_reg [`REG_PKTOUT_WIDTH-2:0]<= #1  clear_counters | pktout_reg_clear ? 'h0  : pktout_reg [`REG_PKTOUT_WIDTH-2:0] + (m_axis_tlast && m_axis_tvalid && m_axis_tready) ;
                pktout_reg [`REG_PKTOUT_WIDTH-1]<= #1  clear_counters | pktout_reg_clear ? 'h0  : pktout_reg [`REG_PKTOUT_WIDTH-2:0] + (m_axis_tlast && m_axis_tvalid && m_axis_tready)  > {(`REG_PKTOUT_WIDTH-1){1'b1}} ?
                                                                1'b1 : pktout_reg [`REG_PKTOUT_WIDTH-1];
/*		ip2cpu_debug_reg [31:16]<= #1    fifo_data_count;
                ip2cpu_debug_reg [0]<= #1     m_axis_tvalid;
		ip2cpu_debug_reg [1]<= #1     !in_fifo_empty;
		ip2cpu_debug_reg [2]<= #1     time_expired;
		ip2cpu_debug_reg [3]<= #1     m_axis_tready;
		ip2cpu_debug_reg [4]<= #1     in_fifo_rd_en;
                ip2cpu_debug_reg [5]<= #1     in_fifo_nearly_full ? 1'b1 : reset_reg[8] ? 1'b0 : ip2cpu_debug_reg [5];
                ip2cpu_debug_reg [6]<= #1      |(delayval_reg);
                ip2cpu_debug_reg [15:8]<= #1   {time_counter[31:28],time_counter[3:0]};
*/
		ip2cpu_debug_reg [0] <= #1 clear_counters ? 1'b0 : in_fifo_nearly_full & !in_fifo_empty ? 1'b1 : ip2cpu_debug_reg[0]; //did the fifo reach nearly full?
		ip2cpu_debug_reg[3:1] <= #1 3'h0;
		ip2cpu_debug_reg [15:4] <= #1 clear_counters ? 12'h0 : ip2cpu_debug_reg[15:4]==12'hFFF ? 12'hFFF : in_fifo_nearly_full & !in_fifo_empty ? ip2cpu_debug_reg[15:4]+1'b1 : ip2cpu_debug_reg[15:4]; //how many times reached nearly full?
		ip2cpu_debug_reg [31:16] <= #1 clear_counters ? 16'h0 : in_fifo_empty ? ip2cpu_debug_reg[31:16] : fifo_data_count>ip2cpu_debug_reg [31:16] ? fifo_data_count : ip2cpu_debug_reg[31:16]; //data count watermark
        end

//Expired time logic
always @(posedge axis_aclk)
	if (~resetn_sync | reset_registers) begin
	   time_expired <= #1 1'b1;
   	   delay_val_next <= #1 32'b0;
	   prbs_current <= #1 32'h0;
	   uniform_jitter <= #1 31'h0;
	   normal_jitter <= #1 31'h0;
	   pareto_jitter <= #1 31'h0;
	   paretonormal_jitter <= #1 31'h0;
           user_jitter   <= #1 31'h0;
	end
	else begin
           time_expired <= #1 ((time_counter+33'h1) > (fifo_time+delay_val_next+33'h0))  ||
                             ((fifo_time > (time_counter+33'h1)) && ((time_counter + 33'h100000001) > (fifo_time+delay_val_next+33'h0))) ? 
                             1'b1 : 1'b0;
	   delay_val_next <= #1 jittertype_reg == 32'h0 ? delayval_reg :
				jittertype_reg == 32'h1 ? delayval_reg + uniform_jitter:
         			jittertype_reg == 32'h2 ? delayval_reg + normal_jitter :
				jittertype_reg == 32'h4 ? delayval_reg + pareto_jitter :
				jittertype_reg == 32'h8 ? delayval_reg + paretonormal_jitter :
				jittertype_reg == 32'h10 ? delayval_reg + user_jitter :
				delayval_reg;
	   prbs_current <= #1 in_fifo_rd_en & new_packet ? prbs_next : prbs_current;
           uniform_jitter <= #1 jitterval_reg < 32'd12 ? ram_entry>>(12-jitterval_reg) :
                                jitterval_reg == 32'd12 ? ram_entry :
                                ram_entry<< (jitterval_reg-12);
           normal_jitter  <= #1 jitterval_reg < 32'd16  ? normal_dout>>(16-jitterval_reg) :
                                jitterval_reg == 32'd16 ? normal_dout :
                                 normal_dout<< (jitterval_reg-16);
           pareto_jitter  <= #1 jitterval_reg < 32'd16  ? pareto_dout>>(16-jitterval_reg) :
                                jitterval_reg == 32'd16 ? pareto_dout :
                                 pareto_dout<< (jitterval_reg-16);
           paretonormal_jitter  <= #1 jitterval_reg < 32'd16  ? paretonormal_dout>>(16-jitterval_reg) :
                                jitterval_reg == 32'd16 ? paretonormal_dout :
                                 paretonormal_dout<< (jitterval_reg-16);
           user_jitter    <= #1 jitterval_reg < 32'd16  ? user_dist_dout>>(16-jitterval_reg) :
                                jitterval_reg == 32'd16 ? user_dist_dout :
                                user_dist_dout<< (jitterval_reg-16);

	end
 
endmodule // delay
