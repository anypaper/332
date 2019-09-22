module tb_top ();

  parameter C_DATA_WIDTH                        = 512 ;
parameter C_M_AXIS_DATA_WIDTH=512;
parameter C_S_AXIS_DATA_WIDTH=512;
parameter C_M_AXIS_TUSER_WIDTH=128;
parameter C_TUSER_WIDTH=128;
localparam NF_C_S_AXI_DATA_WIDTH    = 32;    
localparam NF_C_S_AXI_ADDR_WIDTH    = 32; 

localparam CORE_PERIOD = 7.142;
localparam AXI_PERIOD  = 10.000;

reg axi_aclk;
wire axi_aresetn;
reg axi_aclk_100;
wire axi_aresetn_100;
initial begin
	axi_aclk = 1'b0;
	#(CORE_PERIOD/2);
	forever
		#(CORE_PERIOD/2) axi_aclk = ~axi_aclk;
end 

initial begin
	axi_aclk_100 = 1'b0;
	#(AXI_PERIOD/2);
	forever
		#(AXI_PERIOD/2) axi_aclk_100 = ~axi_aclk_100;
end 

reg [13:0] cold_counter = 14'd0;
reg        sys_rst;
always @(posedge axi_aclk) 
	if (cold_counter != 14'h0009) begin
		cold_counter <= cold_counter + 14'd1;
		sys_rst <= 1'b1;
	end else
		sys_rst <= 1'b0;

reg [13:0] f_cold_counter = 14'd0;
reg        f_sys_rst;
always @(posedge axi_aclk_100) 
	if (f_cold_counter != 14'h0009) begin
		f_cold_counter <= f_cold_counter + 14'd1;
		f_sys_rst <= 1'b1;
	end else
		f_sys_rst <= 1'b0;
assign axi_aresetn = !sys_rst;
assign axi_aresetn_100 = !f_sys_rst;

wire  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]     S0_AXI_AWADDR;
wire                                S0_AXI_AWVALID;
wire  [NF_C_S_AXI_DATA_WIDTH-1 : 0]     S0_AXI_WDATA;
wire  [NF_C_S_AXI_DATA_WIDTH/8-1 : 0]   S0_AXI_WSTRB;
wire                                S0_AXI_WVALID;
wire                                S0_AXI_BREADY;
wire  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]     S0_AXI_ARADDR;
wire                                 S0_AXI_ARVALID;
wire                                 S0_AXI_RREADY;
wire                                 S0_AXI_ARREADY;
wire  [NF_C_S_AXI_DATA_WIDTH-1 : 0]     S0_AXI_RDATA;
wire  [1 : 0]                        S0_AXI_RRESP;
wire                                 S0_AXI_RVALID;
wire                                 S0_AXI_WREADY;
wire  [1 :0]                         S0_AXI_BRESP;
wire                                 S0_AXI_BVALID;
wire                                 S0_AXI_AWREADY;

wire  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]     S1_AXI_AWADDR;
wire                                 S1_AXI_AWVALID;
wire  [NF_C_S_AXI_DATA_WIDTH-1 : 0]     S1_AXI_WDATA;
wire  [NF_C_S_AXI_DATA_WIDTH/8-1 : 0]   S1_AXI_WSTRB;
wire                                 S1_AXI_WVALID;
wire                                 S1_AXI_BREADY;
wire  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]     S1_AXI_ARADDR;
wire                                 S1_AXI_ARVALID;
wire                                 S1_AXI_RREADY;
wire                                 S1_AXI_ARREADY;
wire  [NF_C_S_AXI_DATA_WIDTH-1 : 0]     S1_AXI_RDATA;
wire  [1 : 0]                        S1_AXI_RRESP;
wire                                 S1_AXI_RVALID;
wire                                 S1_AXI_WREADY;
wire  [1 :0]                         S1_AXI_BRESP;
wire                                 S1_AXI_BVALID;
wire                                 S1_AXI_AWREADY;

