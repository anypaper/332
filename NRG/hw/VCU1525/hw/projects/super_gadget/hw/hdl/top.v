module top #(
	parameter PL_LINK_CAP_MAX_LINK_WIDTH          = 16,            // 1- X1; 2 - X2; 4 - X4; 8 - X8
	parameter PL_SIM_FAST_LINK_TRAINING           = "FALSE",      // Simulation Speedup
	parameter PL_LINK_CAP_MAX_LINK_SPEED          = 4,             // 1- GEN1; 2 - GEN2; 4 - GEN3
	parameter C_DATA_WIDTH                        = 512 ,
	parameter EXT_PIPE_SIM                        = "FALSE",  // This Parameter has effect on selecting Enable External PIPE Interface in GUI.
	parameter C_ROOT_PORT                         = "FALSE",      // PCIe block is in root port mode
	parameter C_DEVICE_NUMBER                     = 0,            // Device number for Root Port configurations only
	parameter C_M_AXIS_DATA_WIDTH=512,
	parameter C_S_AXIS_DATA_WIDTH=512,
	parameter C_M_AXIS_TUSER_WIDTH=128,
	parameter C_TUSER_WIDTH=128,
	parameter NF_C_S_AXI_DATA_WIDTH    = 32,    
	parameter NF_C_S_AXI_ADDR_WIDTH    = 32, 
	parameter AXIS_CCIX_RX_TDATA_WIDTH     = 256, 
	parameter AXIS_CCIX_TX_TDATA_WIDTH     = 256,
	parameter AXIS_CCIX_RX_TUSER_WIDTH     = 46,
	parameter AXIS_CCIX_TX_TUSER_WIDTH     = 46
)(	
    output [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pci_exp_txp,
    output [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0] pci_exp_txn,
    input [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_rxp,
    input [(PL_LINK_CAP_MAX_LINK_WIDTH - 1) : 0]  pci_exp_rxn,

    input sys_clk_p,
    input sys_clk_n,
    input sys_rst_n,
	input SYSCLK_P,
	input SYSCLK_N,

	input QSFP0_CLOCK_P,
	input QSFP0_CLOCK_N,
	input QSFP1_CLOCK_P,
	input QSFP1_CLOCK_N,

	/* QSFP port 0 */
`ifndef __BOARD_AU280__
	output QSFP0_FS0,
	output QSFP0_FS1,

	input  QSFP0_INTL,
	output QSFP0_LPMODE,
	input  QSFP0_MODPRSL,
	output QSFP0_MODSELL,
	output QSFP0_RESETL,
`endif
	output [3:0] QSFP0_TX_P,
	output [3:0] QSFP0_TX_N,
	input  [3:0] QSFP0_RX_P,
	input  [3:0] QSFP0_RX_N,
	
	/* QSFP port 1 */
`ifndef __BOARD_AU280__
	output QSFP1_FS0,
	output QSFP1_FS1,

	input  QSFP1_INTL,
	output QSFP1_LPMODE,
	input  QSFP1_MODPRSL,
	output QSFP1_MODSELL,
	output QSFP1_RESETL,
`endif

	output [3:0] QSFP1_TX_P,
	output [3:0] QSFP1_TX_N,
	input  [3:0] QSFP1_RX_P,
	input  [3:0] QSFP1_RX_N
);


/* clock infrastracture */
wire sysclk_ibufds;
IBUFDS IBUFDS_sysclk (
	.I(SYSCLK_P),
	.IB(SYSCLK_N),
	.O(sysclk_ibufds)
);

wire sys_clk;
reg clk_div = 1'b0;
always @ (posedge sysclk_ibufds)
	clk_div <= ~clk_div;
BUFG bufg_clk (
	.I  (clk_div),
	.O  (sys_clk)
);

reg [13:0] cold_counter = 14'd0;
reg sys_rst;
always @ (posedge sys_clk) begin
	if (cold_counter != 14'h3fff) begin
		cold_counter <= cold_counter + 14'd1;
		sys_rst <= 1'b1;
	end else begin
		sys_rst <= 1'b0;
	end
end

wire user_axi_aclk;
wire ref_aclk;
wire user_aresetn;
wire locked;
wire ref_aresetn = locked;
clk_wiz_1 u_clk_wiz_1 ( 
	.clk_out1(ref_aclk),        //  output        
	.reset   (~user_aresetn), //  input         
	.locked  (locked),     //  output        
	.clk_in1 (user_axi_aclk)      //  input         
);


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

wire [C_DATA_WIDTH-1:0]      axis_i_0_tdata;
wire                         axis_i_0_tvalid;
wire                         axis_i_0_tlast;
wire [C_TUSER_WIDTH-1:0]     axis_i_0_tuser;
wire [(C_DATA_WIDTH/8)-1:0]  axis_i_0_tkeep;
wire                         axis_i_0_tready;

wire [C_DATA_WIDTH-1:0]      axis_o_0_tdata;
wire                         axis_o_0_tvalid;
wire                         axis_o_0_tlast;
wire  [C_TUSER_WIDTH-1:0]    axis_o_0_tuser;
wire [(C_DATA_WIDTH/8)-1:0]  axis_o_0_tkeep;
wire                         axis_o_0_tready;

wire [C_DATA_WIDTH-1:0]      axis_i_1_tdata;
wire                         axis_i_1_tvalid;
wire                         axis_i_1_tlast;
wire [C_TUSER_WIDTH-1:0]     axis_i_1_tuser;
wire [C_DATA_WIDTH/8-1:0]    axis_i_1_tkeep;
wire                         axis_i_1_tready;

wire [C_DATA_WIDTH-1:0]      axis_o_1_tdata;
wire                         axis_o_1_tvalid;
wire                         axis_o_1_tlast;
wire  [C_TUSER_WIDTH-1:0]    axis_o_1_tuser;
wire [C_DATA_WIDTH/8-1:0]    axis_o_1_tkeep;
wire                         axis_o_1_tready;

//// AXIS DMA interfaces
//wire [255:0]   axis_dma_i_tdata ;
//wire [31:0]    axis_dma_i_tkeep ;
//wire           axis_dma_i_tlast ;
//wire           axis_dma_i_tready;
//wire [255:0]   axis_dma_i_tuser ;
//wire           axis_dma_i_tvalid;
//  
//wire [255:0]  axis_dma_o_tdata;
//wire [31:0]   axis_dma_o_tkeep;
//wire          axis_dma_o_tlast;
//wire          axis_dma_o_tready;
//wire [127:0]  axis_dma_o_tuser;
//wire          axis_dma_o_tvalid;

wire axi_aclk;
wire axi_aresetn;
wire axi_aclk_100;
wire axi_aresetn_100;
wire axi_aclk_200;
wire axi_aresetn_200;
nf_datapath #(
    //Slave AXI parameters
   .C_S_AXI_DATA_WIDTH    ( 32 ),          
   .C_S_AXI_ADDR_WIDTH    ( 32 ),          
   .C_BASEADDR            ( 32'h00000000),

    // Master AXI Stream Data Width
    .C_M_AXIS_DATA_WIDTH(512),
    .C_S_AXIS_DATA_WIDTH(512),
    .C_M_AXIS_TUSER_WIDTH(128),
    .C_S_AXIS_TUSER_WIDTH(128),
    .NUM_QUEUES(5)
) nf_datapath_0 (
    //Datapath clock
    .axis_aclk   (ref_aclk),
    .axis_resetn (ref_aresetn),
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
//    .s_axis_2_tdata  (),
//    .s_axis_2_tkeep  (),
//    .s_axis_2_tuser  (),
//    .s_axis_2_tvalid (),
//    .s_axis_2_tready (),
//    .s_axis_2_tlast  (),

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
//    .m_axis_2_tdata  (),
//    .m_axis_2_tkeep  (),
//    .m_axis_2_tuser  (),
//    .m_axis_2_tvalid (),
//    .m_axis_2_tready (1'b1),
//    .m_axis_2_tlast  (),
);

nf_qdma_ip  u_control_sub (
	.S0_AXI_AWADDR  (S0_AXI_AWADDR  ),
	.S0_AXI_AWVALID (S0_AXI_AWVALID ),
	.S0_AXI_WDATA   (S0_AXI_WDATA   ),
	.S0_AXI_WSTRB   (S0_AXI_WSTRB   ),
	.S0_AXI_WVALID  (S0_AXI_WVALID  ),
	.S0_AXI_BREADY  (S0_AXI_BREADY  ),
	.S0_AXI_ARADDR  (S0_AXI_ARADDR  ),
	.S0_AXI_ARVALID (S0_AXI_ARVALID ),
	.S0_AXI_RREADY  (S0_AXI_RREADY  ),
	.S0_AXI_ARREADY (S0_AXI_ARREADY ),
	.S0_AXI_RDATA   (S0_AXI_RDATA   ),
	.S0_AXI_RRESP   (S0_AXI_RRESP   ),
	.S0_AXI_RVALID  (S0_AXI_RVALID  ),
	.S0_AXI_WREADY  (S0_AXI_WREADY  ),
	.S0_AXI_BRESP   (S0_AXI_BRESP   ),
	.S0_AXI_BVALID  (S0_AXI_BVALID  ),
	.S0_AXI_AWREADY (S0_AXI_AWREADY ),
                                        
	.S1_AXI_AWADDR  (S1_AXI_AWADDR  ),
	.S1_AXI_AWVALID (S1_AXI_AWVALID ),
	.S1_AXI_WDATA   (S1_AXI_WDATA   ),
	.S1_AXI_WSTRB   (S1_AXI_WSTRB   ),
	.S1_AXI_WVALID  (S1_AXI_WVALID  ),
	.S1_AXI_BREADY  (S1_AXI_BREADY  ),
	.S1_AXI_ARADDR  (S1_AXI_ARADDR  ),
	.S1_AXI_ARVALID (S1_AXI_ARVALID ),
	.S1_AXI_RREADY  (S1_AXI_RREADY  ),
	.S1_AXI_ARREADY (S1_AXI_ARREADY ),
	.S1_AXI_RDATA   (S1_AXI_RDATA   ),
	.S1_AXI_RRESP   (S1_AXI_RRESP   ),
	.S1_AXI_RVALID  (S1_AXI_RVALID  ),
	.S1_AXI_WREADY  (S1_AXI_WREADY  ),
	.S1_AXI_BRESP   (S1_AXI_BRESP   ),
	.S1_AXI_BVALID  (S1_AXI_BVALID  ),
	.S1_AXI_AWREADY (S1_AXI_AWREADY ),
	                 
	.S2_AXI_AWADDR  (S2_AXI_AWADDR  ),
	.S2_AXI_AWVALID (S2_AXI_AWVALID ),
	.S2_AXI_WDATA   (S2_AXI_WDATA   ),
	.S2_AXI_WSTRB   (S2_AXI_WSTRB   ),
	.S2_AXI_WVALID  (S2_AXI_WVALID  ),
	.S2_AXI_BREADY  (S2_AXI_BREADY  ),
	.S2_AXI_ARADDR  (S2_AXI_ARADDR  ),
	.S2_AXI_ARVALID (S2_AXI_ARVALID ),
	.S2_AXI_RREADY  (S2_AXI_RREADY  ),
	.S2_AXI_ARREADY (S2_AXI_ARREADY ),
	.S2_AXI_RDATA   (S2_AXI_RDATA   ),
	.S2_AXI_RRESP   (S2_AXI_RRESP   ),
	.S2_AXI_RVALID  (S2_AXI_RVALID  ),
	.S2_AXI_WREADY  (S2_AXI_WREADY  ),
	.S2_AXI_BRESP   (S2_AXI_BRESP   ),
	.S2_AXI_BVALID  (S2_AXI_BVALID  ),
	.S2_AXI_AWREADY (S2_AXI_AWREADY ),

	.S3_AXI_AWADDR  (S3_AXI_AWADDR  ),
	.S3_AXI_AWVALID (S3_AXI_AWVALID ),
	.S3_AXI_WDATA   (S3_AXI_WDATA   ),
	.S3_AXI_WSTRB   (S3_AXI_WSTRB   ),
	.S3_AXI_WVALID  (S3_AXI_WVALID  ),
	.S3_AXI_BREADY  (S3_AXI_BREADY  ),
	.S3_AXI_ARADDR  (S3_AXI_ARADDR  ),
	.S3_AXI_ARVALID (S3_AXI_ARVALID ),
	.S3_AXI_RREADY  (S3_AXI_RREADY  ),
	.S3_AXI_ARREADY (S3_AXI_ARREADY ),
	.S3_AXI_RDATA   (S3_AXI_RDATA   ),
	.S3_AXI_RRESP   (S3_AXI_RRESP   ),
	.S3_AXI_RVALID  (S3_AXI_RVALID  ),
	.S3_AXI_WREADY  (S3_AXI_WREADY  ),
	.S3_AXI_BRESP   (S3_AXI_BRESP   ),
	.S3_AXI_BVALID  (S3_AXI_BVALID  ),
	.S3_AXI_AWREADY (S3_AXI_AWREADY ),

	.S4_AXI_AWADDR  (S4_AXI_AWADDR  ),
	.S4_AXI_AWVALID (S4_AXI_AWVALID ),
	.S4_AXI_WDATA   (S4_AXI_WDATA   ),
	.S4_AXI_WSTRB   (S4_AXI_WSTRB   ),
	.S4_AXI_WVALID  (S4_AXI_WVALID  ),
	.S4_AXI_BREADY  (S4_AXI_BREADY  ),
	.S4_AXI_ARADDR  (S4_AXI_ARADDR  ),
	.S4_AXI_ARVALID (S4_AXI_ARVALID ),
	.S4_AXI_RREADY  (S4_AXI_RREADY  ),
	.S4_AXI_ARREADY (S4_AXI_ARREADY ),
	.S4_AXI_RDATA   (S4_AXI_RDATA   ),
	.S4_AXI_RRESP   (S4_AXI_RRESP   ),
	.S4_AXI_RVALID  (S4_AXI_RVALID  ),
	.S4_AXI_WREADY  (S4_AXI_WREADY  ),
	.S4_AXI_BRESP   (S4_AXI_BRESP   ),
	.S4_AXI_BVALID  (S4_AXI_BVALID  ),
	.S4_AXI_AWREADY (S4_AXI_AWREADY ),

	.S5_AXI_AWADDR  (S5_AXI_AWADDR  ),
	.S5_AXI_AWVALID (S5_AXI_AWVALID ),
	.S5_AXI_WDATA   (S5_AXI_WDATA   ),
	.S5_AXI_WSTRB   (S5_AXI_WSTRB   ),
	.S5_AXI_WVALID  (S5_AXI_WVALID  ),
	.S5_AXI_BREADY  (S5_AXI_BREADY  ),
	.S5_AXI_ARADDR  (S5_AXI_ARADDR  ),
	.S5_AXI_ARVALID (S5_AXI_ARVALID ),
	.S5_AXI_RREADY  (S5_AXI_RREADY  ),
	.S5_AXI_ARREADY (S5_AXI_ARREADY ),
	.S5_AXI_RDATA   (S5_AXI_RDATA   ),
	.S5_AXI_RRESP   (S5_AXI_RRESP   ),
	.S5_AXI_RVALID  (S5_AXI_RVALID  ),
	.S5_AXI_WREADY  (S5_AXI_WREADY  ),
	.S5_AXI_BRESP   (S5_AXI_BRESP   ),
	.S5_AXI_BVALID  (S5_AXI_BVALID  ),
	.S5_AXI_AWREADY (S5_AXI_AWREADY ),

	.axi_aclk    (user_axi_aclk),
	.axi_aresetn (user_aresetn),
	.axi_aclk_100    (axi_aclk_100),
	.axi_aresetn_100 (axi_aresetn_100),
	.pci_exp_txp (pci_exp_txp),
	.pci_exp_txn (pci_exp_txn),
	.pci_exp_rxp (pci_exp_rxp),
	.pci_exp_rxn (pci_exp_rxn),

	.sys_clk_p (sys_clk_p),
	.sys_clk_n (sys_clk_n),
	.sys_rst_n (sys_rst_n)
 );


nf_cmac_interface_0_ip u_nf_cmac_interface_0 (
	.axis_aclk    (ref_aclk),
	.axis_resetn  (ref_aresetn),

	.s_axis_tdata (axis_o_0_tdata ),
	.s_axis_tkeep (axis_o_0_tkeep ),
	.s_axis_tuser (axis_o_0_tuser ),
	.s_axis_tvalid(axis_o_0_tvalid),
	.s_axis_tready(axis_o_0_tready),
	.s_axis_tlast (axis_o_0_tlast ),

	.m_axis_tdata (axis_i_0_tdata ),
	.m_axis_tkeep (axis_i_0_tkeep ),
	.m_axis_tuser (axis_i_0_tuser ),
	.m_axis_tvalid(axis_i_0_tvalid),
	.m_axis_tready(axis_i_0_tready),
	.m_axis_tlast (axis_i_0_tlast ),

	.QSFP_CLOCK_P (QSFP0_CLOCK_P),
	.QSFP_CLOCK_N (QSFP0_CLOCK_N),

	.QSFP_FS0     (QSFP0_FS0    ),
	.QSFP_FS1     (QSFP0_FS1    ),
                                
	.QSFP_INTL    (QSFP0_INTL   ),
	.QSFP_LPMODE  (QSFP0_LPMODE ),
	.QSFP_MODPRSL (QSFP0_MODPRSL),
	.QSFP_MODSELL (QSFP0_MODSELL),
	.QSFP_RESETL  (QSFP0_RESETL ),
                                
	.QSFP_TX_P    (QSFP0_TX_P   ),
	.QSFP_TX_N    (QSFP0_TX_N   ),
	.QSFP_RX_P    (QSFP0_RX_P   ),
	.QSFP_RX_N    (QSFP0_RX_N   ),
	
	.interface_number(8'b0000_0001),
	.sys_clk      (sys_clk),
	.sys_rst      (sys_rst)
);

nf_cmac_interface_1_ip u_nf_cmac_interface_1 (
	.axis_aclk    (ref_aclk),
	.axis_resetn  (ref_aresetn),

	.s_axis_tdata (axis_o_1_tdata ),
	.s_axis_tkeep (axis_o_1_tkeep ),
	.s_axis_tuser (axis_o_1_tuser ),
	.s_axis_tvalid(axis_o_1_tvalid),
	.s_axis_tready(axis_o_1_tready),
	.s_axis_tlast (axis_o_1_tlast ),

	.m_axis_tdata (axis_i_1_tdata ),
	.m_axis_tkeep (axis_i_1_tkeep ),
	.m_axis_tuser (axis_i_1_tuser ),
	.m_axis_tvalid(axis_i_1_tvalid),
	.m_axis_tready(axis_i_1_tready),
	.m_axis_tlast (axis_i_1_tlast ),

	.QSFP_CLOCK_P (QSFP1_CLOCK_P),
	.QSFP_CLOCK_N (QSFP1_CLOCK_N),

	.QSFP_FS0     (QSFP1_FS0    ),
	.QSFP_FS1     (QSFP1_FS1    ),

	.QSFP_INTL    (QSFP1_INTL   ),
	.QSFP_LPMODE  (QSFP1_LPMODE ),
	.QSFP_MODPRSL (QSFP1_MODPRSL),
	.QSFP_MODSELL (QSFP1_MODSELL),
	.QSFP_RESETL  (QSFP1_RESETL ),
                                
	.QSFP_TX_P    (QSFP1_TX_P   ),
	.QSFP_TX_N    (QSFP1_TX_N   ),
	.QSFP_RX_P    (QSFP1_RX_P   ),
	.QSFP_RX_N    (QSFP1_RX_N   ),
	
	.interface_number(8'b0000_0100),
	.sys_clk      (sys_clk),
	.sys_rst      (sys_rst)
);

endmodule 

