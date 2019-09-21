#### Change design settings here #######
set design nf_cmac_interface_1
set top nf_cmac_interface_1
set device xcvu9p-fsgd2104-2L-e
set board  xilinx.com:vcu1525:part0:1.3
set proj_dir ./ip_proj
set ip_version 1.00
set lib_name NetFPGA
#####################################
# Project Settings #####################################
create_project -name ${design} -force -dir "./${proj_dir}" -part ${device} -ip
set_property source_mgmt_mode All [current_project]  
set_property board_part ${board} [current_project]
set_property top ${top} [current_fileset]
set_property ip_repo_paths $::env(SUME_FOLDER)/hw/lib  [current_fileset]
puts "Creating Input Arbiter IP"
#####################################
# Project Structure & IP Build
#####################################
read_verilog "hdl/cmac1_startup_seq.v "
read_verilog "./hdl/nf_cmac_interface_1.v"
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
ipx::package_project

update_ip_catalog -rebuild 
ipx::infer_user_parameters [ipx::current_core]

create_ip -name cmac_usplus -vendor xilinx.com -library ip -version 2.6 -module_name cmac_interface_1 -dir ./${proj_dir}
set_property -dict [list \
	CONFIG.CMAC_CAUI4_MODE {1} \
	CONFIG.NUM_LANES {4} \
	CONFIG.GT_REF_CLK_FREQ {161.1328125} \
	CONFIG.USER_INTERFACE {AXIS} \
	CONFIG.TX_FLOW_CONTROL {0} \
	CONFIG.RX_FLOW_CONTROL {0} \
	CONFIG.INCLUDE_RS_FEC {1} \
	CONFIG.ENABLE_AXI_INTERFACE {0} \
	CONFIG.INCLUDE_STATISTICS_COUNTERS {0} \
	CONFIG.CMAC_CORE_SELECT {CMACE4_X0Y7} \
	CONFIG.GT_GROUP_SELECT {X1Y44~X1Y47} \
	CONFIG.LANE1_GT_LOC {X1Y44} \
	CONFIG.LANE2_GT_LOC {X1Y45} \
	CONFIG.LANE3_GT_LOC {X1Y46} \
	CONFIG.LANE4_GT_LOC {X1Y47} \
	CONFIG.LANE5_GT_LOC {NA} \
	CONFIG.LANE6_GT_LOC {NA} \
	CONFIG.LANE7_GT_LOC {NA} \
	CONFIG.LANE8_GT_LOC {NA} \
	CONFIG.LANE9_GT_LOC {NA} \
	CONFIG.LANE10_GT_LOC {NA} \
	CONFIG.RX_GT_BUFFER {NA} \
	CONFIG.GT_RX_BUFFER_BYPASS {NA}] [get_ips cmac_interface_1]
generate_target {instantiation_template} [get_files ./${proj_dir}/cmac_interface_1/cmac_interface_1.xci]
generate_target all [get_files  ./${proj_dir}/cmac_interface_1/cmac_interface_1.xci]
ipx::package_project -force -import_files ./${proj_dir}/cmac_interface_1/cmac_interface_1.xci

set_property name ${design} [ipx::current_core]
set_property library ${lib_name} [ipx::current_core]
set_property vendor_display_name {NetFPGA} [ipx::current_core]
set_property company_url {http://www.netfpga.org} [ipx::current_core]
set_property vendor {NetFPGA} [ipx::current_core]
#set_property supported_families {{virtex7} {Production}} [ipx::current_core]
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

#ipx::add_user_parameter {C_S_AXI_DATA_WIDTH} [ipx::current_core]
#set_property value_resolve_type {user} [ipx::get_user_parameters C_S_AXI_DATA_WIDTH]
#set_property display_name {C_S_AXI_DATA_WIDTH} [ipx::get_user_parameters C_S_AXI_DATA_WIDTH]
#set_property value {32} [ipx::get_user_parameters C_S_AXI_DATA_WIDTH]
#set_property value_format {long} [ipx::get_user_parameters C_S_AXI_DATA_WIDTH]
#
#ipx::add_user_parameter {C_S_AXI_ADDR_WIDTH} [ipx::current_core]
#set_property value_resolve_type {user} [ipx::get_user_parameters C_S_AXI_ADDR_WIDTH]
#set_property display_name {C_S_AXI_ADDR_WIDTH} [ipx::get_user_parameters C_S_AXI_ADDR_WIDTH]
#set_property value {32} [ipx::get_user_parameters C_S_AXI_ADDR_WIDTH]
#set_property value_format {long} [ipx::get_user_parameters C_S_AXI_ADDR_WIDTH]
#
#ipx::add_user_parameter {C_BASEADDR} [ipx::current_core]
#set_property value_resolve_type {user} [ipx::get_user_parameters C_BASEADDR]
#set_property display_name {C_BASEADDR} [ipx::get_user_parameters C_BASEADDR]
#set_property value {0x00000000} [ipx::get_user_parameters C_BASEADDR]
#set_property value_format {bitstring} [ipx::get_user_parameters C_BASEADDR]

ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces m_axis -of_objects [ipx::current_core]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces s_axis -of_objects [ipx::current_core]]

ipx::add_subcore NetFPGA:NetFPGA:nf_10g_attachment:1.0 [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
ipx::add_subcore NetFPGA:NetFPGA:nf_10g_attachment:1.0 [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]

ipx::infer_user_parameters [ipx::current_core]

ipx::check_integrity [ipx::current_core]
ipx::save_core [ipx::current_core]
update_ip_catalog
close_project
