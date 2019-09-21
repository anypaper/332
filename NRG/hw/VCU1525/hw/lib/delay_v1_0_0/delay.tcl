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
set design delay
set top delay
set device xcvu9p-fsgd2104-2L-e
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
read_verilog "./hdl/delay_cpu_regs_defines.v"
read_verilog "./hdl/delay_cpu_regs.v"
read_verilog "./hdl/prbs.v"
read_verilog "./hdl/uram_fifo.v"
read_verilog "./hdl/delay.v"
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
ipx::package_project

if { [ file exists ${project_dir} ] == 1} then {
	file delete -force ${project_dir}
}
file mkdir ${project_dir}
#set_property -dict [list \
#      CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} 
create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name delay_fifo -dir ${project_dir}
set_property -dict [list \
      CONFIG.Fifo_Implementation {Common_Clock_Builtin_FIFO} \
	  CONFIG.Performance_Options {First_Word_Fall_Through} \
      CONFIG.Input_Data_Width {737} \
	  CONFIG.Input_Depth {16384} \
	  CONFIG.Output_Data_Width {737} \
	  CONFIG.Output_Depth {16384} \
	  CONFIG.Use_Embedded_Registers {false} \
	  CONFIG.Use_Extra_Logic {true} \
	  CONFIG.Programmable_Full_Type {Single_Programmable_Full_Threshold_Constant} \
	  CONFIG.Programmable_Empty_Type {Single_Programmable_Empty_Threshold_Constant} \
	  CONFIG.Empty_Threshold_Assert_Value {4} \
	  CONFIG.Empty_Threshold_Negate_Value {5}] [get_ips delay_fifo]

#set_property -dict [list \
#      CONFIG.Fifo_Implementation {Common_Clock_Block_RAM} \
#	  CONFIG.Performance_Options {First_Word_Fall_Through} \
#      CONFIG.Input_Data_Width {737} \
#	  CONFIG.Input_Depth {16384} \
#	  CONFIG.Output_Data_Width {737} \
#	  CONFIG.Output_Depth {16384} \
#	  CONFIG.Use_Embedded_Registers {false} \
#	  CONFIG.Almost_Full_Flag {true} \
#	  CONFIG.Almost_Empty_Flag {true} \
#	  CONFIG.Use_Extra_Logic {true} \
#	  CONFIG.Data_Count {true} \
#	  CONFIG.Data_Count_Width {15} \
#	  CONFIG.Write_Data_Count_Width {15} \
#	  CONFIG.Read_Data_Count_Width {15} \
#      CONFIG.Full_Flags_Reset_Value {1} \
#	  CONFIG.Full_Threshold_Assert_Value {16383} \
#	  CONFIG.Full_Threshold_Negate_Value {16382} \
#	  CONFIG.Empty_Threshold_Assert_Value {4} \
#	  CONFIG.Empty_Threshold_Negate_Value {5}] [get_ips delay_fifo]

generate_target {instantiation_template} [get_files ./${project_dir}/delay_fifo/delay_fifo.xci]
generate_target all [get_files  ./${project_dir}/delay_fifo/delay_fifo.xci]
ipx::package_project -force -import_files ./${project_dir}/delay_fifo/delay_fifo.xci

#create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name delay_fifo_1 -dir ${project_dir}
#set_property -dict [list \
#      CONFIG.Fifo_Implementation {Common_Clock_Distributed_RAM} \
#	  CONFIG.Performance_Options {First_Word_Fall_Through} \
#      CONFIG.Input_Data_Width {368} \
#	  CONFIG.Input_Depth {32768} \
#	  CONFIG.Output_Data_Width {368} \
#	  CONFIG.Output_Depth {32768} \
#	  CONFIG.Use_Embedded_Registers {false} \
#	  CONFIG.Almost_Full_Flag {true} \
#	  CONFIG.Almost_Empty_Flag {true} \
#	  CONFIG.Use_Extra_Logic {true} \
#	  CONFIG.Data_Count {true} \
#	  CONFIG.Data_Count_Width {16} \
#	  CONFIG.Write_Data_Count_Width {16} \
#	  CONFIG.Read_Data_Count_Width {16} \
#      CONFIG.Full_Flags_Reset_Value {1} \
#	  CONFIG.Full_Threshold_Assert_Value {32767} \
#	  CONFIG.Full_Threshold_Negate_Value {32766} \
#	  CONFIG.Empty_Threshold_Assert_Value {4} \
#	  CONFIG.Empty_Threshold_Negate_Value {5}] [get_ips delay_fifo_1]
#
#generate_target {instantiation_template} [get_files ./${project_dir}/delay_fifo_1/delay_fifo_1.xci]
#generate_target all [get_files  ./${project_dir}/delay_fifo_1/delay_fifo_1.xci]
#ipx::package_project -force -import_files ./${project_dir}/delay_fifo_1/delay_fifo_1.xci

