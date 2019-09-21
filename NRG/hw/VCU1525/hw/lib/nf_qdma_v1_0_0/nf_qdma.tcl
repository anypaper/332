#### Change design settings here #######
set design nf_qdma
set top xilinx_qdma_pcie_ep
set device xcvu9p-fsgd2104-2L-e
set board  xilinx.com:vcu1525:part0:1.3
set proj_dir ./ip_proj
set ip_version 1.00
set lib_name NetFPGA
#####################################
# Project Settings
#####################################
set ip_name qdma_0
set axi_ip_name axi_clock_converter_0
set clk_ip_name clk_wiz_0
create_project -name ${design} -force -dir "./${proj_dir}" -part ${device} -ip
set_property source_mgmt_mode All [current_project]  
set_property board_part ${board} [current_project]
set_property top ${top} [current_fileset]
set_property ip_repo_paths $::env(SUME_FOLDER)/hw/lib  [current_fileset]
puts "Creating Input Arbiter IP"
#####################################
# Project Structure & IP Build
#####################################
source "./control_sub.tcl"
make_wrapper -files [get_files ./ip_proj/nf_qdma.srcs/sources_1/bd/design_1/design_1.bd] -top
#read_bd "./ip_proj/nf_qdma.srcs/sources_1/bd/design_1/design_1.bd"
read_verilog "./ip_proj/nf_qdma.srcs/sources_1/bd/design_1/hdl/design_1_wrapper.v"

read_verilog -sv "xilinx/axi_st_module.sv"
#read_verilog "xilinx/pcie_4_0_rp.v"
#read_verilog "xilinx/pci_exp_expect_tasks.vh"
read_verilog -sv "xilinx/qdma_app.sv"
read_verilog -sv "xilinx/qdma_fifo_lut.sv"
read_verilog -sv "xilinx/qdma_lpbk.sv"
read_verilog -sv "xilinx/qdma_stm_c2h_stub.sv"
read_verilog "xilinx/qdma_stm_defines.svh"
read_verilog -sv "xilinx/qdma_stm_h2c_stub.sv"
read_verilog -sv "xilinx/qdma_stm_lpbk.sv"
#read_verilog "xilinx/sample_tests_sriov.vh"
#read_verilog "xilinx/sample_tests.vh"
read_verilog -sv "xilinx/st_c2h.sv"
read_verilog -sv "xilinx/st_h2c.sv"
#read_verilog "xilinx/sys_clk_gen_ds.v"
#read_verilog "xilinx/sys_clk_gen.v"
#read_verilog "xilinx/tests.vh"
read_verilog -sv "xilinx/user_control.sv"
#read_verilog "xilinx/usp_pci_exp_usrapp_cfg.v"
#read_verilog "xilinx/usp_pci_exp_usrapp_com.v"
#read_verilog "xilinx/usp_pci_exp_usrapp_rx.v"
#read_verilog "xilinx/usp_pci_exp_usrapp_tx_sriov.sv"
#read_verilog "xilinx/usp_pci_exp_usrapp_tx.v"
#read_verilog "xilinx/xilinx_pcie_uscale_rp.v"
read_verilog -sv "xilinx/xilinx_qdma_pcie_ep.sv"
#read_verilog "xilinx/xp4_usp_smsw_model_core_top.v"

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
ipx::package_project

read_ip "xilinx/blk_mem_gen_0.xci"

