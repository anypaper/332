//
// Copyright (c) 2015 James Hongyi Zeng, Yury Audzevich
// Copyright (c) 2016 Jong Hun Han
// All rights reserved.
// 
// Description:
//        10g ethernet tx queue with backpressure.
//        ported from nf10 (Virtex-5 based) interface.
//
//
// This software was developed by
// Stanford University and the University of Cambridge Computer Laboratory
// under National Science Foundation under Grant No. CNS-0855268,
// the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
// by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"), 
// as part of the DARPA MRC research programme.
//
// @NETFPGA_LICENSE_HEADER_START@
//
// Licensed to NetFPGA C.I.C. (NetFPGA) under one or more
// contributor license agreements.  See the NOTICE file distributed with this
// work for additional information regarding copyright ownership.  NetFPGA
// licenses this file to you under the NetFPGA Hardware-Software License,
// Version 1.0 (the "License"); you may not use this file except in compliance
// with the License.  You may obtain a copy of the License at:
//
//   http://www.netfpga-cic.org
//
// Unless required by applicable law or agreed to in writing, Work distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations under the License.
//
// @NETFPGA_LICENSE_HEADER_END@

module tx_queue
 #(
    parameter AXI_DATA_WIDTH             = 512, //Only 64 is supported right now.
    parameter C_S_AXIS_TUSER_WIDTH       = 512 
 
 )
 (
    // AXI side
    input                               clk,
    input                               reset,
      
    input [C_S_AXIS_TUSER_WIDTH-1:0]    i_tuser,
    input [AXI_DATA_WIDTH-1:0]          i_tdata,
    input [(AXI_DATA_WIDTH/8)-1:0]      i_tkeep,
    input                               i_tvalid,
    input                               i_tlast,
    output                              i_tready,
    
    // other
    output                              tx_dequeued_pkt,
    output reg                          be,  
    output reg                          tx_pkts_enqueued_signal,
    output reg [15:0]                   tx_bytes_enqueued,
       
     // MAC side
    input                               clk156,
   input                                areset_clk156,
    
    // AXI side output
    output [AXI_DATA_WIDTH-1:0]         o_tdata,
    output reg [(AXI_DATA_WIDTH/8)-1:0] o_tkeep,
    output reg                          o_tvalid,
    output reg                          o_tlast,
    output reg                          o_tuser,
    input                               o_tready   
 );
 
    localparam IDLE         = 2'd0;
    localparam SEND_PKT     = 2'd1;
 
    localparam METADATA     = 1'b0;
    localparam EOP          = 1'b1;
    
    wire [6:0]                          tkeep_encoded_o;
    reg  [63:0]                         tkeep_decoded_o;
    reg  [6:0]                          tkeep_encoded_i;
    wire                                tlast_axi_i;
    wire                                tlast_axi_o;
 
    wire                                fifo_almost_full, info_fifo_full;
    wire                                fifo_empty, info_fifo_empty;
    reg                                 fifo_rd_en, info_fifo_rd_en;
    reg                                 info_fifo_wr_en;
    wire                                fifo_wr_en;       
     
    reg                                 tx_dequeued_pkt_next;   

    reg  [2:0]                          state, state_next;
    reg                                 state1, state1_next;
   
    wire [2:0]                          zero_padding;

    ////////////////////////////////////////////////
    ////////////////////////////////////////////////
    assign fifo_wr_en  = (i_tvalid & i_tready);    
    assign i_tready    = ~fifo_almost_full & ~info_fifo_full;
    assign tlast_axi_i = i_tlast;

tx_fifo u_tx_fifo (
	.rst         (areset_clk156), //: IN STD_LOGIC;
	.wr_clk      (clk), //: IN STD_LOGIC;
	.rd_clk      (clk156), //: IN STD_LOGIC;
	.din         ({tlast_axi_i , tkeep_encoded_i, i_tdata}), //: IN STD_LOGIC_VECTOR(519 DOWNTO 0);
	.wr_en       (fifo_wr_en), //: IN STD_LOGIC;
	.rd_en       (fifo_rd_en), //: IN STD_LOGIC;
	.dout        ({tlast_axi_o, tkeep_encoded_o, o_tdata}), //: OUT STD_LOGIC_VECTOR(519 DOWNTO 0);
	.full        (), //: OUT STD_LOGIC;
	.almost_full (fifo_almost_full), //: OUT STD_LOGIC;
	.empty       (fifo_empty), //: OUT STD_LOGIC;
	.almost_empty(), //: OUT STD_LOGIC;
	.wr_rst_busy (), //: OUT STD_LOGIC;
	.rd_rst_busy ()  //: OUT STD_LOGIC
);

      		 
      // Instantiate clock domain crossing FIFO
      // 36Kb FIFO (First-In-First-Out) Block RAM Memory primitive V7  
      // IMPORTANT: RST should stay high for at least 5 clks, RDEN & WREN should stay 1'b0;
