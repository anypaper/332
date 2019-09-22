#
# Copyright (c) 2016 
# All rights reserved.
#
#
# @NETFPGA_LICENSE_HEADER_START@
#
# Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
# license agreements.  See the NOTICE file distributed with this work for
# additional information regarding copyright ownership.  NetFPGA licenses this
# file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
# "License"); you may not use this file except in compliance with the
# License.  You may obtain a copy of the License at:
#
#   http://www.netfpga-cic.org
#
# Unless required by applicable law or agreed to in writing, Work distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations under the License.
#
# @NETFPGA_LICENSE_HEADER_END@
#

# Vivado Launch Script
#### Change design settings here #######
set design rate_limiter
set top rate_limiter
set device xcu280-fsvh2892-2L-e
set proj_dir ./synth
set ip_version 1.00
set lib_name NetFPGA
set project_dir proj
#####################################
# set IP paths
#####################################

#####################################
# Project Settings
#####################################
create_project -name ${design} -force -dir "./${proj_dir}" -part ${device} -ip
set_property source_mgmt_mode All [current_project]  
set_property top ${top} [current_fileset]
set_property ip_repo_paths $::env(SUME_FOLDER)/hw/lib  [current_fileset]
puts "Creating Output Port Lookup IP"
# Project Constraints
#####################################
# Project Structure & IP Build
#####################################
read_verilog "./hdl/rate_limiter_cpu_regs_defines.v"
read_verilog "./hdl/rate_limiter_cpu_regs.v"
read_verilog "./hdl/rate_limiter.v"
read_verilog "./hdl/uram_fifo.v"
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
ipx::package_project

if { [ file exists ${project_dir} ] == 1} then {
	file delete -force ${project_dir}
}
file mkdir ${project_dir}

create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name rate_limiter_fifo -dir ${project_dir}
set_property -dict [list \
      CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
	  CONFIG.Performance_Options {First_Word_Fall_Through} \
      CONFIG.Input_Data_Width {705} \
	  CONFIG.Input_Depth {4096} \
	  CONFIG.Output_Data_Width {705} \
	  CONFIG.Output_Depth {4096} \
	  CONFIG.Use_Embedded_Registers {false} \
	  CONFIG.Almost_Full_Flag {true} \
	  CONFIG.Almost_Empty_Flag {true} \
	  CONFIG.Use_Extra_Logic {true} \
	  CONFIG.Data_Count {true} \
	  CONFIG.Data_Count_Width {11} \
	  CONFIG.Write_Data_Count_Width {11} \
	  CONFIG.Read_Data_Count_Width {11} \
      CONFIG.Full_Flags_Reset_Value {1} \
	  CONFIG.Full_Threshold_Assert_Value {1023} \
	  CONFIG.Full_Threshold_Negate_Value {1022} \
	  CONFIG.Empty_Threshold_Assert_Value {4} \
	  CONFIG.Empty_Threshold_Negate_Value {5}] [get_ips rate_limiter_fifo]

