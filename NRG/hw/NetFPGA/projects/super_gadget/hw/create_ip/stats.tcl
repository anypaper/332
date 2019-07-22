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


create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.3 -module_name stats_mem
set_property -dict [list CONFIG.Interface_Type {Native} CONFIG.Enable_32bit_Address {false} CONFIG.ecctype {No_ECC} CONFIG.Write_Depth_A {4096} CONFIG.Register_PortB_Output_of_Memory_Core {false} CONFIG.Fill_Remaining_Memory_Locations {true} CONFIG.Use_AXI_ID {false} CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.ECC {false} CONFIG.softecc {false} CONFIG.Use_Byte_Write_Enable {false} CONFIG.Byte_Size {9} CONFIG.Algorithm {Minimum_Area} CONFIG.Primitive {256x72} CONFIG.Assume_Synchronous_Clk {false} CONFIG.Write_Width_A {32} CONFIG.Read_Width_A {32} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Write_Width_B {32} CONFIG.Read_Width_B {32} CONFIG.Operating_Mode_B {WRITE_FIRST} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {true} CONFIG.Use_RSTB_Pin {false} CONFIG.Reset_Type {SYNC} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Enable_Rate {100}] [get_ips stats_mem]
set_property generate_synth_checkpoint false [get_files stats_mem.xci]
reset_target all [get_ips stats_mem]
generate_target all [get_ips stats_mem]