#set_property -dict [list CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM}] [get_ips delay_fifo] 
#set_property -dict [list CONFIG.INTERFACE_TYPE {Native}] [get_ips delay_fifo] 
#set_property -dict [list CONFIG.Almost_Full_Flag {true} CONFIG.Write_Acknowledge_Flag {false}] [get_ips delay_fifo] 
#set_property -dict [list CONFIG.Data_Count {true}] [get_ips delay_fifo] 
#set_property -dict [list CONFIG.Programmable_Empty_Type {No_Programmable_Empty_Threshold}] [get_ips delay_fifo] 
#set_property -dict [list CONFIG.Use_Extra_Logic {true}] [get_ips delay_fifo]
#set_property -dict [list CONFIG.Performance_Options {First_Word_Fall_Through}] [get_ips delay_fifo]
#set_property -dict [list CONFIG.Input_Data_Width {449} CONFIG.Input_Depth {32768}] [get_ips delay_fifo]
#set_property -dict [list CONFIG.Reset_Pin {true}] [get_ips delay_fifo]
#set_property -dict [list CONFIG.Output_Data_Width {449} CONFIG.Output_Depth {32768}] [get_ips delay_fifo]
#set_property -dict [list CONFIG.Full_Flags_Reset_Value {1}] [get_ips delay_fifo]
#set_property -dict [list CONFIG.Use_Dout_Reset {true}] [get_ips delay_fifo]
#set_property -dict [list CONFIG.Data_Count_Width {16}] [get_ips delay_fifo]
#set_property -dict [list CONFIG.Write_Data_Count_Width {16}] [get_ips delay_fifo]
#set_property -dict [list CONFIG.Read_Data_Count_Width {16}] [get_ips delay_fifo]
#set_property -dict [list CONFIG.Full_Threshold_Assert_Value {32767}] [get_ips delay_fifo]
#set_property -dict [list CONFIG.Full_Threshold_Negate_Value {32766}] [get_ips delay_fifo]
#set_property -dict [list CONFIG.Empty_Threshold_Assert_Value {4}] [get_ips delay_fifo]
#set_property -dict [list CONFIG.Empty_Threshold_Negate_Value {5}] [get_ips delay_fifo]

#set_property generate_synth_checkpoint false [get_files delay_fifo.xci]
#reset_target all [get_ips delay_fifo]
#generate_target all [get_ips delay_fifo]

generate_target {instantiation_template} [get_files ./${project_dir}/delay_fifo_0/delay_fifo_0.xci]
generate_target all [get_files  ./${project_dir}/delay_fifo_0/delay_fifo_0.xci]
ipx::package_project -force -import_files ./${project_dir}/delay_fifo_0/delay_fifo_0.xci

#Normal distribution
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name normal_dist_mem -dir ${project_dir}
set_property -dict [list CONFIG.Write_Depth_A {4096} CONFIG.Enable_A {Always_Enabled} CONFIG.Load_Init_File {true} CONFIG.Coe_File {../../normal.coe} CONFIG.Fill_Remaining_Memory_Locations {true} CONFIG.Use_RSTA_Pin {true}] [get_ips normal_dist_mem]

#create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name blk_mem_gen_0 
##-dir /root/latency/NetFPGA-SUME-dev/lib/hw/std/cores/delay_v1_0_0
#set_property -dict [list CONFIG.Write_Width_A {32} CONFIG.Write_Depth_A {65536} CONFIG.Fill_Remaining_Memory_Locations {true} CONFIG.Use_RSTA_Pin {true} CONFIG.Read_Width_A {32} CONFIG.Write_Width_B {32} CONFIG.Read_Width_B {32}] [get_ips blk_mem_gen_0]
#generate_target {instantiation_template} [get_files /root/latency/NetFPGA-SUME-dev/lib/hw/std/cores/delay_v1_0_0/blk_mem_gen_0/blk_mem_gen_0.xci]

#set_property generate_synth_checkpoint false [get_files normal_dist_mem.xci]
#reset_target all [get_ips normal_dist_mem]
#generate_target all [get_ips normal_dist_mem]
generate_target {instantiation_template} [get_files ./${project_dir}/normal_dist_mem/normal_dist_mem.xci]
generate_target all [get_files  ./${project_dir}/normal_dist_mem/normal_dist_mem.xci]
ipx::package_project -force -import_files ./${project_dir}/normal_dist_mem/normal_dist_mem.xci

#Pareto distribution
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name pareto_dist_mem -dir ${project_dir}
set_property -dict [list CONFIG.Write_Depth_A {4096} CONFIG.Enable_A {Always_Enabled} CONFIG.Load_Init_File {true} CONFIG.Coe_File {../../pareto.coe} CONFIG.Fill_Remaining_Memory_Locations {true} CONFIG.Use_RSTA_Pin {true}] [get_ips pareto_dist_mem]