#set_property -dict [list CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM}] [get_ips rate_limiter_fifo]
#set_property -dict [list CONFIG.INTERFACE_TYPE {Native}] [get_ips rate_limiter_fifo]
#set_property -dict [list CONFIG.Almost_Full_Flag {true} CONFIG.Write_Acknowledge_Flag {false}] [get_ips rate_limiter_fifo]
#set_property -dict [list CONFIG.Data_Count {true}] [get_ips rate_limiter_fifo]
#set_property -dict [list CONFIG.Programmable_Empty_Type {No_Programmable_Empty_Threshold}] [get_ips rate_limiter_fifo]
#set_property -dict [list CONFIG.Use_Extra_Logic {true}] [get_ips rate_limiter_fifo]
#set_property -dict [list CONFIG.Performance_Options {First_Word_Fall_Through}] [get_ips rate_limiter_fifo]
##set_property -dict [list CONFIG.Input_Data_Width {417} CONFIG.Input_Depth {8192}] [get_ips rate_limiter_fifo]
#set_property -dict [list CONFIG.Input_Data_Width {417} CONFIG.Input_Depth {4096}] [get_ips rate_limiter_fifo]
#set_property -dict [list CONFIG.Reset_Pin {true}] [get_ips rate_limiter_fifo]
##set_property -dict [list CONFIG.Output_Data_Width {417} CONFIG.Output_Depth {8192}] [get_ips rate_limiter_fifo]
#set_property -dict [list CONFIG.Output_Data_Width {417} CONFIG.Output_Depth {4096}] [get_ips rate_limiter_fifo]
#set_property -dict [list CONFIG.Full_Flags_Reset_Value {1}] [get_ips rate_limiter_fifo]
#set_property -dict [list CONFIG.Use_Dout_Reset {true}] [get_ips rate_limiter_fifo]
##set_property -dict [list CONFIG.Data_Count_Width {14}] [get_ips rate_limiter_fifo]
#set_property -dict [list CONFIG.Data_Count_Width {13}] [get_ips rate_limiter_fifo]
#set_property -dict [list CONFIG.Write_Data_Count_Width {13}] [get_ips rate_limiter_fifo]
#set_property -dict [list CONFIG.Read_Data_Count_Width {13}] [get_ips rate_limiter_fifo]
#set_property -dict [list CONFIG.Full_Threshold_Assert_Value {4095}] [get_ips rate_limiter_fifo]
#set_property -dict [list CONFIG.Full_Threshold_Negate_Value {4094}] [get_ips rate_limiter_fifo]
##set_property -dict [list CONFIG.Write_Data_Count_Width {14}] [get_ips rate_limiter_fifo]
##set_property -dict [list CONFIG.Read_Data_Count_Width {14}] [get_ips rate_limiter_fifo]
##set_property -dict [list CONFIG.Full_Threshold_Assert_Value {8191}] [get_ips rate_limiter_fifo]
##set_property -dict [list CONFIG.Full_Threshold_Negate_Value {8190}] [get_ips rate_limiter_fifo]
#set_property -dict [list CONFIG.Empty_Threshold_Assert_Value {4}] [get_ips rate_limiter_fifo]
#set_property -dict [list CONFIG.Empty_Threshold_Negate_Value {5}] [get_ips rate_limiter_fifo]


#set_property generate_synth_checkpoint false [get_files rate_limiter_fifo.xci]
#reset_target all [get_ips rate_limiter_fifo]
#generate_target all [get_ips rate_limiter_fifo]
generate_target {instantiation_template} [get_files ./${project_dir}/rate_limiter_fifo/rate_limiter_fifo.xci]
generate_target all [get_files  ./${project_dir}/rate_limiter_fifo/rate_limiter_fifo.xci]
ipx::package_project -force -import_files ./${project_dir}/rate_limiter_fifo/rate_limiter_fifo.xci

update_ip_catalog -rebuild 
ipx::infer_user_parameters [ipx::current_core]

set_property name ${design} [ipx::current_core]
set_property library ${lib_name} [ipx::current_core]
set_property vendor_display_name {NetFPGA} [ipx::current_core]
set_property company_url {http://www.netfpga.org} [ipx::current_core]
set_property vendor {NetFPGA} [ipx::current_core]
#set_property supported_families {{virtex7} {Production}} [ipx::current_core]
set_property supported_families {{virtexuplusHBM} {Production}} [ipx::current_core]
set_property taxonomy {{/NetFPGA/Generic}} [ipx::current_core]
set_property version ${ip_version} [ipx::current_core]
set_property display_name ${design} [ipx::current_core]
set_property description ${design} [ipx::current_core]

ipx::add_user_parameter {C_S_AXI_DATA_WIDTH} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameter C_S_AXI_DATA_WIDTH [ipx::current_core]]
set_property display_name {C_S_AXI_DATA_WIDTH} [ipx::get_user_parameter C_S_AXI_DATA_WIDTH [ipx::current_core]]
set_property value {32} [ipx::get_user_parameter C_S_AXI_DATA_WIDTH [ipx::current_core]]
set_property value_format {long} [ipx::get_user_parameter C_S_AXI_DATA_WIDTH [ipx::current_core]]

