#
# Copyright (c) 2015 
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

# Set variables.
set design $::env(NF_PROJECT_NAME)
set top tb_top
set sim_top tb_top
set device xcvu9p-fsgd2104-2L-e
set proj_dir ./project
set public_repo_dir $::env(SUME_FOLDER)/hw/lib/
#set xilinx_repo_dir $::env(XILINX_PATH)/data/ip/xilinx/
set repo_dir ./ip_repo
#set bit_settings $::env(CONSTRAINTS)/generic_bit.xdc 
#set project_constraints $::env(NF_DESIGN_DIR)/hw/constraints/nf_sume_general.xdc
#set nf_10g_constraints $::env(NF_DESIGN_DIR)/hw/constraints/nf_sume_10g.xdc


#set test_name [lindex $argv 0] 

#####################################
# Read IP Addresses and export registers
#####################################
#source $::env(NF_DESIGN_DIR)/hw/tcl/$::env(NF_PROJECT_NAME)_defines.tcl

# Build project.
create_project -name ${design} -force -dir "$::env(NF_DESIGN_DIR)/hw/${proj_dir}" -part ${device}
set_property source_mgmt_mode DisplayOnly [current_project]  
set_property top ${top} [current_fileset]
puts "Creating User Datapath reference project"

create_fileset -constrset -quiet constraints
file copy ${public_repo_dir}/ ${repo_dir}
set_property ip_repo_paths ${repo_dir} [current_fileset]
#add_files -fileset constraints -norecurse ${bit_settings}
#add_files -fileset constraints -norecurse ${project_constraints}
#add_files -fileset constraints -norecurse ${nf_10g_constraints}
#set_property is_enabled true [get_files ${project_constraints}]
#set_property is_enabled true [get_files ${bit_settings}]
#set_property is_enabled true [get_files ${project_constraints}]

update_ip_catalog
#source ./create_ip/delay.tcl
create_ip -name delay -vendor NetFPGA -library NetFPGA -module_name delay_ip
set_property generate_synth_checkpoint false [get_files delay_ip.xci]
reset_target all [get_ips delay_ip]
generate_target all [get_ips delay_ip]

#source ./create_ip/rate_limiter.tcl
create_ip -name rate_limiter -vendor NetFPGA -library NetFPGA -module_name rate_limiter_ip
set_property generate_synth_checkpoint false [get_files rate_limiter_ip.xci]
reset_target all [get_ips rate_limiter_ip]
generate_target all [get_ips rate_limiter_ip]

#source ./create_ip/stats.tcl
create_ip -name stats -vendor NetFPGA -library NetFPGA -module_name stats_ip
set_property generate_synth_checkpoint false [get_files stats_ip.xci]
reset_target all [get_ips stats_ip]
generate_target all [get_ips stats_ip]


update_ip_catalog

#source $::env(NF_DESIGN_DIR)/hw/tcl/control_sub_sim.tcl

read_verilog "./hdl/nf_datapath.v"
read_verilog "./hdl/tb_top.v"

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

set_property top ${sim_top} [get_filesets sim_1]
set_property include_dirs ${proj_dir} [get_filesets sim_1]
set_property simulator_language Mixed [current_project]
set_property verilog_define { {SIMULATION=1} } [get_filesets sim_1]
set_property -name xsim.more_options -value {-testplusarg TESTNAME=basic_test} -objects [get_filesets sim_1]
set_property runtime {} [get_filesets sim_1]
set_property target_simulator xsim [current_project]
#set_property compxlib.compiled_library_dir {} [current_project]
set_property  compxlib.xsim_compiled_library_dir {} [current_project]
set_property top_lib xil_defaultlib [get_filesets sim_1]
update_compile_order -fileset sim_1

#set output [exec python $::env(NF_DESIGN_DIR)/test/${test_name}/run.py]
#puts $output

launch_xsim -simset sim_1 -mode behavioral
run 10us