wire  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]  S2_AXI_AWADDR;
wire                                 S2_AXI_AWVALID;
wire  [NF_C_S_AXI_DATA_WIDTH-1 : 0]  S2_AXI_WDATA;
wire  [NF_C_S_AXI_DATA_WIDTH/8-1 : 0]S2_AXI_WSTRB;
wire                                 S2_AXI_WVALID;
wire                                 S2_AXI_BREADY;
wire  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]  S2_AXI_ARADDR;
wire                                 S2_AXI_ARVALID;
wire                                 S2_AXI_RREADY;
wire                                 S2_AXI_ARREADY;
wire  [NF_C_S_AXI_DATA_WIDTH-1 : 0]  S2_AXI_RDATA;
wire  [1 : 0]                        S2_AXI_RRESP;
wire                                 S2_AXI_RVALID;
wire                                 S2_AXI_WREADY;
wire  [1 :0]                         S2_AXI_BRESP;
wire                                 S2_AXI_BVALID;
wire                                 S2_AXI_AWREADY;

wire  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]  S3_AXI_AWADDR;
wire                                 S3_AXI_AWVALID;
wire  [NF_C_S_AXI_DATA_WIDTH-1 : 0]  S3_AXI_WDATA;
wire  [NF_C_S_AXI_DATA_WIDTH/8-1 : 0]S3_AXI_WSTRB;
wire                                 S3_AXI_WVALID;
wire                                 S3_AXI_BREADY;
wire  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]  S3_AXI_ARADDR;
wire                                 S3_AXI_ARVALID;
wire                                 S3_AXI_RREADY;
wire                                 S3_AXI_ARREADY;
wire  [NF_C_S_AXI_DATA_WIDTH-1 : 0]  S3_AXI_RDATA;
wire  [1 : 0]                        S3_AXI_RRESP;
wire                                 S3_AXI_RVALID;
wire                                 S3_AXI_WREADY;
wire  [1 :0]                         S3_AXI_BRESP;
wire                                 S3_AXI_BVALID;
wire                                 S3_AXI_AWREADY;

wire  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]  S4_AXI_AWADDR;
wire                                 S4_AXI_AWVALID;
wire  [NF_C_S_AXI_DATA_WIDTH-1 : 0]  S4_AXI_WDATA;
wire  [NF_C_S_AXI_DATA_WIDTH/8-1 : 0]S4_AXI_WSTRB;
wire                                 S4_AXI_WVALID;
wire                                 S4_AXI_BREADY;
wire  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]  S4_AXI_ARADDR;
wire                                 S4_AXI_ARVALID;
wire                                 S4_AXI_RREADY;
wire                                 S4_AXI_ARREADY;
wire  [NF_C_S_AXI_DATA_WIDTH-1 : 0]  S4_AXI_RDATA;
wire  [1 : 0]                        S4_AXI_RRESP;
wire                                 S4_AXI_RVALID;
wire                                 S4_AXI_WREADY;
wire  [1 :0]                         S4_AXI_BRESP;
wire                                 S4_AXI_BVALID;
wire                                 S4_AXI_AWREADY;

wire  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]  S5_AXI_AWADDR;
wire                                 S5_AXI_AWVALID;
wire  [NF_C_S_AXI_DATA_WIDTH-1 : 0]  S5_AXI_WDATA;
wire  [NF_C_S_AXI_DATA_WIDTH/8-1 : 0]S5_AXI_WSTRB;
wire                                 S5_AXI_WVALID;
wire                                 S5_AXI_BREADY;
wire  [NF_C_S_AXI_ADDR_WIDTH-1 : 0]  S5_AXI_ARADDR;
wire                                 S5_AXI_ARVALID;
wire                                 S5_AXI_RREADY;
wire                                 S5_AXI_ARREADY;
wire  [NF_C_S_AXI_DATA_WIDTH-1 : 0]  S5_AXI_RDATA;
wire  [1 : 0]                        S5_AXI_RRESP;
wire                                 S5_AXI_RVALID;
wire                                 S5_AXI_WREADY;
wire  [1 :0]                         S5_AXI_BRESP;
wire                                 S5_AXI_BVALID;
wire                                 S5_AXI_AWREADY;

