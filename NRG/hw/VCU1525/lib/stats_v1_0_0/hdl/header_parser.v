/*******************************************************************************
*
* Copyright (C) 2016 
* All rights reserved.
*
* Adapted from eth_parser, written by Giann Antichi, Muhammad Shahbaz and Stanford
*
*
* @NETFPGA_LICENSE_HEADER_START@
*
* Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
* license agreements. See the NOTICE file distributed with this work for
* additional information regarding copyright ownership. NetFPGA licenses this
* file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
* "License"); you may not use this file except in compliance with the
* License. You may obtain a copy of the License at:
*
* http://www.netfpga-cic.org
*
* Unless required by applicable law or agreed to in writing, Work distributed
* under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
* CONDITIONS OF ANY KIND, either express or implied. See the License for the
* specific language governing permissions and limitations under the License.
*
* @NETFPGA_LICENSE_HEADER_END@
*
********************************************************************************/


  module header_parser
    #(parameter C_S_AXIS_DATA_WIDTH	= 512
      )
   (// --- Interface to the previous stage
    input  [C_S_AXIS_DATA_WIDTH-1:0]   tdata,
    input                              tvalid,
    input                              tlast,
   
    // --- Interface to process block
    output                             is_arp_pkt,
    output                             is_ip_pkt,
    output                             is_ip6_pkt,
    output                             is_tcp_pkt,
    output                             is_udp_pkt,
    output                             is_broadcast,
    output                             is_syn,
    output                             is_fin,
    output  [15:0]                  window_size,
    output  [95:0]                  flow_id,
 //   input                              parser_trigger,
    output                             parser_info_vld,

     // --- Misc

    input                              reset,
    input                              clk
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

   //------------------ Internal Parameter ---------------------------
   localparam				ETH_ARP	= 16'h0608;	// byte order = Little Endian
   localparam				ETH_IP 	= 16'h0008;	// byte order = Little Endian
   localparam				ETH_IP6	= 16'hDD86;	// byte order = Little Endian
   localparam				IP_TCP	= 8'h06;	
   localparam				IP_UDP	= 8'h11;

   localparam                           IDLE		= 1;
   localparam                           CYCLE0  	= 2;
   localparam                           CYCLE1  	= 4;
   localparam                           CYCLE2  	= 8;
   localparam                           CYCLE3  	= 16;
   localparam				FLUSH_ENTRY	= 32;

   //---------------------- Wires/Regs -------------------------------
   reg [15:0]                          ethertype;
   reg [7:0] 			       ipprotocol;

   reg [47:0]			       dst_MAC;
//   reg                                 search_req;

   reg [5:0]                           state, state_next;
   reg                                 wr_en, wr_en_next, wr_en_d;

   wire                                broadcast_bit;

 //   wire [15:0]			       ethertype_fifo;
   reg				       rd_parser;
   wire				       empty;
   reg  [95:0]			       flow_data;
   reg [15:0]                          window_data;
   reg 				       syn_flag, fin_flag;

  reg [511:0]                          tdata_d;

   //----------------------- Modules ---------------------------------
   fallthrough_small_fifo #(.WIDTH(8+96+16), .MAX_DEPTH_BITS(2))
      eth_fifo
        (.din ({              			// is for us
                (ethertype==ETH_ARP),				// is ARP
                (ethertype==ETH_IP),				// is IP
		(ethertype==ETH_IP6),				// is IPv6
                (broadcast_bit),				// is broadcast
                (ipprotocol==IP_TCP),                               // is TCP
		(ipprotocol==IP_UDP),
		flow_data, window_data, syn_flag, fin_flag}),	                        // is UDP
         .wr_en (wr_en),					// Write enable
         .rd_en (parser_info_vld),				// Read the next word
         .dout ({is_arp_pkt, is_ip_pkt, is_ip6_pkt, is_broadcast, is_tcp_pkt, is_udp_pkt, flow_id, window_size,is_syn,is_fin}),
         .full (),
         .nearly_full (),
         .prog_full (),
         .empty (empty),
         .reset (reset),
         .clk (clk)
         );


  
   //------------------------ Logic ----------------------------------
   assign parser_info_vld = !empty;
   assign broadcast_bit = dst_MAC[40]; 	// Big endian 

  

   /******************************************************************
    * Get the type of the pkt
    * Note that the Parsing is not entirely "legal" and makes assumptions as for the headers
    *****************************************************************/
   always @(posedge clk) begin
      if(reset) begin
	 tdata_d    <= #1 0;
         dst_MAC    <= #1 0;
         ethertype  <= #1 0;
	 ipprotocol <= #1 0;
	 flow_data  <= #1 0;
	 window_data<= #1 0;
	 syn_flag   <= #1 0;
	 fin_flag   <= #1 0;
     end
      else begin
	 if (tvalid) begin
	    tdata_d     <= #1 tdata;
         end
	 dst_MAC	<= #1  (state == CYCLE0) ? tdata[47:0] : dst_MAC; 	// Little endian
	 ethertype	<= #1  (state == CYCLE0) ? tdata[111:96] : ethertype; 	// Little endian
         ipprotocol  <= #1  (state == CYCLE0) ? tdata[191:184]   : ipprotocol;       // Little Endian 
	 flow_data   <= #1  (state == CYCLE0) ? {tdata[255:208],tdata[303:256]} : flow_data; //: (state == CYCLE1) ? {flow_data[95:48],tdata[47:0]}: flow_data; //"flow id: src ip, dst ip, src port, dest port. not 5-tuple to save resources
	 window_data <= #1  (ipprotocol==IP_TCP) ?  ((state == CYCLE0) ? {tdata[391:384],tdata[399:392]}: window_data ) : window_data;// Little endian**
	 syn_flag   <= #1 (ipprotocol==IP_TCP) ? ((state == CYCLE0) ? tdata[377]: syn_flag ) : 0;// Little endian
	 fin_flag   <= #1 (ipprotocol==IP_TCP) ? ((state == CYCLE0) ? tdata[376]: fin_flag ) : 0;// Little endian
      end // else: !if(reset)
   end // always @ (posedge clk)

   /*************************************************************
    * Provide timing for the header parsing operations
    *************************************************************/
   always @(*) begin

      state_next = state;
      wr_en_next = 0;
       rd_parser = 0;

      case(state)

        CYCLE0: begin
           if(tvalid) begin
 		if (tlast) begin
              		state_next	= CYCLE0;
             		wr_en_next	= 1;
		end
		else
			state_next      = CYCLE1;
           end
         end
        CYCLE1: begin
           if(tvalid) begin
 		if (tlast) begin
              		state_next	= CYCLE0;
             		wr_en_next	= 1;
		end
		else
			state_next      = CYCLE2;
           end
         end
        CYCLE2: begin
           if(tvalid) begin
 		if (tlast) begin
              		state_next	= CYCLE0;
             		wr_en_next	= 1;
		end
		else
			state_next      = CYCLE3;
           end
         end
        CYCLE3: begin
           if(tvalid) begin
                wr_en_next	= 1;
 		if (tlast) begin
              		state_next	= CYCLE0;           		
		end
		else
			state_next      = FLUSH_ENTRY;
           end
         end
	FLUSH_ENTRY: begin
		if (tlast)
		    state_next	= CYCLE0;
	end

      endcase // case(state)

   end // always @(*)


   always @(posedge clk) begin
      if(reset) begin
         state		<= #1 CYCLE0;
	wr_en		<= #1 0;
	wr_en_d         <= #1 0;
      end
      else begin
         state		<= #1 state_next;
	 wr_en		<= #1 wr_en_next;
	 wr_en_d        <= #1 wr_en;
     end
   end

endmodule // header_parser


