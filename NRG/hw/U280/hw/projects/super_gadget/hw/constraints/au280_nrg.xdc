##-----------------------------------------------------------------------------
##
## (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
##
## This file contains confidential and proprietary information
## of Xilinx, Inc. and is protected under U.S. and
## international copyright and other intellectual property
## laws.
##
## DISCLAIMER
## This disclaimer is not a license and does not grant any
## rights to the materials distributed herewith. Except as
## otherwise provided in a valid license issued to you by
## Xilinx, and to the maximum extent permitted by applicable
## law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
## WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
## AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
## BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
## INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
## (2) Xilinx shall not be liable (whether in contract or tort,
## including negligence, or under any other theory of
## liability) for any loss or damage of any kind or nature
## related to, arising under or in connection with these
## materials, including for any direct, or any indirect,
## special, incidental, or consequential loss or damage
## (including loss of data, profits, goodwill, or any type of
## loss or damage suffered as a result of any action brought
## by a third party) even if such damage or loss was
## reasonably foreseeable or Xilinx had been advised of the
## possibility of the same.
##
## CRITICAL APPLICATIONS
## Xilinx products are not designed or intended to be fail-
## safe, or for use in any application requiring fail-safe
## performance, such as life-support or safety devices or
## systems, Class III medical devices, nuclear facilities,
## applications related to the deployment of airbags, or any
## other applications that could lead to death, personal
## injury, or severe property or environmental damage
## (individually and collectively, "Critical
## Applications"). Customer assumes the sole risk and
## liability of any use of Xilinx products in Critical
## Applications, subject only to applicable laws and
## regulations governing limitations on product liability.
##
## THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
## PART OF THIS FILE AT ALL TIMES.
##
##-----------------------------------------------------------------------------
##
## Project    : The Xilinx PCI Express DMA 
## File       : xilinx_pcie_qdma_ref_board.xdc
## Version    : 5.0
##-----------------------------------------------------------------------------
#
# User Configuration
# Link Width   - x8
# Link Speed   - Gen3
# Family       - virtexuplusHBM
# Part         - xcu280
# Package      - fsvh2892
# Speed grade  - -2L
# Xilinx Reference Board is AU280
###############################################################################
# User Time Names / User Time Groups / Time Specs
###############################################################################
##
## Free Running Clock is Required for IBERT/DRP operations.
##
#############################################################################################################

create_clock -name sys_clk -period 10 [get_ports sys_clk_p]
#
#############################################################################################################
set_false_path -from [get_ports sys_rst_n]
set_property PULLUP true [get_ports sys_rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports sys_rst_n]
#
set_property PACKAGE_PIN BH26 [get_ports sys_rst_n]
#
set_property CONFIG_VOLTAGE 1.8 [current_design]
#
#############################################################################################################
#set_property PACKAGE_PIN AL14 [get_ports sys_clk_n]
#set_property PACKAGE_PIN AL15 [get_ports sys_clk_p]
set_property LOC [get_package_pins -of_objects [get_bels [get_sites -filter {NAME =~ *COMMON*} -of_objects [get_iobanks -of_objects [get_sites GTYE4_CHANNEL_X1Y15]]]/REFCLK0P]] [get_ports sys_clk_p]
set_property LOC [get_package_pins -of_objects [get_bels [get_sites -filter {NAME =~ *COMMON*} -of_objects [get_iobanks -of_objects [get_sites GTYE4_CHANNEL_X1Y15]]]/REFCLK0N]] [get_ports sys_clk_n]
#
#############################################################################################################
#
#
# BITFILE/BITSTREAM compress options
#
#set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN div-1 [current_design]
#set_property BITSTREAM.CONFIG.BPI_SYNC_MODE Type1 [current_design]
#set_property CONFIG_MODE BPI16 [current_design]
#set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
#set_property BITSTREAM.CONFIG.UNUSEDPIN Pulldown [current_design]
#
#
set_false_path -to [get_pins -hier *sync_reg[0]/D]
#
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets u_control_sub/inst/sys_clk_gt]



# CMAC
# SYSCLK
set_property PACKAGE_PIN BJ44 [get_ports SYSCLK_N];
set_property IOSTANDARD LVDS [get_ports SYSCLK_N];
set_property PACKAGE_PIN BJ43 [get_ports SYSCLK_P];
set_property IOSTANDARD LVDS [get_ports SYSCLK_P];
create_clock -period  10.000 -name SYSCLK0_300 [get_ports SYSCLK_P]
set_clock_groups -asynchronous -group [get_clocks SYSCLK0_300 -include_generated_clocks]