reg [C_DATA_WIDTH-1:0]      axis_i_0_tdata;
reg                         axis_i_0_tvalid;
reg                         axis_i_0_tlast;
reg [C_TUSER_WIDTH-1:0]     axis_i_0_tuser;
reg [(C_DATA_WIDTH/8)-1:0]  axis_i_0_tkeep;
wire                        axis_i_0_tready;

wire [C_DATA_WIDTH-1:0]      axis_o_0_tdata;
wire                         axis_o_0_tvalid;
wire                         axis_o_0_tlast;
wire  [C_TUSER_WIDTH-1:0]    axis_o_0_tuser;
wire [(C_DATA_WIDTH/8)-1:0]  axis_o_0_tkeep;
reg                        axis_o_0_tready;

reg [C_DATA_WIDTH-1:0]     axis_i_1_tdata;
reg                        axis_i_1_tvalid;
reg                        axis_i_1_tlast;
reg [C_TUSER_WIDTH-1:0]    axis_i_1_tuser;
reg [C_DATA_WIDTH/8-1:0]   axis_i_1_tkeep;
wire                         axis_i_1_tready;

wire [C_DATA_WIDTH-1:0]     axis_o_1_tdata;
wire                        axis_o_1_tvalid;
wire                        axis_o_1_tlast;
wire  [C_TUSER_WIDTH-1:0]   axis_o_1_tuser;
wire [C_DATA_WIDTH/8-1:0]   axis_o_1_tkeep;
reg                         axis_o_1_tready;