create_ip -name qdma -vendor xilinx.com -library ip -version 3.0 -module_name ${ip_name} -dir ./${proj_dir}
set_property -dict [list CONFIG.mode_selection {Advanced} \
	CONFIG.barlite_mb_pf0 {1}                 \
	CONFIG.barlite_mb_pf1 {1}                 \
	CONFIG.barlite_mb_pf2 {1}                 \
	CONFIG.barlite_mb_pf3 {1}                 \
	CONFIG.tl_pf_enable_reg {4}               \
	CONFIG.testname {st}                      \
	CONFIG.SRIOV_CAP_ENABLE {true}            \
	CONFIG.MAILBOX_ENABLE {true}              \
	CONFIG.flr_enable {true}                  \
	CONFIG.pf0_bar0_prefetchable_qdma {true}  \
	CONFIG.pf0_bar2_prefetchable_qdma {true}  \
	CONFIG.pf0_bar2_size_qdma {512}           \
	CONFIG.pf1_bar0_prefetchable_qdma {true}  \
	CONFIG.pf1_bar2_prefetchable_qdma {true}  \
	CONFIG.pf1_bar2_size_qdma {512}           \
	CONFIG.pf2_bar0_prefetchable_qdma {true}  \
	CONFIG.pf2_bar2_prefetchable_qdma {true}  \
	CONFIG.pf2_bar2_size_qdma {512}           \
	CONFIG.pf3_bar0_prefetchable_qdma {true}  \
	CONFIG.pf3_bar2_prefetchable_qdma {true}  \
	CONFIG.pf3_bar2_size_qdma {512}           \
	CONFIG.SRIOV_FIRST_VF_OFFSET {4}          \
	CONFIG.PF0_SRIOV_CAP_INITIAL_VF {4}       \
	CONFIG.PF0_SRIOV_FIRST_VF_OFFSET {4}      \
	CONFIG.PF2_SRIOV_CAP_INITIAL_VF {4}       \
	CONFIG.PF2_SRIOV_FIRST_VF_OFFSET {6}      \
	CONFIG.pf0_ari_enabled {true}             \
	CONFIG.dma_intf_sel_qdma {AXI_Stream_with_Completion}     \
	CONFIG.en_axi_mm_qdma {false}] [get_ips ${ip_name}]
generate_target {instantiation_template} [get_files ./${proj_dir}/${ip_name}/${ip_name}.xci]
generate_target all [get_files  ./${proj_dir}/${ip_name}/${ip_name}.xci]
ipx::package_project -force -import_files ./${proj_dir}/${ip_name}/${ip_name}.xci

create_ip -name axi_clock_converter -vendor xilinx.com -library ip -version 2.1 -module_name ${axi_ip_name} -dir ./${proj_dir}
set_property -dict [list       \
	CONFIG.PROTOCOL {AXI4LITE} \
	CONFIG.DATA_WIDTH {32}     \
	CONFIG.ID_WIDTH {0}        \
	CONFIG.AWUSER_WIDTH {0}    \
	CONFIG.ARUSER_WIDTH {0}    \
	CONFIG.RUSER_WIDTH {0}     \
	CONFIG.WUSER_WIDTH {0}     \
	CONFIG.BUSER_WIDTH {0}] [get_ips ${axi_ip_name}]
generate_target {instantiation_template} [get_files ./${proj_dir}/${axi_ip_name}/${axi_ip_name}.xci]
generate_target all [get_files  ./${proj_dir}/${axi_ip_name}/${axi_ip_name}.xci]
ipx::package_project -force -import_files ./${proj_dir}/${axi_ip_name}/${axi_ip_name}.xci

create_ip -name clk_wiz -vendor xilinx.com -library ip -version 6.0 -module_name ${clk_ip_name} -dir ./${proj_dir}
set_property -dict [list                 \
	CONFIG.PRIM_IN_FREQ {250.000}        \
	CONFIG.CLKIN1_JITTER_PS {40.0}       \
	CONFIG.MMCM_DIVCLK_DIVIDE {5}        \
	CONFIG.MMCM_CLKFBOUT_MULT_F {24.000} \
	CONFIG.MMCM_CLKIN1_PERIOD {4.000}    \
	CONFIG.MMCM_CLKIN2_PERIOD {10.0}     \
	CONFIG.CLKOUT1_JITTER {134.506}      \
	CONFIG.CLKOUT1_PHASE_ERROR {154.678}] [get_ips ${clk_ip_name}]
generate_target {instantiation_template} [get_files ./${proj_dir}/${clk_ip_name}/${clk_ip_name}.xci]
generate_target all [get_files  ./${proj_dir}/${clk_ip_name}/${clk_ip_name}.xci]
ipx::package_project -force -import_files ./${proj_dir}/${clk_ip_name}/${clk_ip_name}.xci

update_ip_catalog -rebuild 
ipx::infer_user_parameters [ipx::current_core]