## USER_SI570_CLOCK
#set_property PACKAGE_PIN AV19 [get_ports USER_SI570_CLOCK_N];
#set_property IOSTANDARD LVDS [get_ports USER_SI570_CLOCK_N];
#set_property PACKAGE_PIN AU19 [get_ports USER_SI570_CLOCK_P];
#set_property IOSTANDARD LVDS [get_ports USER_SI570_CLOCK_P];
#create_clock -period  6.400 -name USER_SI570_CLOCK [get_ports USER_SI570_CLOCK_P]
#set_clock_groups -asynchronous -group [get_clocks USER_SI570_CLOCK -include_generated_clocks]

# QSFP0_CLOCK
set_property PACKAGE_PIN R41 [get_ports QSFP0_CLOCK_N];
##set_property IOSTANDARD LVDS [get_ports QSFP0_CLOCK_N];
set_property PACKAGE_PIN R40 [get_ports QSFP0_CLOCK_P];
#set_property IOSTANDARD LVDS [get_ports QSFP0_CLOCK_P];
#create_clock -period 6.206 -name QSFP0_CLOCK [get_ports QSFP0_CLOCK_P]
#create_clock -period 3.103 -name QSFP0_CLOCK [get_ports QSFP0_CLOCK_P]
#set_clock_groups -asynchronous -group [get_clocks QSFP0_CLOCK -include_generated_clocks]

# QSFP0_PORT
#set_property PACKAGE_PIN AT20 [get_ports QSFP0_FS0];
#set_property IOSTANDARD LVCMOS12 [get_ports QSFP0_FS0];
#set_property PACKAGE_PIN AU22 [get_ports QSFP0_FS1];
#set_property IOSTANDARD LVCMOS12 [get_ports QSFP0_FS1];
#
#set_property PACKAGE_PIN BE21 [get_ports QSFP0_INTL];
#set_property IOSTANDARD LVCMOS12 [get_ports QSFP0_INTL];
#set_property PACKAGE_PIN BD18 [get_ports QSFP0_LPMODE];
#set_property IOSTANDARD LVCMOS12 [get_ports QSFP0_LPMODE];
#set_property PACKAGE_PIN BE20 [get_ports QSFP0_MODPRSL];
#set_property IOSTANDARD LVCMOS12 [get_ports QSFP0_MODPRSL];
#set_property PACKAGE_PIN BE16 [get_ports QSFP0_MODSELL];
#set_property IOSTANDARD LVCMOS12 [get_ports QSFP0_MODSELL];
##set_property PACKAGE_PIN AT22 [get_ports QSFP0_REFCLK_RESET];
##set_property IOSTANDARD LVCMOS12 [get_ports QSFP0_REFCLK_RESET];
#set_property PACKAGE_PIN BE17 [get_ports QSFP0_RESETL];
#set_property IOSTANDARD LVCMOS12 [get_ports QSFP0_RESETL];
#
## QSFP0_TX
#set_property -dict { LOC K7 } [get_ports QSFP0_TX_P[3]]
#set_property -dict { LOC K6 } [get_ports QSFP0_TX_N[3]]
#set_property -dict { LOC L9 } [get_ports QSFP0_TX_P[2]]
#set_property -dict { LOC L8 } [get_ports QSFP0_TX_N[2]]
#set_property -dict { LOC M7 } [get_ports QSFP0_TX_P[1]]
#set_property -dict { LOC M6 } [get_ports QSFP0_TX_N[1]]
#set_property -dict { LOC N9 } [get_ports QSFP0_TX_P[0]]
#set_property -dict { LOC N8 } [get_ports QSFP0_TX_N[0]]
#
## QSFP0_RX
#set_property -dict { LOC K2 } [get_ports QSFP0_RX_P[3]]
#set_property -dict { LOC K1 } [get_ports QSFP0_RX_N[3]]
#set_property -dict { LOC L4 } [get_ports QSFP0_RX_P[2]]
#set_property -dict { LOC L3 } [get_ports QSFP0_RX_N[2]]
#set_property -dict { LOC M2 } [get_ports QSFP0_RX_P[1]]
#set_property -dict { LOC M1 } [get_ports QSFP0_RX_N[1]]
#set_property -dict { LOC N4 } [get_ports QSFP0_RX_P[0]]
#set_property -dict { LOC N3 } [get_ports QSFP0_RX_N[0]]
#
## QSFP1
set_property PACKAGE_PIN M43 [get_ports QSFP1_CLOCK_N];
##set_property IOSTANDARD LVDS [get_ports QSFP1_CLOCK_N];
set_property PACKAGE_PIN M42 [get_ports QSFP1_CLOCK_P];
##set_property IOSTANDARD LVDS [get_ports QSFP1_CLOCK_P];
#
## QSFP1
#set_property PACKAGE_PIN AR22 [get_ports QSFP1_FS0];
#set_property IOSTANDARD LVCMOS12 [get_ports QSFP1_FS0];
#set_property PACKAGE_PIN AU20 [get_ports QSFP1_FS1];
#set_property IOSTANDARD LVCMOS12 [get_ports QSFP1_FS1];
#set_property PACKAGE_PIN AV21 [get_ports QSFP1_INTL];
#set_property IOSTANDARD LVCMOS12 [get_ports QSFP1_INTL];
#set_property PACKAGE_PIN AV22 [get_ports QSFP1_LPMODE];
#set_property IOSTANDARD LVCMOS12 [get_ports QSFP1_LPMODE];
#set_property PACKAGE_PIN BC19 [get_ports QSFP1_MODPRSL];
#set_property IOSTANDARD LVCMOS12 [get_ports QSFP1_MODPRSL];
#set_property PACKAGE_PIN AY20 [get_ports QSFP1_MODSELL];
#set_property IOSTANDARD LVCMOS12 [get_ports QSFP1_MODSELL];
##set_property PACKAGE_PIN AR21 [get_ports QSFP1_REFCLK_RESET];
##set_property IOSTANDARD LVCMOS12 [get_ports QSFP1_REFCLK_RESET];
#set_property PACKAGE_PIN BC18 [get_ports QSFP1_RESETL];
#set_property IOSTANDARD LVCMOS12 [get_ports QSFP1_RESETL];
#
## QSFP1_TX
#set_property -dict { LOC P7 } [get_ports QSFP1_TX_P[3]]
#set_property -dict { LOC P6 } [get_ports QSFP1_TX_N[3]]
#set_property -dict { LOC R9 } [get_ports QSFP1_TX_P[2]]
#set_property -dict { LOC R8 } [get_ports QSFP1_TX_N[2]]
#set_property -dict { LOC T7 } [get_ports QSFP1_TX_P[1]]
#set_property -dict { LOC T6 } [get_ports QSFP1_TX_N[1]]
#set_property -dict { LOC U9 } [get_ports QSFP1_TX_P[0]]
#set_property -dict { LOC U8 } [get_ports QSFP1_TX_N[0]]
#
## QSFP1_RX
#set_property -dict { LOC P2 } [get_ports QSFP1_RX_P[3]]
#set_property -dict { LOC P1 } [get_ports QSFP1_RX_N[3]]
#set_property -dict { LOC R4 } [get_ports QSFP1_RX_P[2]]
#set_property -dict { LOC R3 } [get_ports QSFP1_RX_N[2]]
#set_property -dict { LOC T2 } [get_ports QSFP1_RX_P[1]]
#set_property -dict { LOC T1 } [get_ports QSFP1_RX_N[1]]
#set_property -dict { LOC U4 } [get_ports QSFP1_RX_P[0]]
#set_property -dict { LOC U3 } [get_ports QSFP1_RX_N[0]]