nf_datapath #(
    //Slave AXI parameters
   .C_S_AXI_DATA_WIDTH    ( 32 ),          
   .C_S_AXI_ADDR_WIDTH    ( 32 ),          
   .C_BASEADDR            ( 32'h00000000),

    // Master AXI Stream Data Width
    .C_M_AXIS_DATA_WIDTH(512),
    .C_S_AXIS_DATA_WIDTH(512),
    .C_M_AXIS_TUSER_WIDTH(128),
    .C_S_AXIS_TUSER_WIDTH(128)
//    .NUM_QUEUES(5)
) nf_datapath_0 (
    //Datapath clock
    .axis_aclk   (axi_aclk),
    .axis_resetn (axi_aresetn),
    //Registers clock
    .axi_aclk    (axi_aclk_100),
    .axi_resetn  (axi_aresetn_100),

    // Slave AXI Ports
    .S0_AXI_AWADDR  (S0_AXI_AWADDR ),
    .S0_AXI_AWVALID (S0_AXI_AWVALID),
    .S0_AXI_WDATA   (S0_AXI_WDATA  ),
    .S0_AXI_WSTRB   (S0_AXI_WSTRB  ),
    .S0_AXI_WVALID  (S0_AXI_WVALID ),
    .S0_AXI_BREADY  (S0_AXI_BREADY ),
    .S0_AXI_ARADDR  (S0_AXI_ARADDR ),
    .S0_AXI_ARVALID (S0_AXI_ARVALID),
    .S0_AXI_RREADY  (S0_AXI_RREADY ),
    .S0_AXI_ARREADY (S0_AXI_ARREADY),
    .S0_AXI_RDATA   (S0_AXI_RDATA  ),
    .S0_AXI_RRESP   (S0_AXI_RRESP  ),
    .S0_AXI_RVALID  (S0_AXI_RVALID ),
    .S0_AXI_WREADY  (S0_AXI_WREADY ),
    .S0_AXI_BRESP   (S0_AXI_BRESP  ),
    .S0_AXI_BVALID  (S0_AXI_BVALID ),
    .S0_AXI_AWREADY (S0_AXI_AWREADY),
  
    .S1_AXI_AWADDR  (S1_AXI_AWADDR ),
    .S1_AXI_AWVALID (S1_AXI_AWVALID),
    .S1_AXI_WDATA   (S1_AXI_WDATA  ),
    .S1_AXI_WSTRB   (S1_AXI_WSTRB  ),
    .S1_AXI_WVALID  (S1_AXI_WVALID ),
    .S1_AXI_BREADY  (S1_AXI_BREADY ),
    .S1_AXI_ARADDR  (S1_AXI_ARADDR ),
    .S1_AXI_ARVALID (S1_AXI_ARVALID),
    .S1_AXI_RREADY  (S1_AXI_RREADY ),
    .S1_AXI_ARREADY (S1_AXI_ARREADY),
    .S1_AXI_RDATA   (S1_AXI_RDATA  ),
    .S1_AXI_RRESP   (S1_AXI_RRESP  ),
    .S1_AXI_RVALID  (S1_AXI_RVALID ),
    .S1_AXI_WREADY  (S1_AXI_WREADY ),
    .S1_AXI_BRESP   (S1_AXI_BRESP  ),
    .S1_AXI_BVALID  (S1_AXI_BVALID ),
    .S1_AXI_AWREADY (S1_AXI_AWREADY),

    .S2_AXI_AWADDR  (S2_AXI_AWADDR ),
    .S2_AXI_AWVALID (S2_AXI_AWVALID),
    .S2_AXI_WDATA   (S2_AXI_WDATA  ),
    .S2_AXI_WSTRB   (S2_AXI_WSTRB  ),
    .S2_AXI_WVALID  (S2_AXI_WVALID ),
    .S2_AXI_BREADY  (S2_AXI_BREADY ),
    .S2_AXI_ARADDR  (S2_AXI_ARADDR ),
    .S2_AXI_ARVALID (S2_AXI_ARVALID),
    .S2_AXI_RREADY  (S2_AXI_RREADY ),
    .S2_AXI_ARREADY (S2_AXI_ARREADY),
    .S2_AXI_RDATA   (S2_AXI_RDATA  ),
    .S2_AXI_RRESP   (S2_AXI_RRESP  ),
    .S2_AXI_RVALID  (S2_AXI_RVALID ),
    .S2_AXI_WREADY  (S2_AXI_WREADY ),
    .S2_AXI_BRESP   (S2_AXI_BRESP  ),
    .S2_AXI_BVALID  (S2_AXI_BVALID ),
    .S2_AXI_AWREADY (S2_AXI_AWREADY),

    .S3_AXI_AWADDR  (S3_AXI_AWADDR ),
    .S3_AXI_AWVALID (S3_AXI_AWVALID),
    .S3_AXI_WDATA   (S3_AXI_WDATA  ),
    .S3_AXI_WSTRB   (S3_AXI_WSTRB  ),
    .S3_AXI_WVALID  (S3_AXI_WVALID ),
    .S3_AXI_BREADY  (S3_AXI_BREADY ),
    .S3_AXI_ARADDR  (S3_AXI_ARADDR ),
    .S3_AXI_ARVALID (S3_AXI_ARVALID),
    .S3_AXI_RREADY  (S3_AXI_RREADY ),
    .S3_AXI_ARREADY (S3_AXI_ARREADY),
    .S3_AXI_RDATA   (S3_AXI_RDATA  ),
    .S3_AXI_RRESP   (S3_AXI_RRESP  ),
    .S3_AXI_RVALID  (S3_AXI_RVALID ),
    .S3_AXI_WREADY  (S3_AXI_WREADY ),
    .S3_AXI_BRESP   (S3_AXI_BRESP  ),
    .S3_AXI_BVALID  (S3_AXI_BVALID ),
    .S3_AXI_AWREADY (S3_AXI_AWREADY),

    .S4_AXI_AWADDR  (S4_AXI_AWADDR ),
    .S4_AXI_AWVALID (S4_AXI_AWVALID),
    .S4_AXI_WDATA   (S4_AXI_WDATA  ),
    .S4_AXI_WSTRB   (S4_AXI_WSTRB  ),
    .S4_AXI_WVALID  (S4_AXI_WVALID ),
    .S4_AXI_BREADY  (S4_AXI_BREADY ),
    .S4_AXI_ARADDR  (S4_AXI_ARADDR ),
    .S4_AXI_ARVALID (S4_AXI_ARVALID),
    .S4_AXI_RREADY  (S4_AXI_RREADY ),
    .S4_AXI_ARREADY (S4_AXI_ARREADY),
    .S4_AXI_RDATA   (S4_AXI_RDATA  ),
    .S4_AXI_RRESP   (S4_AXI_RRESP  ),
    .S4_AXI_RVALID  (S4_AXI_RVALID ),
    .S4_AXI_WREADY  (S4_AXI_WREADY ),
    .S4_AXI_BRESP   (S4_AXI_BRESP  ),
    .S4_AXI_BVALID  (S4_AXI_BVALID ),
    .S4_AXI_AWREADY (S4_AXI_AWREADY),

    .S5_AXI_AWADDR  (S5_AXI_AWADDR ),
    .S5_AXI_AWVALID (S5_AXI_AWVALID),
    .S5_AXI_WDATA   (S5_AXI_WDATA  ),
    .S5_AXI_WSTRB   (S5_AXI_WSTRB  ),
    .S5_AXI_WVALID  (S5_AXI_WVALID ),
    .S5_AXI_BREADY  (S5_AXI_BREADY ),
    .S5_AXI_ARADDR  (S5_AXI_ARADDR ),
    .S5_AXI_ARVALID (S5_AXI_ARVALID),
    .S5_AXI_RREADY  (S5_AXI_RREADY ),
    .S5_AXI_ARREADY (S5_AXI_ARREADY),
    .S5_AXI_RDATA   (S5_AXI_RDATA  ),
    .S5_AXI_RRESP   (S5_AXI_RRESP  ),
    .S5_AXI_RVALID  (S5_AXI_RVALID ),
    .S5_AXI_WREADY  (S5_AXI_WREADY ),
    .S5_AXI_BRESP   (S5_AXI_BRESP  ),
    .S5_AXI_BVALID  (S5_AXI_BVALID ),
    .S5_AXI_AWREADY (S5_AXI_AWREADY),

    // Slave Stream Ports (interface from Rx queues)
    .s_axis_0_tdata  (axis_i_0_tdata ),
    .s_axis_0_tkeep  (axis_i_0_tkeep ),
    .s_axis_0_tuser  (axis_i_0_tuser ),
    .s_axis_0_tvalid (axis_i_0_tvalid),
    .s_axis_0_tready (axis_i_0_tready),
    .s_axis_0_tlast  (axis_i_0_tlast ),
    .s_axis_1_tdata  (axis_i_1_tdata ),
    .s_axis_1_tkeep  (axis_i_1_tkeep ),
    .s_axis_1_tuser  (axis_i_1_tuser ),
    .s_axis_1_tvalid (axis_i_1_tvalid),
    .s_axis_1_tready (axis_i_1_tready),
    .s_axis_1_tlast  (axis_i_1_tlast ),

    // Master Stream Ports (interface to TX queues)
    .m_axis_0_tdata  (axis_o_0_tdata ),
    .m_axis_0_tkeep  (axis_o_0_tkeep ),
    .m_axis_0_tuser  (axis_o_0_tuser ),
    .m_axis_0_tvalid (axis_o_0_tvalid),
    .m_axis_0_tready (axis_o_0_tready),
    .m_axis_0_tlast  (axis_o_0_tlast ),
    .m_axis_1_tdata  (axis_o_1_tdata ),
    .m_axis_1_tkeep  (axis_o_1_tkeep ),
    .m_axis_1_tuser  (axis_o_1_tuser ),
    .m_axis_1_tvalid (axis_o_1_tvalid),
    .m_axis_1_tready (axis_o_1_tready),
    .m_axis_1_tlast  (axis_o_1_tlast )
);