//      FIFO36E2 #(        
//        .PROG_EMPTY_THRESH       (9'hA), 
//        .PROG_FULL_THRESH        (9'hA),
//        //.DO_REG                     (1),
//		.REGISTER_MODE           ("REGISTERED"),
//        .EN_ECC_READ                ("FALSE"),
//        .EN_ECC_WRITE               ("FALSE"),
//        //.EN_SYN                     ("FALSE"),
//        .FIRST_WORD_FALL_THROUGH    ("TRUE"),
//        //.DATA_WIDTH                 (72),       
//		.WRITE_WIDTH                (72),
//		.READ_WIDTH                (72),
//        //.FIFO_MODE                  ("FIFO36_72"),
//        .INIT                       (72'h000000000000000000),
//        //.SIM_DEVICE                 ("7SERIES"), 
//        .SRVAL                      (72'h000000000000000000)
//      ) tx_fifo_0 (
//        .PROGEMPTY                (),
//        .PROGFULL                 (fifo0_almost_full),
//        .EMPTY                      (fifo0_empty),
//        .FULL                       (),
//               
//        .DIN                        (i_tdata[63:0]),
//        .DINP                       ({3'b0, tlast_axi_i , tkeep_encoded_i}),
//        .WRCLK                      (clk),
//        .WREN                       (fifo_wr_en),
//        .WRCOUNT                    (),
//        .WRERR                      (),    
//                   
//        .DOUT                       (o_tdata[63:0]),
//        .DOUTP                      ({zero_padding, tlast_axi_o, tkeep_encoded_o}),
//        .RDCLK                      (clk156),
//        .RDEN                       (fifo_rd_en),
//        .RDCOUNT                    (),
//        .RDERR                      (),
//           
//        .SBITERR                    (),
//        .DBITERR                    (),
//        .ECCPARITY                  (),
//        .INJECTDBITERR              (),
//        .INJECTSBITERR              (),    
//      
//        .RST                        (areset_clk156),
//        .RSTREG                     (), 
//        .REGCE                      ()     
//      );
//
//      FIFO36E2 #(        
//        .PROG_EMPTY_THRESH       (9'hA), 
//        .PROG_FULL_THRESH        (9'hA),
//		.REGISTER_MODE           ("REGISTERED"),
//        .EN_ECC_READ             ("FALSE"),
//        .EN_ECC_WRITE            ("FALSE"),
//        .FIRST_WORD_FALL_THROUGH ("TRUE"),
//		.WRITE_WIDTH             (72),
//		.READ_WIDTH              (72),
//        .INIT                    (72'h000000000000000000),
//        .SRVAL                   (72'h000000000000000000)
//      ) tx_fifo_1 (
//        .PROGEMPTY                (),
//        .PROGFULL                 (fifo1_almost_full),
//        .EMPTY                    (fifo1_empty),
//        .FULL                     (),
//               
//        .DIN                      (i_tdata[127:64]),
//        .DINP                     ({3'b0, tlast_axi_i , tkeep0_encoded_i}),
//        .WRCLK                    (clk),
//        .WREN                     (fifo_wr_en),
//        .WRCOUNT                  (),
//        .WRERR                    (),    
//                   
//        .DOUT                     (o_tdata[127:64]),
//        .DOUTP                    ({zero_padding, tlast_axi_o, tkeep_encoded_o}),
//        .RDCLK                    (clk156),
//        .RDEN                     (fifo_rd_en),
//        .RDCOUNT                  (),
//        .RDERR                    (),
//           
//        .SBITERR                  (),
//        .DBITERR                  (),
//        .ECCPARITY                (),
//        .INJECTDBITERR            (),
//        .INJECTSBITERR            (),    
//      
//        .RST                      (areset_clk156),
//        .RSTREG                   (), 
//        .REGCE                    ()     
//      );
//  	
//      FIFO36E2 #(        
//        .PROG_EMPTY_THRESH       (9'hA), 
//        .PROG_FULL_THRESH        (9'hA),
//		.REGISTER_MODE           ("REGISTERED"),
//        .EN_ECC_READ             ("FALSE"),
//        .EN_ECC_WRITE            ("FALSE"),
//        .FIRST_WORD_FALL_THROUGH ("TRUE"),
//		.WRITE_WIDTH             (72),
//		.READ_WIDTH              (72),
//        .INIT                    (72'h000000000000000000),
//        .SRVAL                   (72'h000000000000000000)
//      ) tx_fifo_2 (
//        .PROGEMPTY                (),
//        .PROGFULL                 (fifo2_almost_full),
//        .EMPTY                    (fifo2_empty),
//        .FULL                     (),
//               
//        .DIN                      (i_tdata[191:128]),
//        .DINP                     ({3'b0, tlast_axi_i , tkeep0_encoded_i}),
//        .WRCLK                    (clk),
//        .WREN                     (fifo_wr_en),
//        .WRCOUNT                  (),
//        .WRERR                    (),    
//                   
//        .DOUT                     (o_tdata[191:128]),
//        .DOUTP                    ({zero_padding, tlast_axi_o, tkeep_encoded_o}),
//        .RDCLK                    (clk156),
//        .RDEN                     (fifo_rd_en),
//        .RDCOUNT                  (),
//        .RDERR                    (),
//           
//        .SBITERR                  (),
//        .DBITERR                  (),
//        .ECCPARITY                (),
//        .INJECTDBITERR            (),
//        .INJECTSBITERR            (),    
//      
//        .RST                      (areset_clk156),
//        .RSTREG                   (), 
//        .REGCE                    ()     
//      );
//  	
//      FIFO36E2 #(        
//        .PROG_EMPTY_THRESH       (9'hA), 
//        .PROG_FULL_THRESH        (9'hA),
//		.REGISTER_MODE           ("REGISTERED"),
//        .EN_ECC_READ             ("FALSE"),
//        .EN_ECC_WRITE            ("FALSE"),
//        .FIRST_WORD_FALL_THROUGH ("TRUE"),
//		.WRITE_WIDTH             (72),
//		.READ_WIDTH              (72),
//        .INIT                    (72'h000000000000000000),
//        .SRVAL                   (72'h000000000000000000)
//      ) tx_fifo_3 (
//        .PROGEMPTY                (),
//        .PROGFULL                 (fifo3_almost_full),
//        .EMPTY                    (fifo3_empty),
//        .FULL                     (),
//               
//        .DIN                      (i_tdata[255:192]),
//        .DINP                     ({3'b0, tlast_axi_i , tkeep0_encoded_i}),
//        .WRCLK                    (clk),
//        .WREN                     (fifo_wr_en),
//        .WRCOUNT                  (),
//        .WRERR                    (),    
//                   
//        .DOUT                     (o_tdata[255:192]),
//        .DOUTP                    ({zero_padding, tlast_axi_o, tkeep_encoded_o}),
//        .RDCLK                    (clk156),
//        .RDEN                     (fifo_rd_en),
//        .RDCOUNT                  (),
//        .RDERR                    (),
//           
//        .SBITERR                  (),
//        .DBITERR                  (),
//        .ECCPARITY                (),
//        .INJECTDBITERR            (),
//        .INJECTSBITERR            (),    
//      
//        .RST                      (areset_clk156),
//        .RSTREG                   (), 
//        .REGCE                    ()     
//      );
//  	
//      FIFO36E2 #(        
//        .PROG_EMPTY_THRESH       (9'hA), 
//        .PROG_FULL_THRESH        (9'hA),
//		.REGISTER_MODE           ("REGISTERED"),
//        .EN_ECC_READ             ("FALSE"),
//        .EN_ECC_WRITE            ("FALSE"),
//        .FIRST_WORD_FALL_THROUGH ("TRUE"),
//		.WRITE_WIDTH             (72),
//		.READ_WIDTH              (72),
//        .INIT                    (72'h000000000000000000),
//        .SRVAL                   (72'h000000000000000000)
//      ) tx_fifo_4 (
//        .PROGEMPTY                (),
//        .PROGFULL                 (fifo4_almost_full),
//        .EMPTY                    (fifo4_empty),
//        .FULL                     (),
//               
//        .DIN                      (i_tdata[319:256]),
//        .DINP                     ({3'b0, tlast_axi_i , tkeep0_encoded_i}),
//        .WRCLK                    (clk),
//        .WREN                     (fifo_wr_en),
//        .WRCOUNT                  (),
//        .WRERR                    (),    
//                   
//        .DOUT                     (o_tdata[319:256]),
//        .DOUTP                    ({zero_padding, tlast_axi_o, tkeep_encoded_o}),
//        .RDCLK                    (clk156),
//        .RDEN                     (fifo_rd_en),
//        .RDCOUNT                  (),
//        .RDERR                    (),
//           
//        .SBITERR                  (),
//        .DBITERR                  (),
//        .ECCPARITY                (),
//        .INJECTDBITERR            (),
//        .INJECTSBITERR            (),    
//      
//        .RST                      (areset_clk156),
//        .RSTREG                   (), 
//        .REGCE                    ()     
//      );
//  	
//      FIFO36E2 #(        
//        .PROG_EMPTY_THRESH       (9'hA), 
//        .PROG_FULL_THRESH        (9'hA),
//		.REGISTER_MODE           ("REGISTERED"),
//        .EN_ECC_READ             ("FALSE"),
//        .EN_ECC_WRITE            ("FALSE"),
//        .FIRST_WORD_FALL_THROUGH ("TRUE"),
//		.WRITE_WIDTH             (72),
//		.READ_WIDTH              (72),
//        .INIT                    (72'h000000000000000000),
//        .SRVAL                   (72'h000000000000000000)
//      ) tx_fifo_5 (
//        .PROGEMPTY                (),
//        .PROGFULL                 (fifo5_almost_full),
//        .EMPTY                    (fifo5_empty),
//        .FULL                     (),
//               
//        .DIN                      (i_tdata[383:320]),
//        .DINP                     ({3'b0, tlast_axi_i , tkeep0_encoded_i}),
//        .WRCLK                    (clk),
//        .WREN                     (fifo_wr_en),
//        .WRCOUNT                  (),
//        .WRERR                    (),    
//                   
//        .DOUT                     (o_tdata[383:320]),
//        .DOUTP                    ({zero_padding, tlast_axi_o, tkeep_encoded_o}),
//        .RDCLK                    (clk156),
//        .RDEN                     (fifo_rd_en),
//        .RDCOUNT                  (),
//        .RDERR                    (),
//           
//        .SBITERR                  (),
//        .DBITERR                  (),
//        .ECCPARITY                (),
//        .INJECTDBITERR            (),
//        .INJECTSBITERR            (),    
//      
//        .RST                      (areset_clk156),
//        .RSTREG                   (), 
//        .REGCE                    ()     
//      );
//  	
//      FIFO36E2 #(        
//        .PROG_EMPTY_THRESH       (9'hA), 
//        .PROG_FULL_THRESH        (9'hA),
//		.REGISTER_MODE           ("REGISTERED"),
//        .EN_ECC_READ             ("FALSE"),
//        .EN_ECC_WRITE            ("FALSE"),
//        .FIRST_WORD_FALL_THROUGH ("TRUE"),
//		.WRITE_WIDTH             (72),
//		.READ_WIDTH              (72),
//        .INIT                    (72'h000000000000000000),
//        .SRVAL                   (72'h000000000000000000)
//      ) tx_fifo_6 (
//        .PROGEMPTY                (),
//        .PROGFULL                 (fifo6_almost_full),
//        .EMPTY                    (fifo6_empty),
//        .FULL                     (),
//               
//        .DIN                      (i_tdata[447:384]),
//        .DINP                     ({3'b0, tlast_axi_i , tkeep0_encoded_i}),
//        .WRCLK                    (clk),
//        .WREN                     (fifo_wr_en),
//        .WRCOUNT                  (),
//        .WRERR                    (),    
//                   
//        .DOUT                     (o_tdata[447:383]),
//        .DOUTP                    ({zero_padding, tlast_axi_o, tkeep_encoded_o}),
//        .RDCLK                    (clk156),
//        .RDEN                     (fifo_rd_en),
//        .RDCOUNT                  (),
//        .RDERR                    (),
//           
//        .SBITERR                  (),
//        .DBITERR                  (),
//        .ECCPARITY                (),
//        .INJECTDBITERR            (),
//        .INJECTSBITERR            (),    
//      
//        .RST                      (areset_clk156),
//        .RSTREG                   (), 
//        .REGCE                    ()     
//      );
//  	
//      FIFO36E2 #(        
//        .PROG_EMPTY_THRESH       (9'hA), 
//        .PROG_FULL_THRESH        (9'hA),
//		.REGISTER_MODE           ("REGISTERED"),
//        .EN_ECC_READ             ("FALSE"),
//        .EN_ECC_WRITE            ("FALSE"),
//        .FIRST_WORD_FALL_THROUGH ("TRUE"),
//		.WRITE_WIDTH             (72),
//		.READ_WIDTH              (72),
//        .INIT                    (72'h000000000000000000),
//        .SRVAL                   (72'h000000000000000000)
//      ) tx_fifo_7 (
//        .PROGEMPTY                (),
//        .PROGFULL                 (fifo7_almost_full),
//        .EMPTY                    (fifo7_empty),
//        .FULL                     (),
//               
//        .DIN                      (i_tdata[511:448]),
//        .DINP                     ({3'b0, tlast_axi_i , tkeep0_encoded_i}),
//        .WRCLK                    (clk),
//        .WREN                     (fifo_wr_en),
//        .WRCOUNT                  (),
//        .WRERR                    (),    
//                   
//        .DOUT                     (o_tdata[511:448]),
//        .DOUTP                    ({zero_padding, tlast_axi_o, tkeep_encoded_o}),
//        .RDCLK                    (clk156),
//        .RDEN                     (fifo_rd_en),
//        .RDCOUNT                  (),
//        .RDERR                    (),
//           
//        .SBITERR                  (),
//        .DBITERR                  (),
//        .ECCPARITY                (),
//        .INJECTDBITERR            (),
//        .INJECTSBITERR            (),    
//      
//        .RST                      (areset_clk156),
//        .RSTREG                   (), 
//        .REGCE                    ()     
//      );

	fifo_generator_1_9 tx_info_fifo (
		.din 			(1'b0							),	
		.wr_en			(info_fifo_wr_en					), //Only 1 cycle per packet!	
		.wr_clk			(clk							),
		
		.dout			(							),
		.rd_en			(info_fifo_rd_en					),
		.rd_clk			(clk156							),
		
		.full 			(info_fifo_full							),
		.empty 			(info_fifo_empty					),
 		.rst			(areset_clk156							)
	);	
	 

      // Encoder to map 8bit strobe to 4 bit
      // and vice versa.      
      always @(*) begin
          // encode FIFO IN (8b->4b)
          case (i_tkeep)
              64'h1                : tkeep_encoded_i = 7'h0;
              64'h3                : tkeep_encoded_i = 7'h1;
              64'h7                : tkeep_encoded_i = 7'h2;
              64'hF                : tkeep_encoded_i = 7'h3;
              64'h1F               : tkeep_encoded_i = 7'h4;
              64'h3F               : tkeep_encoded_i = 7'h5;
              64'h7F               : tkeep_encoded_i = 7'h6;
              64'hFF               : tkeep_encoded_i = 7'h7;
              64'h1FF              : tkeep_encoded_i = 7'h8;
              64'h3FF              : tkeep_encoded_i = 7'h9;
              64'h7FF              : tkeep_encoded_i = 7'ha;
              64'hFFF              : tkeep_encoded_i = 7'hb;
              64'h1FFF             : tkeep_encoded_i = 7'hc;
              64'h3FFF             : tkeep_encoded_i = 7'hd;
              64'h7FFF             : tkeep_encoded_i = 7'he;
              64'hFFFF             : tkeep_encoded_i = 7'hf;
              64'h1FFFF            : tkeep_encoded_i = 7'h10;
              64'h3FFFF            : tkeep_encoded_i = 7'h11;
              64'h7FFFF            : tkeep_encoded_i = 7'h12;
              64'hFFFFF            : tkeep_encoded_i = 7'h13;
              64'h1FFFFF           : tkeep_encoded_i = 7'h14;
              64'h3FFFFF           : tkeep_encoded_i = 7'h15;
              64'h7FFFFF           : tkeep_encoded_i = 7'h16;
              64'hFFFFFF           : tkeep_encoded_i = 7'h17;
              64'h1FFFFFF          : tkeep_encoded_i = 7'h18;
              64'h3FFFFFF          : tkeep_encoded_i = 7'h19;
              64'h7FFFFFF          : tkeep_encoded_i = 7'h1a;
              64'hFFFFFFF          : tkeep_encoded_i = 7'h1b;
              64'h1FFFFFFF         : tkeep_encoded_i = 7'h1c;
              64'h3FFFFFFF         : tkeep_encoded_i = 7'h1d;
              64'h7FFFFFFF         : tkeep_encoded_i = 7'h1e;
              64'hFFFFFFFF         : tkeep_encoded_i = 7'h1f;
              64'h1_FFFFFFFF       : tkeep_encoded_i = 7'h20;
              64'h3_FFFFFFFF       : tkeep_encoded_i = 7'h21;
              64'h7_FFFFFFFF       : tkeep_encoded_i = 7'h22;
              64'hF_FFFFFFFF       : tkeep_encoded_i = 7'h23;
              64'h1F_FFFFFFFF      : tkeep_encoded_i = 7'h24;
              64'h3F_FFFFFFFF      : tkeep_encoded_i = 7'h25;
              64'h7F_FFFFFFFF      : tkeep_encoded_i = 7'h26;
              64'hFF_FFFFFFFF      : tkeep_encoded_i = 7'h27;
              64'h1FF_FFFFFFFF     : tkeep_encoded_i = 7'h28;
              64'h3FF_FFFFFFFF     : tkeep_encoded_i = 7'h29;
              64'h7FF_FFFFFFFF     : tkeep_encoded_i = 7'h2a;
              64'hFFF_FFFFFFFF     : tkeep_encoded_i = 7'h2b;
              64'h1FFF_FFFFFFFF    : tkeep_encoded_i = 7'h2c;
              64'h3FFF_FFFFFFFF    : tkeep_encoded_i = 7'h2d;
              64'h7FFF_FFFFFFFF    : tkeep_encoded_i = 7'h2e;
              64'hFFFF_FFFFFFFF    : tkeep_encoded_i = 7'h2f;
              64'h1FFFF_FFFFFFFF   : tkeep_encoded_i = 7'h30;
              64'h3FFFF_FFFFFFFF   : tkeep_encoded_i = 7'h31;
              64'h7FFFF_FFFFFFFF   : tkeep_encoded_i = 7'h32;
              64'hFFFFF_FFFFFFFF   : tkeep_encoded_i = 7'h33;
              64'h1FFFFF_FFFFFFFF  : tkeep_encoded_i = 7'h34;
              64'h3FFFFF_FFFFFFFF  : tkeep_encoded_i = 7'h35;
              64'h7FFFFF_FFFFFFFF  : tkeep_encoded_i = 7'h36;
              64'hFFFFFF_FFFFFFFF  : tkeep_encoded_i = 7'h37;
              64'h1FFFFFF_FFFFFFFF : tkeep_encoded_i = 7'h38;
              64'h3FFFFFF_FFFFFFFF : tkeep_encoded_i = 7'h39;
              64'h7FFFFFF_FFFFFFFF : tkeep_encoded_i = 7'h3a;
              64'hFFFFFFF_FFFFFFFF : tkeep_encoded_i = 7'h3b;
              64'h1FFFFFFF_FFFFFFFF: tkeep_encoded_i = 7'h3c;
              64'h3FFFFFFF_FFFFFFFF: tkeep_encoded_i = 7'h3d;
              64'h7FFFFFFF_FFFFFFFF: tkeep_encoded_i = 7'h3e;
              64'hFFFFFFFF_FFFFFFFF: tkeep_encoded_i = 7'h3f;
              default:  tkeep_encoded_i = 7'h40;
          endcase
      
          // decode FIFO OUT (4b->8b)   
          case (tkeep_encoded_o)
              7'h0 :     tkeep_decoded_o = 64'h1                ;
              7'h1 :     tkeep_decoded_o = 64'h3                ;
              7'h2 :     tkeep_decoded_o = 64'h7                ;
              7'h3 :     tkeep_decoded_o = 64'hF                ;
              7'h4 :     tkeep_decoded_o = 64'h1F               ;
              7'h5 :     tkeep_decoded_o = 64'h3F               ;
              7'h6 :     tkeep_decoded_o = 64'h7F               ;
              7'h7 :     tkeep_decoded_o = 64'hFF               ;
              7'h8 :     tkeep_decoded_o = 64'h1FF              ;
              7'h9 :     tkeep_decoded_o = 64'h3FF              ;
              7'ha :     tkeep_decoded_o = 64'h7FF              ;
              7'hb :     tkeep_decoded_o = 64'hFFF              ;
              7'hc :     tkeep_decoded_o = 64'h1FFF             ;
              7'hd :     tkeep_decoded_o = 64'h3FFF             ;
              7'he :     tkeep_decoded_o = 64'h7FFF             ;
              7'hf :     tkeep_decoded_o = 64'hFFFF             ;
              7'h10:     tkeep_decoded_o = 64'h1FFFF            ;
              7'h11:     tkeep_decoded_o = 64'h3FFFF            ;
              7'h12:     tkeep_decoded_o = 64'h7FFFF            ;
              7'h13:     tkeep_decoded_o = 64'hFFFFF            ;
              7'h14:     tkeep_decoded_o = 64'h1FFFFF           ;
              7'h15:     tkeep_decoded_o = 64'h3FFFFF           ;
              7'h16:     tkeep_decoded_o = 64'h7FFFFF           ;
              7'h17:     tkeep_decoded_o = 64'hFFFFFF           ;
              7'h18:     tkeep_decoded_o = 64'h1FFFFFF          ;
              7'h19:     tkeep_decoded_o = 64'h3FFFFFF          ;
              7'h1a:     tkeep_decoded_o = 64'h7FFFFFF          ;
              7'h1b:     tkeep_decoded_o = 64'hFFFFFFF          ;
              7'h1c:     tkeep_decoded_o = 64'h1FFFFFFF         ;
              7'h1d:     tkeep_decoded_o = 64'h3FFFFFFF         ;
              7'h1e:     tkeep_decoded_o = 64'h7FFFFFFF         ;
              7'h1f:     tkeep_decoded_o = 64'hFFFFFFFF         ;
              7'h20:     tkeep_decoded_o = 64'h1_FFFFFFFF       ;
              7'h21:     tkeep_decoded_o = 64'h3_FFFFFFFF       ;
              7'h22:     tkeep_decoded_o = 64'h7_FFFFFFFF       ;
              7'h23:     tkeep_decoded_o = 64'hF_FFFFFFFF       ;
              7'h24:     tkeep_decoded_o = 64'h1F_FFFFFFFF      ;
              7'h25:     tkeep_decoded_o = 64'h3F_FFFFFFFF      ;
              7'h26:     tkeep_decoded_o = 64'h7F_FFFFFFFF      ;
              7'h27:     tkeep_decoded_o = 64'hFF_FFFFFFFF      ;
              7'h28:     tkeep_decoded_o = 64'h1FF_FFFFFFFF     ;
              7'h29:     tkeep_decoded_o = 64'h3FF_FFFFFFFF     ;
              7'h2a:     tkeep_decoded_o = 64'h7FF_FFFFFFFF     ;
              7'h2b:     tkeep_decoded_o = 64'hFFF_FFFFFFFF     ;
              7'h2c:     tkeep_decoded_o = 64'h1FFF_FFFFFFFF    ;
              7'h2d:     tkeep_decoded_o = 64'h3FFF_FFFFFFFF    ;
              7'h2e:     tkeep_decoded_o = 64'h7FFF_FFFFFFFF    ;
              7'h2f:     tkeep_decoded_o = 64'hFFFF_FFFFFFFF    ;
              7'h30:     tkeep_decoded_o = 64'h1FFFF_FFFFFFFF   ;
              7'h31:     tkeep_decoded_o = 64'h3FFFF_FFFFFFFF   ;
              7'h32:     tkeep_decoded_o = 64'h7FFFF_FFFFFFFF   ;
              7'h33:     tkeep_decoded_o = 64'hFFFFF_FFFFFFFF   ;
              7'h34:     tkeep_decoded_o = 64'h1FFFFF_FFFFFFFF  ;
              7'h35:     tkeep_decoded_o = 64'h3FFFFF_FFFFFFFF  ;
              7'h36:     tkeep_decoded_o = 64'h7FFFFF_FFFFFFFF  ;
              7'h37:     tkeep_decoded_o = 64'hFFFFFF_FFFFFFFF  ;
              7'h38:     tkeep_decoded_o = 64'h1FFFFFF_FFFFFFFF ;
              7'h39:     tkeep_decoded_o = 64'h3FFFFFF_FFFFFFFF ;
              7'h3a:     tkeep_decoded_o = 64'h7FFFFFF_FFFFFFFF ;
              7'h3b:     tkeep_decoded_o = 64'hFFFFFFF_FFFFFFFF ;
              7'h3c:     tkeep_decoded_o = 64'h1FFFFFFF_FFFFFFFF;
              7'h3d:     tkeep_decoded_o = 64'h3FFFFFFF_FFFFFFFF;
              7'h3e:     tkeep_decoded_o = 64'h7FFFFFFF_FFFFFFFF;
              7'h3f:     tkeep_decoded_o = 64'hFFFFFFFF_FFFFFFFF;
              default:  tkeep_decoded_o = 64'h0;
          endcase         
      end
 
      
          
      // Sideband INFO 
      // pkt enq FSM comb
      always @(*) begin 
          state1_next             = METADATA;
              
          tx_pkts_enqueued_signal = 0;
          tx_bytes_enqueued       = 0;
       
          case(state1)
              METADATA: begin
                  if(i_tvalid & i_tlast & i_tready) begin
                      state1_next = METADATA;
                      tx_pkts_enqueued_signal = 1;
                      tx_bytes_enqueued       = i_tuser[15:0];
                  end else if(i_tvalid & i_tready) begin
                      tx_pkts_enqueued_signal = 1;
                      tx_bytes_enqueued       = i_tuser[15:0];
                      state1_next             = EOP;
                  end
              end
       
              EOP: begin
                  state1_next = EOP;
                  if(i_tvalid & i_tlast & i_tready) begin
                      state1_next = METADATA;
                  end
              end
                      
              default: begin 
                      state1_next = METADATA;
              end
           endcase     
      end
       
      // pkt enq FSM seq  
      always @(posedge clk) begin
           if (reset) state1 <= METADATA;
           else       state1 <= state1_next;
      end
           
      // write en on pkt
      always @(posedge clk)
         if (reset)
            info_fifo_wr_en   <= 0;
         else
            info_fifo_wr_en <= i_tlast & i_tvalid & i_tready;
        
 
      //////////////////////////////////////////////////////////
      //////////////////////////////////////////////////////////
      //////////////////////////////////////////////////////////
      
      // FIFO draining FSM comb  
      assign tx_dequeued_pkt = tx_dequeued_pkt_next; 

      always @(*) begin
          state_next            = IDLE;
          
          // axi
          o_tkeep               = tkeep_decoded_o;
          o_tuser               = 1'b0; // no underrun
          o_tvalid              = 1'b0;
          o_tlast               = 1'b0;
          
          // fifos
          fifo_rd_en            = 1'b0;
          info_fifo_rd_en       = 1'b0;
          
          //sideband          
          tx_dequeued_pkt_next  = 'b0;
          be                    = 'b0;
 
          case(state)
              IDLE: begin
                  o_tkeep = 64'b0;
                  if( ~info_fifo_empty & ~fifo_empty) begin
                      // pkt is stored already
                      info_fifo_rd_en = 1'b1;
                      be              = 'b0;                      
                      state_next      = SEND_PKT;                     
                  end
              end

              SEND_PKT: begin 
                // very important: 
                // tvalid to go first: pg157, v3.0, pp. 109.
                o_tvalid = 1'b1;
                state_next  = SEND_PKT;
                if (o_tready & ~fifo_empty) begin                
                    fifo_rd_en            = 1'b1;
                  
                    be                    = 1'b1;
                    tx_dequeued_pkt_next  = 1'b1; 
                                                         
                    if (tlast_axi_o) begin
                         o_tlast    = 1'b1;
                         be         = 1'b1;    
                         state_next = IDLE;                       
                    end               
                end                 
              end
          endcase
      end
 
      always @(posedge clk156) begin
          if(areset_clk156) state <= IDLE;
          else      state <= state_next;         
      end 
 endmodule