set_false_path -from [get_clocks clk_out1_clk_wiz_0] -to [get_clocks txoutclk_out[0]]
set_false_path -from [get_clocks clk_out1_clk_wiz_0] -to [get_clocks txoutclk_out[0]_1]
set_false_path -from [get_clocks txoutclk_out[0]  ] -to [get_clocks clk_out1_clk_wiz_0]
set_false_path -from [get_clocks txoutclk_out[0]_1] -to [get_clocks clk_out1_clk_wiz_0]
#set_false_path -from [get_clocks clk_out1_clk_wiz_0_1] -to [get_clocks clk_out1_clk_wiz_0]
#set_false_path -from [get_clocks clk_out1_clk_wiz_0] -to [get_clocks clk_out1_clk_wiz_0_1]

set_false_path -from [get_clocks clk_out1_clk_wiz_1_1] -to [get_clocks txoutclk_out[0]]
set_false_path -from [get_clocks clk_out1_clk_wiz_1_1] -to [get_clocks txoutclk_out[0]_1]
set_false_path -from [get_clocks txoutclk_out[0]] -to [get_clocks clk_out1_clk_wiz_1_1]
set_false_path -from [get_clocks txoutclk_out[0]_1] -to [get_clocks clk_out1_clk_wiz_1_1]

set_false_path -from [get_clocks clk_out1_clk_wiz_1_1] -to [get_clocks clk_out1_clk_wiz_0]
set_false_path -from [get_clocks clk_out1_clk_wiz_0] -to [get_clocks clk_out1_clk_wiz_1_1]