/*
 *   Task
 */ 

reg [31:0] sys_cnt = 0;
reg [31:0] pkt_cnt = 0;
always @ (posedge axi_aclk)
	sys_cnt <= sys_cnt + 1;

task waitaclk;
begin
	@(posedge axi_aclk);
end
endtask

task waitclk;
input integer max;
integer i;
begin
	for (i = 0; i < max; i = i + 1)
		waitaclk;
end
endtask

task send_pkt;
input [47:0] dst_mac;
input [47:0] src_mac;
input [8-1:0] src_port;
begin
	$display("Clk[%8d]\tSENDS PKT[%02d]\tDST MAC[0x%08x]\tSRC MAC[0x%08x]\tSRC Port[0x%02x]", 
		sys_cnt, pkt_cnt, dst_mac, src_mac, src_port);
	wait (axis_i_0_tready); 
	axis_i_0_tdata  =  {416'hAABBCCDDEEFFAABBCCDDEEFF_0101A8C0665544332211010005060708010206080101A8C066554433221101000506070801020608, src_mac, dst_mac};
	axis_i_0_tuser  = {96'h0, 8'hff, src_port ,16'h0030};
	axis_i_0_tkeep  = ~32'h0;
	axis_i_0_tvalid = 1;
	axis_i_0_tlast  = 1;

	waitaclk;
	axis_i_0_tvalid = 0;
	axis_i_0_tlast = 1;
	pkt_cnt = pkt_cnt + 1;
end
endtask

//always @ (posedge sys_clk) begin
//	if (u_nf_axis_converter.nf_converter.in_fifo_nearly_full)
//		$display("Clk[%8d] in_fifo_nearly_full", sys_cnt);
//end


/*
 *   senario
 */ 
integer const_latency;
integer i;

initial begin
	// 1. Write Operation is required 14 cc, so that 
	// for read operation for a last written entry, 
	// variable const_latency is required more than 15 cc.
	// Support this, small cache including 16 entreis is needed.
	// 2. Duplication write occurs when const_latency is 10.
	// In this case, CAM entries are wasted for equivalent contents.
	const_latency = 1;
	$dumpfile("./test.vcd");
	$dumpvars(0, tb_top);

	$display("Simulation begins.");
	$display("================================================");


	waitclk(400);

	axis_o_0_tready = 1;
	axis_o_1_tready = 1;

	// Packet #1  Write: MAC 665544332210 is port 0x01
	send_pkt(48'h665544332219, 48'h665544332210, 8'h01);
	waitclk(const_latency);

	// Packet #2
	send_pkt(48'h665544332210, 48'h665544332219, 8'h10);
	waitclk(const_latency);

	// Packet #3
	send_pkt(48'h665544332219, 48'h665544332210, 8'h01);
	waitclk(const_latency);

	// Packet #4
	send_pkt(48'h665544332219, 48'h66554433221c, 8'h04);
	waitclk(const_latency);

	// Packet #6
	send_pkt(48'h66554433221c, 48'h665544332210, 8'h01);
	waitclk(const_latency);

	// Packet #7
	send_pkt(48'h665544332219, 48'h665544332111, 8'h02);
	waitclk(const_latency);

	// Packet #8
	send_pkt(48'h665544332219, 48'h665544332112, 8'h03);
	waitclk(const_latency);

	// Packet #9
	send_pkt(48'h665544332219, 48'h665544332113, 8'h04);
	waitclk(const_latency);

	// Packet #10
	send_pkt(48'h665544332219, 48'h665544332114, 8'h05);
	waitclk(const_latency);

	// Packet #11
	send_pkt(48'h665544332219, 48'h665544332115, 8'h06);
	waitclk(const_latency);

	// Packet #12
	send_pkt(48'h665544332219, 48'h665544332116, 8'h07);
	waitclk(const_latency);

	// Packet #13
	send_pkt(48'h665544332219, 48'h665544332117, 8'h08);
	waitclk(const_latency);

	// Packet #14
	send_pkt(48'h665544332219, 48'h665544332118, 8'h08);
	waitclk(const_latency);

	// Packet #15
	send_pkt(48'h665544332219, 48'h665544332119, 8'h0a);
	waitclk(const_latency);

	// Packet #16
	send_pkt(48'h665544332110, 48'h665544332219, 8'h10);
	waitclk(const_latency);
                               
	// Packet #17
	send_pkt(48'h665544332111, 48'h665544332219, 8'h10);
	waitclk(const_latency);
                               
	// Packet #18
	send_pkt(48'h665544332112, 48'h665544332219, 8'h10);
	waitclk(const_latency);
                               
	// Packet #19
	send_pkt(48'h665544332113, 48'h665544332219, 8'h10);
	waitclk(const_latency);
                               
	// Packet #20
	send_pkt(48'h665544332114, 48'h665544332219, 8'h10);
	waitclk(const_latency);
                               
	// Packet #21
	send_pkt(48'h665544332115, 48'h665544332219, 8'h10);
	waitclk(const_latency);
                               
	// Packet #22
	send_pkt(48'h665544332116, 48'h665544332219, 8'h10);
	waitclk(const_latency);
                               
	// Packet #23
	send_pkt(48'h665544332117, 48'h665544332219, 8'h10);
	waitclk(const_latency);
                               
	// Packet #24
	send_pkt(48'h665544332118, 48'h665544332219, 8'h10);
	waitclk(const_latency);
                               
	// Packet #25
	send_pkt(48'h665544332119, 48'h665544332219, 8'h10);
	waitclk(const_latency);
                               
	// Packet #26
	send_pkt(48'h665544332110, 48'h665544332219, 8'h10);
	waitclk(const_latency);

	// Packet #27
	send_pkt(48'h665544332110, 48'h665544332222, 8'h12);
	waitclk(const_latency);

	// Packet #28
	send_pkt(48'h665544332110, 48'h665544332223, 8'h13);
	waitclk(const_latency);

	// Packet #29
	send_pkt(48'h665544332110, 48'h665544332224, 8'h14);
	waitclk(const_latency);

	// Packet #30
	send_pkt(48'h665544332110, 48'h665544332225, 8'h15);
	waitclk(const_latency);

	// Packet #31
	send_pkt(48'h665544332110, 48'h665544332226, 8'h16);
	waitclk(const_latency);

	// Packet #32
	send_pkt(48'h665544332110, 48'h665544332227, 8'h17);
	waitclk(const_latency);

	// Packet #33
	send_pkt(48'h665544332110, 48'h665544332228, 8'h18);
	waitclk(const_latency);

	// Packet #34
	send_pkt(48'h665544332110, 48'h665544332229, 8'h19);
	waitclk(const_latency);

	// Packet #35
	send_pkt(48'h665544332110, 48'h66554433222a, 8'h1a);
	waitclk(const_latency);

	// Packet #36
	send_pkt(48'h665544332110, 48'h66554433222b, 8'h1b);
	waitclk(const_latency);

	// Packet #37
	send_pkt(48'h665544332110, 48'h66554433221c, 8'h1c);
	waitclk(const_latency);

	// Packet #38
	send_pkt(48'h665544332110, 48'h66554433221d, 8'h1d);
	waitclk(const_latency);

	// Packet #39
	send_pkt(48'h665544332110, 48'h66554433221e, 8'h1e);
	waitclk(const_latency);

	// Packet #40
	send_pkt(48'h665544332110, 48'h66554433221f, 8'h1f);
	waitclk(const_latency);

	for (i = 0; i < 10000; i = i + 1) begin
	// Packet #40
		send_pkt(48'h665544332110, 48'h66554433221f, 8'h1f);
		waitclk(const_latency);
	end

	waitclk(100);
	$finish;
end
endmodule