#set_property generate_synth_checkpoint false [get_files pareto_dist_mem.xci]
#reset_target all [get_ips pareto_dist_mem]
#generate_target all [get_ips pareto_dist_mem]
generate_target {instantiation_template} [get_files ./${project_dir}/pareto_dist_mem/pareto_dist_mem.xci]
generate_target all [get_files  ./${project_dir}/pareto_dist_mem/pareto_dist_mem.xci]
ipx::package_project -force -import_files ./${project_dir}/pareto_dist_mem/pareto_dist_mem.xci

#Paretonormal distribution
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name paretonormal_dist_mem -dir ${project_dir}
set_property -dict [list CONFIG.Write_Depth_A {4096} CONFIG.Enable_A {Always_Enabled} CONFIG.Load_Init_File {true} CONFIG.Coe_File {../../paretonormal.coe} CONFIG.Fill_Remaining_Memory_Locations {true} CONFIG.Use_RSTA_Pin {true}] [get_ips paretonormal_dist_mem]

#set_property generate_synth_checkpoint false [get_files paretonormal_dist_mem.xci]
#reset_target all [get_ips paretonormal_dist_mem]
#generate_target all [get_ips paretonormal_dist_mem]
generate_target {instantiation_template} [get_files ./${project_dir}/paretonormal_dist_mem/paretonormal_dist_mem.xci]
generate_target all [get_files  ./${project_dir}/paretonormal_dist_mem/paretonormal_dist_mem.xci]
ipx::package_project -force -import_files ./${project_dir}/paretonormal_dist_mem/paretonormal_dist_mem.xci

#User defined distribution
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name user_dist_mem -dir ${project_dir}
set_property -dict [list CONFIG.Write_Depth_A {4096} CONFIG.Enable_A {Always_Enabled} CONFIG.Fill_Remaining_Memory_Locations {true} CONFIG.Use_RSTA_Pin {true}] [get_ips user_dist_mem]

#set_property generate_synth_checkpoint false [get_files user_dist_mem.xci]
#reset_target all [get_ips user_dist_mem]
#generate_target all [get_ips user_dist_mem]
generate_target {instantiation_template} [get_files ./${project_dir}/user_dist_mem/user_dist_mem.xci]
generate_target all [get_files  ./${project_dir}/user_dist_mem/user_dist_mem.xci]
ipx::package_project -force -import_files ./${project_dir}/user_dist_mem/user_dist_mem.xci

#debug distribution memory
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name dist_log_mem  -dir ${project_dir}
set_property -dict [list CONFIG.Write_Width_A {32} CONFIG.Write_Depth_A {65536} CONFIG.Fill_Remaining_Memory_Locations {true} CONFIG.Use_RSTA_Pin {true} CONFIG.Read_Width_A {32} CONFIG.Write_Width_B {32} CONFIG.Read_Width_B {32}] [get_ips dist_log_mem]

#set_property generate_synth_checkpoint false [get_files dist_log_mem.xci]
#reset_target all [get_ips dist_log_mem]
#generate_target all [get_ips pdist_log_mem]
generate_target {instantiation_template} [get_files ./${project_dir}/dist_log_mem/dist_log_mem.xci]
generate_target all [get_files  ./${project_dir}/dist_log_mem/dist_log_mem.xci]
ipx::package_project -force -import_files ./${project_dir}/dist_log_mem/dist_log_mem.xci


update_ip_catalog -rebuild 
ipx::infer_user_parameters [ipx::current_core]

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

ipx::add_user_parameter {C_DELAY_FIFO_DEPTH} [ipx::current_core]
set_property value_resolve_type {user} [ipx::get_user_parameter C_DELAY_FIFO_DEPTH [ipx::current_core]]
set_property display_name {C_S_AXI_DATA_WIDTH} [ipx::get_user_parameter C_DELAY_FIFO_DEPTH [ipx::current_core]]
set_property value {131072} [ipx::get_user_parameter C_DELAY_FIFO_DEPTH [ipx::current_core]]
set_property value_format {long} [ipx::get_user_parameter C_DELAY_FIFO_DEPTH [ipx::current_core]]

#ipx::add_subcore NetFPGA:NetFPGA:fallthrough_small_fifo:1.00 [ipx::get_file_groups xilinx_verilogsynthesis -of_objects [ipx::current_core]]
#ipx::add_subcore NetFPGA:NetFPGA:fallthrough_small_fifo:1.00 [ipx::get_file_groups xilinx_verilogbehavioralsimulation -of_objects [ipx::current_core]]
ipx::add_subcore xilinx.com:ip:fifo_generator:13.2 [ipx::get_file_groups xilinx_anylanguagesynthesis -of_objects [ipx::current_core]]
ipx::add_subcore xilinx.com:ip:fifo_generator:13.2 [ipx::get_file_groups xilinx_anylanguagebehavioralsimulation -of_objects [ipx::current_core]]


ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces m_axis -of_objects [ipx::current_core]]
ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces s_axis -of_objects [ipx::current_core]]

ipx::infer_user_parameters [ipx::current_core]

ipx::check_integrity [ipx::current_core]
ipx::save_core [ipx::current_core]
update_ip_catalog
close_project

file delete -force ${proj_dir} 