ipx::add_user_parameter {C_S_AXI_ADDR_WIDTH} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameter C_S_AXI_ADDR_WIDTH [ipx::current_core]]
set_property display_name {C_S_AXI_ADDR_WIDTH} [ipx::get_user_parameter C_S_AXI_ADDR_WIDTH [ipx::current_core]]
set_property value {32} [ipx::get_user_parameter C_S_AXI_ADDR_WIDTH [ipx::current_core]]
set_property value_format {long} [ipx::get_user_parameter C_S_AXI_ADDR_WIDTH [ipx::current_core]]

ipx::add_user_parameter {C_M_AXIS_DATA_WIDTH} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameter C_M_AXIS_DATA_WIDTH [ipx::current_core]]
set_property display_name {C_M_AXIS_DATA_WIDTH} [ipx::get_user_parameter C_M_AXIS_DATA_WIDTH [ipx::current_core]]
set_property value {512} [ipx::get_user_parameter C_M_AXIS_DATA_WIDTH [ipx::current_core]]
set_property value_format {long} [ipx::get_user_parameter C_M_AXIS_DATA_WIDTH [ipx::current_core]]

ipx::add_user_parameter {C_S_AXIS_DATA_WIDTH} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameter C_S_AXIS_DATA_WIDTH [ipx::current_core]]
set_property display_name {C_S_AXIS_DATA_WIDTH} [ipx::get_user_parameter C_S_AXIS_DATA_WIDTH [ipx::current_core]]
set_property value {512} [ipx::get_user_parameter C_S_AXIS_DATA_WIDTH [ipx::current_core]]
set_property value_format {long} [ipx::get_user_parameter C_S_AXIS_DATA_WIDTH [ipx::current_core]]
  
ipx::add_user_parameter {C_M_AXIS_TUSER_WIDTH} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameter C_M_AXIS_TUSER_WIDTH [ipx::current_core]]
set_property display_name {C_M_AXIS_TUSER_WIDTH} [ipx::get_user_parameter C_M_AXIS_TUSER_WIDTH [ipx::current_core]]
set_property value {128} [ipx::get_user_parameter C_M_AXIS_TUSER_WIDTH [ipx::current_core]]
set_property value_format {long} [ipx::get_user_parameter C_M_AXIS_TUSER_WIDTH [ipx::current_core]]

ipx::add_user_parameter {C_S_AXIS_TUSER_WIDTH} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameter C_S_AXIS_TUSER_WIDTH [ipx::current_core]]
set_property display_name {C_S_AXIS_TUSER_WIDTH} [ipx::get_user_parameter C_S_AXIS_TUSER_WIDTH [ipx::current_core]]
set_property value {128} [ipx::get_user_parameter C_S_AXIS_TUSER_WIDTH [ipx::current_core]]
set_property value_format {long} [ipx::get_user_parameter C_S_AXIS_TUSER_WIDTH [ipx::current_core]]

ipx::add_user_parameter {C_BASEADDR} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameter C_BASEADDR [ipx::current_core]]
set_property display_name {C_BASEADDR} [ipx::get_user_parameter C_BASEADDR [ipx::current_core]]
set_property value {0x00000000} [ipx::get_user_parameter C_BASEADDR [ipx::current_core]]
set_property value_format {bitstring} [ipx::get_user_parameter C_BASEADDR [ipx::current_core]]

update_ip_catalog -rebuild 
#ipx::add_subcore NetFPGA:NetFPGA:fallthrough_small_fifo:1.00 [ipx::get_file_groups xilinx_verilogsynthesis -of_objects [ipx::current_core]]
#ipx::add_subcore NetFPGA:NetFPGA:fallthrough_small_fifo:1.00 [ipx::get_file_groups xilinx_verilogbehavioralsimulation -of_objects [ipx::current_core]]
ipx::add_subcore xilinx.com:ip:fifo_generator:13.2 [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
ipx::add_subcore xilinx.com:ip:fifo_generator:13.2 [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]
ipx::infer_user_parameters [ipx::current_core]



ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces m_axis -of_objects [ipx::current_core]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces s_axis -of_objects [ipx::current_core]]

ipx::infer_user_parameters [ipx::current_core]

ipx::check_integrity [ipx::current_core]
ipx::save_core [ipx::current_core]
update_ip_catalog
close_project

file delete -force ${proj_dir} 