set_property name ${design} [ipx::current_core]
set_property library ${lib_name} [ipx::current_core]
set_property vendor_display_name {NetFPGA} [ipx::current_core]
set_property company_url {http://www.netfpga.org} [ipx::current_core]
set_property vendor {NetFPGA} [ipx::current_core]
set_property supported_families {{virtexuplus} {Production}} [ipx::current_core]
set_property taxonomy {{/NetFPGA/Generic}} [ipx::current_core]
set_property version ${ip_version} [ipx::current_core]
set_property display_name ${design} [ipx::current_core]
set_property description ${design} [ipx::current_core]

ipx::add_user_parameter {C_M_AXIS_DATA_WIDTH} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameters C_M_AXIS_DATA_WIDTH]
set_property display_name {C_M_AXIS_DATA_WIDTH} [ipx::get_user_parameters C_M_AXIS_DATA_WIDTH]
set_property value {512} [ipx::get_user_parameters C_M_AXIS_DATA_WIDTH]
set_property value_format {long} [ipx::get_user_parameters C_M_AXIS_DATA_WIDTH]

ipx::add_user_parameter {C_S_AXIS_DATA_WIDTH} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameters C_S_AXIS_DATA_WIDTH]
set_property display_name {C_S_AXIS_DATA_WIDTH} [ipx::get_user_parameters C_S_AXIS_DATA_WIDTH]
set_property value {512} [ipx::get_user_parameters C_S_AXIS_DATA_WIDTH]
set_property value_format {long} [ipx::get_user_parameters C_S_AXIS_DATA_WIDTH]

ipx::add_user_parameter {C_M_AXIS_TUSER_WIDTH} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameters C_M_AXIS_TUSER_WIDTH]
set_property display_name {C_M_AXIS_TUSER_WIDTH} [ipx::get_user_parameters C_M_AXIS_TUSER_WIDTH]
set_property value {128} [ipx::get_user_parameters C_M_AXIS_TUSER_WIDTH]
set_property value_format {long} [ipx::get_user_parameters C_M_AXIS_TUSER_WIDTH]

ipx::add_user_parameter {C_S_AXIS_TUSER_WIDTH} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameters C_S_AXIS_TUSER_WIDTH]
set_property display_name {C_S_AXIS_TUSER_WIDTH} [ipx::get_user_parameters C_S_AXIS_TUSER_WIDTH]
set_property value {128} [ipx::get_user_parameters C_S_AXIS_TUSER_WIDTH]
set_property value_format {long} [ipx::get_user_parameters C_S_AXIS_TUSER_WIDTH]

ipx::add_user_parameter {C_S_AXI_DATA_WIDTH} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameters C_S_AXI_DATA_WIDTH]
set_property display_name {C_S_AXI_DATA_WIDTH} [ipx::get_user_parameters C_S_AXI_DATA_WIDTH]
set_property value {32} [ipx::get_user_parameters C_S_AXI_DATA_WIDTH]
set_property value_format {long} [ipx::get_user_parameters C_S_AXI_DATA_WIDTH]

ipx::add_user_parameter {C_S_AXI_ADDR_WIDTH} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameters C_S_AXI_ADDR_WIDTH]
set_property display_name {C_S_AXI_ADDR_WIDTH} [ipx::get_user_parameters C_S_AXI_ADDR_WIDTH]
set_property value {32} [ipx::get_user_parameters C_S_AXI_ADDR_WIDTH]
set_property value_format {long} [ipx::get_user_parameters C_S_AXI_ADDR_WIDTH]

#ipx::add_user_parameter {C_BASEADDR} [ipx::current_core]
#set_property value_resolve_type {user} [ipx::get_user_parameters C_BASEADDR]
#set_property display_name {C_BASEADDR} [ipx::get_user_parameters C_BASEADDR]
#set_property value {0x00000000} [ipx::get_user_parameters C_BASEADDR]
#set_property value_format {bitstring} [ipx::get_user_parameters C_BASEADDR]

#ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces m_axis -of_objects [ipx::current_core]]
#ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces s_axis -of_objects [ipx::current_core]]

ipx::infer_user_parameters [ipx::current_core]

ipx::check_integrity [ipx::current_core]
ipx::save_core [ipx::current_core]
update_ip_catalog
close_project

