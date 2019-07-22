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

# Set variables



create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.1 -module_name delay_fifo
set_property -dict [list CONFIG.FIFO_Implementation_wach {Common_Clock_Distributed_RAM} CONFIG.FIFO_Implementation_rach {Common_Clock_Distributed_RAM} CONFIG.FIFO_Implementation_wrch {Common_Clock_Distributed_RAM}] [get_ips delay_fifo]
set_property -dict [list CONFIG.INTERFACE_TYPE {Native}] [get_ips delay_fifo]
set_property -dict [list CONFIG.Almost_Full_Flag {true} CONFIG.Write_Acknowledge_Flag {false}] [get_ips delay_fifo]
set_property -dict [list CONFIG.Data_Count {true}] [get_ips delay_fifo]
set_property -dict [list CONFIG.Programmable_Empty_Type {No_Programmable_Empty_Threshold}] [get_ips delay_fifo]
set_property -dict [list CONFIG.Use_Extra_Logic {true}] [get_ips delay_fifo]
set_property -dict [list CONFIG.Performance_Options {First_Word_Fall_Through}] [get_ips delay_fifo]
set_property -dict [list CONFIG.Input_Data_Width {449} CONFIG.Input_Depth {32768}] [get_ips delay_fifo]
set_property -dict [list CONFIG.Reset_Pin {true}] [get_ips delay_fifo]
set_property -dict [list CONFIG.Output_Data_Width {449} CONFIG.Output_Depth {32768}] [get_ips delay_fifo]
set_property -dict [list CONFIG.Full_Flags_Reset_Value {1}] [get_ips delay_fifo]
set_property -dict [list CONFIG.Use_Dout_Reset {true}] [get_ips delay_fifo]
set_property -dict [list CONFIG.Data_Count_Width {16}] [get_ips delay_fifo]
set_property -dict [list CONFIG.Write_Data_Count_Width {16}] [get_ips delay_fifo]
set_property -dict [list CONFIG.Read_Data_Count_Width {16}] [get_ips delay_fifo]
set_property -dict [list CONFIG.Full_Threshold_Assert_Value {32767}] [get_ips delay_fifo]
set_property -dict [list CONFIG.Full_Threshold_Negate_Value {32766}] [get_ips delay_fifo]
set_property -dict [list CONFIG.Empty_Threshold_Assert_Value {4}] [get_ips delay_fifo]
set_property -dict [list CONFIG.Empty_Threshold_Negate_Value {5}] [get_ips delay_fifo]

set_property generate_synth_checkpoint false [get_files delay_fifo.xci]
reset_target all [get_ips delay_fifo]
generate_target all [get_ips delay_fifo]

#Normal distribution
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.3 -module_name normal_dist_mem
set_property -dict [list CONFIG.Write_Depth_A {4096} CONFIG.Enable_A {Always_Enabled} CONFIG.Load_Init_File {true} CONFIG.Coe_File {/../../../../../../create_ip/normal.coe} CONFIG.Fill_Remaining_Memory_Locations {true} CONFIG.Use_RSTA_Pin {true}] [get_ips normal_dist_mem]

create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.3 -module_name blk_mem_gen_0 -dir /root/latency/NetFPGA-SUME-dev/lib/hw/std/cores/delay_v1_0_0
set_property -dict [list CONFIG.Write_Width_A {32} CONFIG.Write_Depth_A {65536} CONFIG.Fill_Remaining_Memory_Locations {true} CONFIG.Use_RSTA_Pin {true} CONFIG.Read_Width_A {32} CONFIG.Write_Width_B {32} CONFIG.Read_Width_B {32}] [get_ips blk_mem_gen_0]
generate_target {instantiation_template} [get_files /root/latency/NetFPGA-SUME-dev/lib/hw/std/cores/delay_v1_0_0/blk_mem_gen_0/blk_mem_gen_0.xci]

set_property generate_synth_checkpoint false [get_files normal_dist_mem.xci]
reset_target all [get_ips normal_dist_mem]
generate_target all [get_ips normal_dist_mem]

#Pareto distribution
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.3 -module_name pareto_dist_mem
set_property -dict [list CONFIG.Write_Depth_A {4096} CONFIG.Enable_A {Always_Enabled} CONFIG.Load_Init_File {true} CONFIG.Coe_File {/../../../../../../create_ip/pareto.coe} CONFIG.Fill_Remaining_Memory_Locations {true} CONFIG.Use_RSTA_Pin {true}] [get_ips pareto_dist_mem]

set_property generate_synth_checkpoint false [get_files pareto_dist_mem.xci]
reset_target all [get_ips pareto_dist_mem]
generate_target all [get_ips pareto_dist_mem]

#Paretonormal distribution
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.3 -module_name paretonormal_dist_mem
set_property -dict [list CONFIG.Write_Depth_A {4096} CONFIG.Enable_A {Always_Enabled} CONFIG.Load_Init_File {true} CONFIG.Coe_File {/../../../../../../create_ip/paretonormal.coe} CONFIG.Fill_Remaining_Memory_Locations {true} CONFIG.Use_RSTA_Pin {true}] [get_ips paretonormal_dist_mem]

set_property generate_synth_checkpoint false [get_files paretonormal_dist_mem.xci]
reset_target all [get_ips paretonormal_dist_mem]
generate_target all [get_ips paretonormal_dist_mem]

#User defined distribution
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.3 -module_name user_dist_mem
set_property -dict [list CONFIG.Write_Depth_A {4096} CONFIG.Enable_A {Always_Enabled} CONFIG.Fill_Remaining_Memory_Locations {true} CONFIG.Use_RSTA_Pin {true}] [get_ips user_dist_mem]

set_property generate_synth_checkpoint false [get_files user_dist_mem.xci]
reset_target all [get_ips user_dist_mem]
generate_target all [get_ips user_dist_mem]

#debug distribution memory
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.3 -module_name dist_log_mem 
set_property -dict [list CONFIG.Write_Width_A {32} CONFIG.Write_Depth_A {65536} CONFIG.Fill_Remaining_Memory_Locations {true} CONFIG.Use_RSTA_Pin {true} CONFIG.Read_Width_A {32} CONFIG.Write_Width_B {32} CONFIG.Read_Width_B {32}] [get_ips dist_log_mem]

set_property generate_synth_checkpoint false [get_files dist_log_mem.xci]
reset_target all [get_ips dist_log_mem]
generate_target all [get_ips pdist_log_mem]

