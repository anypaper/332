// Copyright (C) 2016 
// All rights reserved.
//
//
// @NETFPGA_LICENSE_HEADER_START@
//
// Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
// license agreements.  See the NOTICE file distributed with this work for
// additional information regarding copyright ownership.  NetFPGA licenses this
// file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
// "License"); you may not use this file except in compliance with the
// License.  You may obtain a copy of the License at:
//
//   http://www.netfpga-cic.org
//
// Unless required by applicable law or agreed to in writing, Work distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations under the License.
//
// @NETFPGA_LICENSE_HEADER_END@
//
/*******************************************************************************
 *  File:
 *        prbs.v
 *
 *  Library:
 *        hw/std/cores/delay_v1_0_0
 *
 *  Module:
 *        prbs
 *
 *  Author:
 *        
 * 		
 *  Description:
 *        2^31 prbs module. Prbs polynom is x^31+x^28+1.
 *
 */

module prbs (
	   do,
	   clk,
	   advance,
	   rstn
	   );

parameter WIDTH = 31; //WIDTH is the size of the data bus

output [WIDTH-1:0] do; //data out
 
input clk;
input advance; //indicates when to advance the prbs mechanism
input rstn;
 
reg [30:0] rpg; //current prbs state
wire [WIDTH-1:0] do;
 
wire [30:0] r0; //next prbs state


always @(posedge clk)
 begin
   rpg <= #1 !rstn  ? 31'h1    :                 //save next prbs state
           ~(|rpg)    ? 31'h1    :
           rstn  && advance     ? r0[30:0] : rpg;
   end
 
assign  do   =  ~{r0[WIDTH-1:0]} ; //output data 
//calculate next prbs state
assign r0[30:3] = rpg[30:3] ^ rpg[27:0];
assign r0[2:0] = rpg[ 2:0] ^ r0[30:28];
               
endmodule // qdr_prbs



















 
