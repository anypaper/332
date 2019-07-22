

// CBG Orangepath HPR L/S System

// Verilog output file generated at 19/06/2017 21:16:15
// Kiwi Scientific Acceleration (KiwiC .net/CIL/C# to Verilog/SystemC compiler): Version Alpha 0.3.1x : 11th-May-2017 Unix 3.19.0.64
//  /root/kiwi/kiwipro/kiwic/distro/lib/kiwic.exe emu_stats_pdf.dll -bevelab-default-pause-mode=hard -vnl-resets=synchronous -vnl-roundtrip=disable -res2-loadstore-port-count=0 -restructure2=disable -conerefine=disable -compose=disable -vnl emu_stats_pdf.v
`timescale 1ns/1ns


module Emu(    input clear,
    input rst,
    input [31:0] bw_resolution,
    input [31:0] timer_resolution,
    input [63:0] s_axis_tuser_low,
    input [63:0] s_axis_tuser_hi,
    output reg s_axis_tready,
    input s_axis_tvalid,
    input s_axis_tlast,
    input [31:0] s_axis_tkeep,
    output reg [31:0] processed_bw_mem,
    output reg [31:0] raw_bw_mem,
    output reg [31:0] total_entries,
    
/* portgroup=net batch2 abstractionName=nokind */input clk,
    
/* portgroup=directorate abstractionName=nokind */input reset);

function [7:0] rtl_unsigned_bitextract3;
   input [31:0] arg;
   rtl_unsigned_bitextract3 = $unsigned(arg[7:0]);
   endfunction


function  rtl_unsigned_bitextract2;
   input [31:0] arg;
   rtl_unsigned_bitextract2 = $unsigned(arg[0:0]);
   endfunction


function [31:0] rtl_unsigned_bitextract1;
   input [63:0] arg;
   rtl_unsigned_bitextract1 = $unsigned(arg[31:0]);
   endfunction


function [63:0] rtl_unsigned_extend0;
   input [31:0] arg;
   rtl_unsigned_extend0 = { 32'b0, arg[31:0] };
   endfunction

//
  reg [31:0] fastspilldup18;
  wire [31:0] Emu_T408_start_timer_T408_start_timer_SPILL_257;
  reg [63:0] Emu_T408_start_timer_T408_start_timer_SPILL_258;
  wire [31:0] Emu_T408_start_timer_T408_start_timer_SPILL_256;
  wire [31:0] Emu_T408_start_timer_T408_start_timer_SPILL_259;
  reg T407_Emu_RX_ReceiveFrame_1_2_V_1;
  reg [31:0] T407_Emu_RX_ReceiveFrame_1_2_V_0;
  reg [63:0] T407_Emu_RX_ReceiveFrame_1_2_SPILL_257;
  integer T407_Emu_RX_ReceiveFrame_1_2_SPILL_256;
  reg [31:0] fastspilldup16;
  reg [31:0] fastspilldup14;
  reg [31:0] Emu_T406_update_tables_T406_update_tables_V_0;
  wire [31:0] Emu_T406_update_tables_T406_update_tables_SPILL_257;
  reg [63:0] Emu_T406_update_tables_T406_update_tables_SPILL_258;
  wire [31:0] Emu_T406_update_tables_T406_update_tables_SPILL_256;
  wire [31:0] Emu_T406_update_tables_T406_update_tables_SPILL_259;
  reg [31:0] fastspilldup12;
  reg [31:0] fastspilldup10;
  wire [31:0] Emu_T405_update_bw_tmp_T405_update_bw_tmp_SPILL_257;
  reg [31:0] Emu_T405_update_bw_tmp_T405_update_bw_tmp_SPILL_258;
  wire [31:0] Emu_T405_update_bw_tmp_T405_update_bw_tmp_SPILL_260;
  wire [31:0] Emu_T405_update_bw_tmp_T405_update_bw_tmp_SPILL_261;
  wire [31:0] Emu_T405_update_bw_tmp_T405_update_bw_tmp_SPILL_256;
  wire [31:0] Emu_T405_update_bw_tmp_T405_update_bw_tmp_SPILL_259;
  reg [31:0] Emu_T404_EntryPoint_CZ_0_34_blockrefxxnewobj30;
  reg [31:0] Emu_T404_EntryPoint_CZ_0_33_blockrefxxnewobj28;
  reg [31:0] Emu_T404_EntryPoint_CZ_0_27_blockrefxxnewobj26;
  reg [31:0] Emu_T404_EntryPoint_CZ_0_26_blockrefxxnewobj24;
  reg [31:0] T404_Emu_TABLES_reset_tables_0_23_V_0;
  reg [31:0] Emu_T404_EntryPoint_CZ_0_20_blockrefxxnewobj22;
  reg [31:0] Emu_T404_EntryPoint_CZ_0_16_blockrefxxnewobj20;
  reg [31:0] Emu_T404_EntryPoint_CZ_0_15_blockrefxxnewobj18;
  reg [31:0] Emu_T404_EntryPoint_CZ_0_11_blockrefxxnewobj16;
  reg [31:0] Emu_T404_EntryPoint_CZ_0_7_blockrefxxnewobj14;
  reg [31:0] Emu_T404_EntryPoint_CZ_0_6_blockrefxxnewobj12;
  reg [31:0] Emu_T404_EntryPoint_CZ_0_2_blockrefxxnewobj10;
  reg [31:0] Emu_T404_EntryPoint_T404_EntryPoint_V_6;
  reg [31:0] Emu_T404_EntryPoint_T404_EntryPoint_V_5;
  reg [31:0] Emu_T404_EntryPoint_T404_EntryPoint_V_4;
  reg [31:0] Emu_T404_EntryPoint_T404_EntryPoint_V_3;
  reg [31:0] Emu_T404_EntryPoint_T404_EntryPoint_V_2;
  reg [31:0] Emu_T404_EntryPoint_T404_EntryPoint_V_1;
  reg [31:0] Emu_T404_EntryPoint_T404_EntryPoint_V_0;
  wire [63:0] ktop18;
  reg [31:0] Emu_packet_size;
  reg Emu_new_pkt_arrived;
  reg Emu_new_bw_slot;
  wire [63:0] ktop16;
  reg [31:0] CS_0_7_refxxarray12;
  reg [31:0] CS_0_3_refxxarray10;
  reg [31:0] Emu_TABLES_processed_bw;
  reg [31:0] Emu_TABLES_raw_bw;
  wire [63:0] ktop14;
  reg System_BitConverter_IsLittleEndian;
  wire [63:0] ktop12;
  reg [63:0] KiwiSystem_Kiwi_tnow;
  reg [63:0] KiwiSystem_Kiwi_old_pausemode_value;
  wire [63:0] ktop10;
//
  reg [31:0] A_UINT_CC_raw_bw_raw_bw_SCALbx10_raw_bw_ARA0[1999:0];
  reg [31:0] A_UINT_CC_processed_bw_processed_bw_SCALbx12_processed_bw_ARB0[999:0];
  reg [31:0] A_UINT_CC_SCALbx26_rawentry10;
  reg [31:0] A_UINT_CC_SCALbx26_bwtmp10;
  reg [31:0] A_UINT_CC_SCALbx32_timer12;
  reg signed [31:0] A_SINT_CC_SCALbx48_kv_table;
  reg signed [31:0] A_SINT_CC_ThreadStart_ThreadStart_SCALbx40_kv_table;
  reg signed [31:0] A_SINT_CC_SCALbx50_kv_table;
  reg signed [31:0] A_SINT_CC_ThreadStart_ThreadStart_SCALbx42_kv_table;
  reg signed [31:0] A_SINT_CC_SCALbx26_kv_table;
  reg signed [31:0] A_SINT_CC_SCALbx52_kv_table;
  reg signed [31:0] A_SINT_CC_ThreadStart_ThreadStart_SCALbx44_kv_table;
  reg signed [31:0] A_SINT_CC_SCALbx32_kv_table;
  reg signed [31:0] A_SINT_CC_SCALbx54_kv_table;
  reg signed [31:0] A_SINT_CC_ThreadStart_ThreadStart_SCALbx46_kv_table;
  reg signed [31:0] A_SINT_CC_SCALbx38_kv_table;
  reg [63:0] A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx40_ThreadStart_method10;
  reg [63:0] A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx40_ThreadStart_object10;
  reg [63:0] A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx42_ThreadStart_object10;
  reg [63:0] A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx42_ThreadStart_method10;
  reg [63:0] A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx44_ThreadStart_method10;
  reg [63:0] A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx44_ThreadStart_object10;
  reg [63:0] A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx46_ThreadStart_object10;
  reg [63:0] A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx46_ThreadStart_method10;
  reg [63:0] A_SyThreading_ThreadStart_CC_SCALbx48_entryp10;
  reg [63:0] A_SyThreading_ThreadStart_CC_SCALbx50_entryp10;
  reg [63:0] A_SyThreading_ThreadStart_CC_SCALbx52_entryp10;
  reg [63:0] A_SyThreading_ThreadStart_CC_SCALbx54_entryp10;
//
  reg bevelab18;
  reg [1:0] bevelab16;
  reg bevelab14;
  reg bevelab12;
  reg [1:0] bevelab10;
 always   @(posedge clk )  begin 
      //Start structure HPR anontop/1.0
      if (reset)  begin 
               Emu_T404_EntryPoint_T404_EntryPoint_V_4 <= 32'd0;
               Emu_T404_EntryPoint_CZ_0_20_blockrefxxnewobj22 <= 32'd0;
               A_SINT_CC_SCALbx26_kv_table <= 32'd0;
               Emu_T404_EntryPoint_T404_EntryPoint_V_3 <= 32'd0;
               A_SyThreading_ThreadStart_CC_SCALbx52_entryp10 <= 64'd0;
               Emu_T404_EntryPoint_CZ_0_16_blockrefxxnewobj20 <= 32'd0;
               A_SINT_CC_SCALbx52_kv_table <= 32'd0;
               A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx44_ThreadStart_method10 <= 64'd0;
               A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx44_ThreadStart_object10 <= 64'd0;
               Emu_T404_EntryPoint_CZ_0_15_blockrefxxnewobj18 <= 32'd0;
               A_SINT_CC_ThreadStart_ThreadStart_SCALbx44_kv_table <= 32'd0;
               Emu_T404_EntryPoint_T404_EntryPoint_V_2 <= 32'd0;
               Emu_T404_EntryPoint_CZ_0_11_blockrefxxnewobj16 <= 32'd0;
               A_SINT_CC_SCALbx32_kv_table <= 32'd0;
               Emu_T404_EntryPoint_T404_EntryPoint_V_1 <= 32'd0;
               A_SyThreading_ThreadStart_CC_SCALbx54_entryp10 <= 64'd0;
               Emu_T404_EntryPoint_CZ_0_7_blockrefxxnewobj14 <= 32'd0;
               A_SINT_CC_SCALbx54_kv_table <= 32'd0;
               A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx46_ThreadStart_method10 <= 64'd0;
               A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx46_ThreadStart_object10 <= 64'd0;
               Emu_T404_EntryPoint_CZ_0_6_blockrefxxnewobj12 <= 32'd0;
               A_SINT_CC_ThreadStart_ThreadStart_SCALbx46_kv_table <= 32'd0;
               Emu_T404_EntryPoint_T404_EntryPoint_V_0 <= 32'd0;
               Emu_T404_EntryPoint_CZ_0_2_blockrefxxnewobj10 <= 32'd0;
               A_SINT_CC_SCALbx38_kv_table <= 32'd0;
               KiwiSystem_Kiwi_tnow <= 64'd0;
               KiwiSystem_Kiwi_old_pausemode_value <= 64'd0;
               System_BitConverter_IsLittleEndian <= 32'd0;
               Emu_TABLES_processed_bw <= 32'd0;
               CS_0_7_refxxarray12 <= 32'd0;
               Emu_TABLES_raw_bw <= 32'd0;
               CS_0_3_refxxarray10 <= 32'd0;
               Emu_packet_size <= 32'd0;
               Emu_new_pkt_arrived <= 32'd0;
               Emu_new_bw_slot <= 32'd0;
               processed_bw_mem <= 32'd0;
               raw_bw_mem <= 32'd0;
               A_UINT_CC_processed_bw_processed_bw_SCALbx12_processed_bw_ARB0[32'h0] <= 32'd0;
               A_UINT_CC_raw_bw_raw_bw_SCALbx10_raw_bw_ARA0[32'd0] <= 32'd0;
               A_UINT_CC_processed_bw_processed_bw_SCALbx12_processed_bw_ARB0[$unsigned(32'd1+T404_Emu_TABLES_reset_tables_0_23_V_0)]
               <= 32'd0;

               bevelab10 <= 32'd0;
               Emu_T404_EntryPoint_T404_EntryPoint_V_6 <= 32'd0;
               A_SyThreading_ThreadStart_CC_SCALbx48_entryp10 <= 64'd0;
               Emu_T404_EntryPoint_CZ_0_34_blockrefxxnewobj30 <= 32'd0;
               A_SINT_CC_SCALbx48_kv_table <= 32'd0;
               A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx40_ThreadStart_method10 <= 64'd0;
               A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx40_ThreadStart_object10 <= 64'd0;
               Emu_T404_EntryPoint_CZ_0_33_blockrefxxnewobj28 <= 32'd0;
               A_SINT_CC_ThreadStart_ThreadStart_SCALbx40_kv_table <= 32'd0;
               Emu_T404_EntryPoint_T404_EntryPoint_V_5 <= 32'd0;
               A_SyThreading_ThreadStart_CC_SCALbx50_entryp10 <= 64'd0;
               Emu_T404_EntryPoint_CZ_0_27_blockrefxxnewobj26 <= 32'd0;
               A_SINT_CC_SCALbx50_kv_table <= 32'd0;
               A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx42_ThreadStart_method10 <= 64'd0;
               A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx42_ThreadStart_object10 <= 64'd0;
               Emu_T404_EntryPoint_CZ_0_26_blockrefxxnewobj24 <= 32'd0;
               A_SINT_CC_ThreadStart_ThreadStart_SCALbx42_kv_table <= 32'd0;
               T404_Emu_TABLES_reset_tables_0_23_V_0 <= 32'd0;
               A_UINT_CC_raw_bw_raw_bw_SCALbx10_raw_bw_ARA0[$unsigned(32'd1+T404_Emu_TABLES_reset_tables_0_23_V_0)] <= 32'd0;
               total_entries <= 32'd0;
               A_UINT_CC_SCALbx26_bwtmp10 <= 32'd0;
               A_UINT_CC_SCALbx26_rawentry10 <= 32'd0;
               A_UINT_CC_SCALbx32_timer12 <= 32'd0;
               end 
               else 
          case (bevelab10)
              32'h2/*2:bevelab10*/: if (clear || rst)  begin 
                       total_entries <= 32'h0;
                       A_UINT_CC_SCALbx26_bwtmp10 <= 32'h0;
                       A_UINT_CC_SCALbx26_rawentry10 <= 32'h0;
                       A_UINT_CC_SCALbx32_timer12 <= 32'h0;
                       end 
                      
              32'h1/*1:bevelab10*/:  begin 
                  if (((rst? 1'd1: !clear) || clear) && ($unsigned(32'd1+T404_Emu_TABLES_reset_tables_0_23_V_0)>=32'sd2000))  begin 
                          if ((rst || clear) && ($unsigned(32'd1+T404_Emu_TABLES_reset_tables_0_23_V_0)>=32'sd2000))  begin 
                                   total_entries <= 32'h0;
                                   A_UINT_CC_SCALbx26_bwtmp10 <= 32'h0;
                                   A_UINT_CC_SCALbx26_rawentry10 <= 32'h0;
                                   A_UINT_CC_SCALbx32_timer12 <= 32'h0;
                                   end 
                                   bevelab10 <= 32'h2/*2:bevelab10*/;
                           Emu_T404_EntryPoint_T404_EntryPoint_V_6 <= 32'd0;
                           A_SyThreading_ThreadStart_CC_SCALbx48_entryp10 <= 32'd0;
                           Emu_T404_EntryPoint_CZ_0_34_blockrefxxnewobj30 <= 32'd0;
                           A_SINT_CC_SCALbx48_kv_table <= 32'd0;
                           A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx40_ThreadStart_method10 <= -64'shce7;
                           A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx40_ThreadStart_object10 <= 32'd0;
                           Emu_T404_EntryPoint_CZ_0_33_blockrefxxnewobj28 <= 32'd0;
                           A_SINT_CC_ThreadStart_ThreadStart_SCALbx40_kv_table <= 32'd0;
                           Emu_T404_EntryPoint_T404_EntryPoint_V_5 <= 32'd0;
                           A_SyThreading_ThreadStart_CC_SCALbx50_entryp10 <= 32'd0;
                           Emu_T404_EntryPoint_CZ_0_27_blockrefxxnewobj26 <= 32'd0;
                           A_SINT_CC_SCALbx50_kv_table <= 32'd0;
                           A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx42_ThreadStart_method10 <= -64'shce7;
                           A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx42_ThreadStart_object10 <= 32'd0;
                           Emu_T404_EntryPoint_CZ_0_26_blockrefxxnewobj24 <= 32'd0;
                           A_SINT_CC_ThreadStart_ThreadStart_SCALbx42_kv_table <= 32'd0;
                           T404_Emu_TABLES_reset_tables_0_23_V_0 <= $unsigned(32'd1+T404_Emu_TABLES_reset_tables_0_23_V_0);
                           end 
                          if (($unsigned(32'd1+T404_Emu_TABLES_reset_tables_0_23_V_0)<32'sd1000))  begin 
                           T404_Emu_TABLES_reset_tables_0_23_V_0 <= $unsigned(32'd1+T404_Emu_TABLES_reset_tables_0_23_V_0);
                           A_UINT_CC_processed_bw_processed_bw_SCALbx12_processed_bw_ARB0[$unsigned(32'd1+T404_Emu_TABLES_reset_tables_0_23_V_0
                          )] <= 32'h0;

                           A_UINT_CC_raw_bw_raw_bw_SCALbx10_raw_bw_ARA0[$unsigned(32'd1+T404_Emu_TABLES_reset_tables_0_23_V_0)] <= 32'h0
                          ;

                           end 
                          if (($unsigned(32'd1+T404_Emu_TABLES_reset_tables_0_23_V_0)<32'sd2000) && ($unsigned(32'd1+T404_Emu_TABLES_reset_tables_0_23_V_0
                  )>=32'sd1000))  begin 
                           T404_Emu_TABLES_reset_tables_0_23_V_0 <= $unsigned(32'd1+T404_Emu_TABLES_reset_tables_0_23_V_0);
                           A_UINT_CC_raw_bw_raw_bw_SCALbx10_raw_bw_ARA0[$unsigned(32'd1+T404_Emu_TABLES_reset_tables_0_23_V_0)] <= 32'h0
                          ;

                           end 
                           end 
                  
              32'h0/*0:bevelab10*/:  begin 
                   bevelab10 <= 32'h1/*1:bevelab10*/;
                   T404_Emu_TABLES_reset_tables_0_23_V_0 <= 32'h0;
                   Emu_T404_EntryPoint_T404_EntryPoint_V_4 <= 32'd0;
                   A_UINT_CC_SCALbx26_rawentry10 <= 32'h0;
                   A_UINT_CC_SCALbx26_bwtmp10 <= 32'h0;
                   Emu_T404_EntryPoint_CZ_0_20_blockrefxxnewobj22 <= 32'd0;
                   A_SINT_CC_SCALbx26_kv_table <= 32'd0;
                   Emu_T404_EntryPoint_T404_EntryPoint_V_3 <= 32'd0;
                   A_SyThreading_ThreadStart_CC_SCALbx52_entryp10 <= 32'd0;
                   Emu_T404_EntryPoint_CZ_0_16_blockrefxxnewobj20 <= 32'd0;
                   A_SINT_CC_SCALbx52_kv_table <= 32'd0;
                   A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx44_ThreadStart_method10 <= -64'shce7;
                   A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx44_ThreadStart_object10 <= 32'd0;
                   Emu_T404_EntryPoint_CZ_0_15_blockrefxxnewobj18 <= 32'd0;
                   A_SINT_CC_ThreadStart_ThreadStart_SCALbx44_kv_table <= 32'd0;
                   Emu_T404_EntryPoint_T404_EntryPoint_V_2 <= 32'd0;
                   A_UINT_CC_SCALbx32_timer12 <= 32'h0;
                   Emu_T404_EntryPoint_CZ_0_11_blockrefxxnewobj16 <= 32'd0;
                   A_SINT_CC_SCALbx32_kv_table <= 32'd0;
                   Emu_T404_EntryPoint_T404_EntryPoint_V_1 <= 32'd0;
                   A_SyThreading_ThreadStart_CC_SCALbx54_entryp10 <= 32'd0;
                   Emu_T404_EntryPoint_CZ_0_7_blockrefxxnewobj14 <= 32'd0;
                   A_SINT_CC_SCALbx54_kv_table <= 32'd0;
                   A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx46_ThreadStart_method10 <= -64'shce7;
                   A_CTL_object_CC_ThreadStart_ThreadStart_SCALbx46_ThreadStart_object10 <= 32'd0;
                   Emu_T404_EntryPoint_CZ_0_6_blockrefxxnewobj12 <= 32'd0;
                   A_SINT_CC_ThreadStart_ThreadStart_SCALbx46_kv_table <= 32'd0;
                   Emu_T404_EntryPoint_T404_EntryPoint_V_0 <= 32'd0;
                   Emu_T404_EntryPoint_CZ_0_2_blockrefxxnewobj10 <= 32'd0;
                   A_SINT_CC_SCALbx38_kv_table <= 32'd0;
                   KiwiSystem_Kiwi_tnow <= 64'h0;
                   KiwiSystem_Kiwi_old_pausemode_value <= 64'h2;
                   System_BitConverter_IsLittleEndian <= 1'h1;
                   Emu_TABLES_processed_bw <= 32'd0;
                   CS_0_7_refxxarray12 <= 32'd0;
                   Emu_TABLES_raw_bw <= 32'd0;
                   CS_0_3_refxxarray10 <= 32'd0;
                   Emu_packet_size <= 32'h0;
                   Emu_new_pkt_arrived <= 1'h0;
                   Emu_new_bw_slot <= 1'h0;
                   processed_bw_mem <= 32'h0;
                   raw_bw_mem <= 32'h0;
                   total_entries <= 32'h0;
                   A_UINT_CC_processed_bw_processed_bw_SCALbx12_processed_bw_ARB0[32'h0] <= 32'h0;
                   A_UINT_CC_raw_bw_raw_bw_SCALbx10_raw_bw_ARA0[32'd0] <= 32'h0;
                   end 
                  endcase
      if (reset)  begin 
               bevelab12 <= 32'd0;
               A_UINT_CC_SCALbx32_timer12 <= 32'd0;
               Emu_T408_start_timer_T408_start_timer_SPILL_258 <= 64'd0;
               fastspilldup18 <= 32'd0;
               Emu_new_bw_slot <= 32'd0;
               end 
               else 
          case (bevelab12)
              32'h1/*1:bevelab12*/:  begin 
                   A_UINT_CC_SCALbx32_timer12 <= $unsigned(((timer_resolution==A_UINT_CC_SCALbx32_timer12)? 64'h0: rtl_unsigned_extend0(32'd1
                  )+rtl_unsigned_extend0(A_UINT_CC_SCALbx32_timer12)));

                   Emu_T408_start_timer_T408_start_timer_SPILL_258 <= ((timer_resolution==A_UINT_CC_SCALbx32_timer12)? 64'h0: rtl_unsigned_extend0(32'd1
                  )+rtl_unsigned_extend0(A_UINT_CC_SCALbx32_timer12));

                   fastspilldup18 <= 32'd0;
                   Emu_new_bw_slot <= (timer_resolution==A_UINT_CC_SCALbx32_timer12);
                   end 
                  
              32'h0/*0:bevelab12*/:  begin 
                   bevelab12 <= 32'h1/*1:bevelab12*/;
                   A_UINT_CC_SCALbx32_timer12 <= $unsigned(((timer_resolution==A_UINT_CC_SCALbx32_timer12)? 64'h0: rtl_unsigned_extend0(32'd1
                  )+rtl_unsigned_extend0(A_UINT_CC_SCALbx32_timer12)));

                   Emu_T408_start_timer_T408_start_timer_SPILL_258 <= ((timer_resolution==A_UINT_CC_SCALbx32_timer12)? 64'h0: rtl_unsigned_extend0(32'd1
                  )+rtl_unsigned_extend0(A_UINT_CC_SCALbx32_timer12));

                   fastspilldup18 <= 32'd0;
                   Emu_new_bw_slot <= (timer_resolution==A_UINT_CC_SCALbx32_timer12);
                   end 
                  endcase
      if (reset)  begin 
               bevelab14 <= 32'd0;
               T407_Emu_RX_ReceiveFrame_1_2_SPILL_257 <= 64'd0;
               T407_Emu_RX_ReceiveFrame_1_2_SPILL_256 <= 32'd0;
               Emu_packet_size <= 32'd0;
               T407_Emu_RX_ReceiveFrame_1_2_V_1 <= 32'd0;
               T407_Emu_RX_ReceiveFrame_1_2_V_0 <= 32'd0;
               s_axis_tready <= 32'd0;
               Emu_new_pkt_arrived <= 32'd0;
               end 
               else 
          case (bevelab14)
              32'h1/*1:bevelab14*/:  begin 
                  if (s_axis_tvalid && !T407_Emu_RX_ReceiveFrame_1_2_V_1)  begin 
                           T407_Emu_RX_ReceiveFrame_1_2_V_0 <= rtl_unsigned_bitextract1((s_axis_tvalid && !T407_Emu_RX_ReceiveFrame_1_2_V_1
                          ? (s_axis_tvalid && !s_axis_tlast && !T407_Emu_RX_ReceiveFrame_1_2_V_1? 32'd1+(s_axis_tvalid && !T407_Emu_RX_ReceiveFrame_1_2_V_1
                          ? 32'h0: T407_Emu_RX_ReceiveFrame_1_2_V_0): 64'h0): T407_Emu_RX_ReceiveFrame_1_2_SPILL_257));

                           T407_Emu_RX_ReceiveFrame_1_2_SPILL_257 <= (s_axis_tvalid && !s_axis_tlast && !T407_Emu_RX_ReceiveFrame_1_2_V_1
                          ? rtl_unsigned_extend0(32'd1)+rtl_unsigned_extend0((s_axis_tvalid && !T407_Emu_RX_ReceiveFrame_1_2_V_1? 32'h0
                          : T407_Emu_RX_ReceiveFrame_1_2_V_0)): 64'h0);

                           T407_Emu_RX_ReceiveFrame_1_2_V_1 <= rtl_unsigned_bitextract2((s_axis_tvalid && !T407_Emu_RX_ReceiveFrame_1_2_V_1
                          ? (s_axis_tvalid && s_axis_tlast && !T407_Emu_RX_ReceiveFrame_1_2_V_1? 1'd0: s_axis_tvalid): T407_Emu_RX_ReceiveFrame_1_2_SPILL_256
                          ));

                           T407_Emu_RX_ReceiveFrame_1_2_SPILL_256 <= (s_axis_tvalid && s_axis_tlast && !T407_Emu_RX_ReceiveFrame_1_2_V_1
                          ? 32'sd0: s_axis_tvalid);

                           Emu_new_pkt_arrived <= 32'd1;
                           Emu_packet_size <= rtl_unsigned_bitextract1(64'sh_ffff&s_axis_tuser_low);
                           s_axis_tready <= 1'h1;
                           end 
                          if (s_axis_tvalid && T407_Emu_RX_ReceiveFrame_1_2_V_1)  begin 
                           T407_Emu_RX_ReceiveFrame_1_2_V_0 <= rtl_unsigned_bitextract1((s_axis_tvalid && T407_Emu_RX_ReceiveFrame_1_2_V_1
                          ? (s_axis_tvalid && !s_axis_tlast && T407_Emu_RX_ReceiveFrame_1_2_V_1? 32'd1+T407_Emu_RX_ReceiveFrame_1_2_V_0
                          : 64'h0): T407_Emu_RX_ReceiveFrame_1_2_SPILL_257));

                           T407_Emu_RX_ReceiveFrame_1_2_SPILL_257 <= (s_axis_tvalid && !s_axis_tlast && T407_Emu_RX_ReceiveFrame_1_2_V_1
                          ? rtl_unsigned_extend0(32'd1)+rtl_unsigned_extend0(T407_Emu_RX_ReceiveFrame_1_2_V_0): 64'h0);

                           T407_Emu_RX_ReceiveFrame_1_2_V_1 <= rtl_unsigned_bitextract2((s_axis_tvalid && T407_Emu_RX_ReceiveFrame_1_2_V_1
                          ? (s_axis_tvalid && s_axis_tlast && T407_Emu_RX_ReceiveFrame_1_2_V_1? 1'd0: s_axis_tvalid): T407_Emu_RX_ReceiveFrame_1_2_SPILL_256
                          ));

                           T407_Emu_RX_ReceiveFrame_1_2_SPILL_256 <= (s_axis_tvalid && s_axis_tlast && T407_Emu_RX_ReceiveFrame_1_2_V_1
                          ? 32'sd0: s_axis_tvalid);

                           Emu_new_pkt_arrived <= ((s_axis_tvalid? T407_Emu_RX_ReceiveFrame_1_2_V_1: 1'd1) || !T407_Emu_RX_ReceiveFrame_1_2_V_1
                          ) && (32'd0==T407_Emu_RX_ReceiveFrame_1_2_V_0);

                           Emu_packet_size <= rtl_unsigned_bitextract1(64'sh_ffff&s_axis_tuser_low);
                           end 
                          if (!s_axis_tvalid && !T407_Emu_RX_ReceiveFrame_1_2_V_1)  begin 
                           Emu_new_pkt_arrived <= 1'h0;
                           T407_Emu_RX_ReceiveFrame_1_2_V_1 <= 1'h1;
                           T407_Emu_RX_ReceiveFrame_1_2_V_0 <= 32'h0;
                           s_axis_tready <= 1'h1;
                           end 
                          if (!s_axis_tvalid && T407_Emu_RX_ReceiveFrame_1_2_V_1)  Emu_new_pkt_arrived <= 1'h0;
                       end 
                  
              32'h0/*0:bevelab14*/: if (s_axis_tvalid)  begin 
                       bevelab14 <= 32'h1/*1:bevelab14*/;
                       T407_Emu_RX_ReceiveFrame_1_2_V_0 <= rtl_unsigned_bitextract1((s_axis_tvalid? (s_axis_tvalid && !s_axis_tlast? 32'd1
                      +(s_axis_tvalid? 32'h0: T407_Emu_RX_ReceiveFrame_1_2_V_0): 64'h0): T407_Emu_RX_ReceiveFrame_1_2_SPILL_257));

                       T407_Emu_RX_ReceiveFrame_1_2_SPILL_257 <= (s_axis_tvalid && !s_axis_tlast? rtl_unsigned_extend0(32'd1)+rtl_unsigned_extend0((s_axis_tvalid
                      ? 32'h0: T407_Emu_RX_ReceiveFrame_1_2_V_0)): 64'h0);

                       T407_Emu_RX_ReceiveFrame_1_2_V_1 <= rtl_unsigned_bitextract2((s_axis_tvalid? (s_axis_tvalid && s_axis_tlast? 1'd0
                      : s_axis_tvalid): T407_Emu_RX_ReceiveFrame_1_2_SPILL_256));

                       T407_Emu_RX_ReceiveFrame_1_2_SPILL_256 <= (s_axis_tvalid && s_axis_tlast? 32'sd0: s_axis_tvalid);
                       Emu_new_pkt_arrived <= 32'd1;
                       Emu_packet_size <= rtl_unsigned_bitextract1(64'sh_ffff&s_axis_tuser_low);
                       s_axis_tready <= 1'h1;
                       end 
                       else  begin 
                       bevelab14 <= 32'h1/*1:bevelab14*/;
                       Emu_new_pkt_arrived <= 1'h0;
                       T407_Emu_RX_ReceiveFrame_1_2_V_1 <= 1'h1;
                       T407_Emu_RX_ReceiveFrame_1_2_V_0 <= 32'h0;
                       s_axis_tready <= 1'h1;
                       end 
                      endcase
      if (reset)  begin 
               fastspilldup16 <= 32'd0;
               processed_bw_mem <= 32'd0;
               A_UINT_CC_processed_bw_processed_bw_SCALbx12_processed_bw_ARB0[$unsigned((A_UINT_CC_SCALbx26_bwtmp10>>(32'sd31&rtl_unsigned_bitextract3(bw_resolution
              ))))] <= 32'd0;

               bevelab16 <= 32'd0;
               Emu_T406_update_tables_T406_update_tables_V_0 <= 32'd0;
               total_entries <= 32'd0;
               A_UINT_CC_SCALbx26_rawentry10 <= 32'd0;
               Emu_T406_update_tables_T406_update_tables_SPILL_258 <= 64'd0;
               fastspilldup14 <= 32'd0;
               A_UINT_CC_raw_bw_raw_bw_SCALbx10_raw_bw_ARA0[A_UINT_CC_SCALbx26_rawentry10] <= 32'd0;
               end 
               else 
          case (bevelab16)
              32'h2/*2:bevelab16*/: if (Emu_new_bw_slot)  begin 
                       bevelab16 <= 32'h1/*1:bevelab16*/;
                       Emu_T406_update_tables_T406_update_tables_V_0 <= $unsigned(A_UINT_CC_processed_bw_processed_bw_SCALbx12_processed_bw_ARB0
                      [$unsigned((A_UINT_CC_SCALbx26_bwtmp10>>(32'sd31&rtl_unsigned_bitextract3(bw_resolution))))]);

                       total_entries <= $unsigned(32'd1+total_entries);
                       A_UINT_CC_SCALbx26_rawentry10 <= rtl_unsigned_bitextract1((Emu_new_bw_slot? (Emu_new_bw_slot && (32'h7d0/*2000:USA10*/!=
                      A_UINT_CC_SCALbx26_rawentry10)? 32'd1+A_UINT_CC_SCALbx26_rawentry10: 64'h0): Emu_T406_update_tables_T406_update_tables_SPILL_258
                      ));

                       Emu_T406_update_tables_T406_update_tables_SPILL_258 <= (Emu_new_bw_slot && (32'h7d0/*2000:USA10*/!=A_UINT_CC_SCALbx26_rawentry10
                      )? rtl_unsigned_extend0(32'd1)+rtl_unsigned_extend0(A_UINT_CC_SCALbx26_rawentry10): 64'h0);

                       fastspilldup14 <= 32'd0;
                       A_UINT_CC_raw_bw_raw_bw_SCALbx10_raw_bw_ARA0[A_UINT_CC_SCALbx26_rawentry10] <= A_UINT_CC_SCALbx26_bwtmp10;
                       end 
                      
              32'h1/*1:bevelab16*/:  begin 
                   bevelab16 <= 32'h2/*2:bevelab16*/;
                   Emu_T406_update_tables_T406_update_tables_V_0 <= $unsigned(32'd1+Emu_T406_update_tables_T406_update_tables_V_0);
                   fastspilldup16 <= Emu_T406_update_tables_T406_update_tables_V_0;
                   processed_bw_mem <= Emu_T406_update_tables_T406_update_tables_V_0;
                   A_UINT_CC_processed_bw_processed_bw_SCALbx12_processed_bw_ARB0[$unsigned((A_UINT_CC_SCALbx26_bwtmp10>>(32'sd31&rtl_unsigned_bitextract3(bw_resolution
                  ))))] <= Emu_T406_update_tables_T406_update_tables_V_0;

                   end 
                  
              32'h0/*0:bevelab16*/: if (Emu_new_bw_slot)  begin 
                       bevelab16 <= 32'h1/*1:bevelab16*/;
                       Emu_T406_update_tables_T406_update_tables_V_0 <= $unsigned(A_UINT_CC_processed_bw_processed_bw_SCALbx12_processed_bw_ARB0
                      [$unsigned((A_UINT_CC_SCALbx26_bwtmp10>>(32'sd31&rtl_unsigned_bitextract3(bw_resolution))))]);

                       total_entries <= $unsigned(32'd1+total_entries);
                       A_UINT_CC_SCALbx26_rawentry10 <= rtl_unsigned_bitextract1((Emu_new_bw_slot? (Emu_new_bw_slot && (32'h7d0/*2000:USA10*/!=
                      A_UINT_CC_SCALbx26_rawentry10)? 32'd1+A_UINT_CC_SCALbx26_rawentry10: 64'h0): Emu_T406_update_tables_T406_update_tables_SPILL_258
                      ));

                       Emu_T406_update_tables_T406_update_tables_SPILL_258 <= (Emu_new_bw_slot && (32'h7d0/*2000:USA10*/!=A_UINT_CC_SCALbx26_rawentry10
                      )? rtl_unsigned_extend0(32'd1)+rtl_unsigned_extend0(A_UINT_CC_SCALbx26_rawentry10): 64'h0);

                       fastspilldup14 <= 32'd0;
                       A_UINT_CC_raw_bw_raw_bw_SCALbx10_raw_bw_ARA0[A_UINT_CC_SCALbx26_rawentry10] <= A_UINT_CC_SCALbx26_bwtmp10;
                       end 
                       else  begin 
                       bevelab16 <= 32'h2/*2:bevelab16*/;
                       Emu_T406_update_tables_T406_update_tables_V_0 <= 32'h0;
                       end 
                      endcase
      if (reset)  begin 
               bevelab18 <= 32'd0;
               A_UINT_CC_SCALbx26_bwtmp10 <= 32'd0;
               Emu_T405_update_bw_tmp_T405_update_bw_tmp_SPILL_258 <= 32'd0;
               fastspilldup12 <= 32'd0;
               fastspilldup10 <= 32'd0;
               end 
               else 
          case (bevelab18)
              32'h1/*1:bevelab18*/:  begin 
                  if (!Emu_new_bw_slot)  fastspilldup12 <= 32'd0;
                       A_UINT_CC_SCALbx26_bwtmp10 <= $unsigned((!Emu_new_bw_slot && !Emu_new_pkt_arrived? A_UINT_CC_SCALbx26_bwtmp10: (!Emu_new_bw_slot
                   && Emu_new_pkt_arrived? Emu_packet_size+A_UINT_CC_SCALbx26_bwtmp10: 32'h0)));

                   Emu_T405_update_bw_tmp_T405_update_bw_tmp_SPILL_258 <= (!Emu_new_bw_slot && !Emu_new_pkt_arrived? A_UINT_CC_SCALbx26_bwtmp10
                  : (!Emu_new_bw_slot && Emu_new_pkt_arrived? Emu_packet_size+A_UINT_CC_SCALbx26_bwtmp10: 32'h0));

                   fastspilldup10 <= 32'd0;
                   end 
                  
              32'h0/*0:bevelab18*/:  begin 
                  if (!Emu_new_bw_slot)  fastspilldup12 <= 32'd0;
                       bevelab18 <= 32'h1/*1:bevelab18*/;
                   A_UINT_CC_SCALbx26_bwtmp10 <= $unsigned((!Emu_new_bw_slot && !Emu_new_pkt_arrived? A_UINT_CC_SCALbx26_bwtmp10: (!Emu_new_bw_slot
                   && Emu_new_pkt_arrived? Emu_packet_size+A_UINT_CC_SCALbx26_bwtmp10: 32'h0)));

                   Emu_T405_update_bw_tmp_T405_update_bw_tmp_SPILL_258 <= (!Emu_new_bw_slot && !Emu_new_pkt_arrived? A_UINT_CC_SCALbx26_bwtmp10
                  : (!Emu_new_bw_slot && Emu_new_pkt_arrived? Emu_packet_size+A_UINT_CC_SCALbx26_bwtmp10: 32'h0));

                   fastspilldup10 <= 32'd0;
                   end 
                  endcase
      //End structure HPR anontop/1.0


       end 
      

// 2 vectors of width 2
// 7 vectors of width 1
// 17 vectors of width 64
// 46 vectors of width 32
// 3000 array locations of width 32
// 32 bits in scalar variables
// Total state bits in module = 98603 bits.
// 672 continuously assigned (wire/non-state) bits 
// Total number of leaf cells = 0
endmodule

//  
// LCP delay estimations included: turn off with -vnl-lcp-delay-estimate=disable
//HPR L/S (orangepath) auxiliary reports.
//KiwiC compilation report
//Kiwi Scientific Acceleration (KiwiC .net/CIL/C# to Verilog/SystemC compiler): Version Alpha 0.3.1x : 11th-May-2017
//19/06/2017 21:16:12
//Cmd line args:  /root/kiwi/kiwipro/kiwic/distro/lib/kiwic.exe emu_stats_pdf.dll -bevelab-default-pause-mode=hard -vnl-resets=synchronous -vnl-roundtrip=disable -res2-loadstore-port-count=0 -restructure2=disable -conerefine=disable -compose=disable -vnl emu_stats_pdf.v


//----------------------------------------------------------

//Report from Abbreviation:::
//    setting up abbreviation SyThreading for prefix System/Threading
//

//----------------------------------------------------------

//Report from Abbreviation:::
//    setting up abbreviation @$SyThreading for prefix @/$star1$/System/Threading
//

//----------------------------------------------------------

//Report from Abbreviation:::
//    setting up abbreviation $SyThreading for prefix $star1$/System/Threading
//

//----------------------------------------------------------

//Report from Abbreviation:::
//    setting up abbreviation ETuTup_SPILL for prefix Emu/T405/update_bw_tmp/T405/update_bw_tmp/_SPILL
//

//----------------------------------------------------------

//Report from Abbreviation:::
//    setting up abbreviation ETuTupSPILL10 for prefix Emu/T406/update_tables/T406/update_tables/_SPILL
//

//----------------------------------------------------------

//Report from Abbreviation:::
//    setting up abbreviation TERXR1._SPILL for prefix T407/Emu/RX/ReceiveFrame/1.2/_SPILL
//

//----------------------------------------------------------

//Report from Abbreviation:::
//    setting up abbreviation ETsTst_SPILL for prefix Emu/T408/start_timer/T408/start_timer/_SPILL
//

//----------------------------------------------------------

//Report from KiwiC-fe.rpt:::
//KiwiC: front end input processing of class or method called KiwiSystem/Kiwi
//
//root_walk start thread at a static method (used as an entry point). Method name=.cctor uid=cctor10
//
//KiwiC start_thread (or entry point) id=cctor10
//
//Root method elaborated: specificf=S_kickoff_collate leftover=1+0
//
//KiwiC: front end input processing of class or method called System/BitConverter
//
//root_walk start thread at a static method (used as an entry point). Method name=.cctor uid=cctor12
//
//KiwiC start_thread (or entry point) id=cctor12
//
//Root method elaborated: specificf=S_kickoff_collate leftover=1+1
//
//KiwiC: front end input processing of class or method called Emu/TABLES
//
//root_walk start thread at a static method (used as an entry point). Method name=.cctor uid=cctor16
//
//KiwiC start_thread (or entry point) id=cctor16
//
//Root method elaborated: specificf=S_kickoff_collate leftover=1+2
//
//KiwiC: front end input processing of class or method called Emu
//
//root_walk start thread at a static method (used as an entry point). Method name=.cctor uid=cctor14
//
//KiwiC start_thread (or entry point) id=cctor14
//
//Root method elaborated: specificf=S_kickoff_collate leftover=1+3
//
//KiwiC: front end input processing of class or method called Emu
//
//root_compiler: start elaborating class 'Emu'
//
//elaborating class 'Emu'
//
//compiling static method as entry point: style=Root idl=Emu/EntryPoint
//
//Performing root elaboration of method EntryPoint
//
//KiwiC start_thread (or entry point) id=EntryPoint10
//
//Logging start thread entry point = CE_region<&(CTL_record(System.Threading.ThreadStart,...))>(System.Threading.ThreadStart.412016%System.Threading.ThreadStart%412016%28, nemtok=Emu/T404/EntryPoint/CZ:0:6/item12, ats={marker=wondtoken, constant=true}): USER_THREAD1(CE_conv(CTL_object, CE_region<&(CTL_record(Emu.RX,...))>(Emu.RX.412000%Emu.RX%412000%12, nemtok=Emu/T404/EntryPoint/CZ:0:2/item10, ats={marker=wondtoken, constant=true})), CE_conv(CTL_object, CE_region<CT_arr(CTL_object, <unspec>)>(Emu.RX.start_rx%Emu.RX.start_rx%-3303%None, nemtok=U$D/Emu.RX.start_rx%Emu.RX.start_rx%-3303%None, ats={marker=wondtoken, constant=true, rnsc=true})), ())
//
//Logging start thread entry point = CE_region<&(CTL_record(System.Threading.ThreadStart,...))>(System.Threading.ThreadStart.412088%System.Threading.ThreadStart%412088%28, nemtok=Emu/T404/EntryPoint/CZ:0:15/item18, ats={marker=wondtoken, constant=true}): USER_THREAD1(CE_conv(CTL_object, CE_region<&(CTL_record(Emu.TIMER,...))>(Emu.TIMER.412072%Emu.TIMER%412072%16, nemtok=Emu/T404/EntryPoint/CZ:0:11/item16, ats={marker=wondtoken, constant=true})), CE_conv(CTL_object, CE_region<CT_arr(CTL_object, <unspec>)>(Emu.TIMER.start_timer%Emu.TIMER.start_timer%-3303%None, nemtok=U$D/Emu.TIMER.start_timer%Emu.TIMER.start_timer%-3303%None, ats={marker=wondtoken, constant=true, rnsc=true})), ())
//
//Logging start thread entry point = CE_region<&(CTL_record(System.Threading.ThreadStart,...))>(System.Threading.ThreadStart.412184%System.Threading.ThreadStart%412184%28, nemtok=Emu/T404/EntryPoint/CZ:0:26/item24, ats={marker=wondtoken, constant=true}): USER_THREAD1(CE_conv(CTL_object, CE_region<&(CTL_record(Emu.TABLES,...))>(Emu.TABLES.412144%Emu.TABLES%412144%36, nemtok=Emu/T404/EntryPoint/CZ:0:20/item22, ats={marker=wondtoken, constant=true})), CE_conv(CTL_object, CE_region<CT_arr(CTL_object, <unspec>)>(Emu.TABLES.update_bw_tmp%Emu.TABLES.update_bw_tmp%-3303%None, nemtok=U$D/Emu.TABLES.update_bw_tmp%Emu.TABLES.update_bw_tmp%-3303%None, ats={marker=wondtoken, constant=true, rnsc=true})), ())
//
//Logging start thread entry point = CE_region<&(CTL_record(System.Threading.ThreadStart,...))>(System.Threading.ThreadStart.412240%System.Threading.ThreadStart%412240%28, nemtok=Emu/T404/EntryPoint/CZ:0:33/item28, ats={marker=wondtoken, constant=true}): USER_THREAD1(CE_conv(CTL_object, CE_region<&(CTL_record(Emu.TABLES,...))>(Emu.TABLES.412144%Emu.TABLES%412144%36, nemtok=Emu/T404/EntryPoint/CZ:0:20/item22, ats={marker=wondtoken, constant=true})), CE_conv(CTL_object, CE_region<CT_arr(CTL_object, <unspec>)>(Emu.TABLES.update_tables%Emu.TABLES.update_tables%-3303%None, nemtok=U$D/Emu.TABLES.update_tables%Emu.TABLES.update_tables%-3303%None, ats={marker=wondtoken, constant=true, rnsc=true})), ())
//
//KiwiC start_thread (or entry point) id=updatebwtmp10
//
//KiwiC start_thread (or entry point) id=updatetables10
//
//KiwiC start_thread (or entry point) id=startrx10
//
//KiwiC start_thread (or entry point) id=starttimer10
//
//root_compiler class done: Emu
//
//Report of all settings used from the recipe or command line:
//
//   kiwife-directorate-ready-flag=absent
//
//   kiwife-directorate-endmode=auto-restart
//
//   kiwife-directorate-startmode=self-start
//
//   cil-uwind-budget=10000
//
//   kiwic-cil-dump=disable
//
//   kiwic-kcode-dump=disable
//
//   kiwic-register-colours=disable
//
//   array-4d-name=KIWIARRAY4D
//
//   array-3d-name=KIWIARRAY3D
//
//   array-2d-name=KIWIARRAY2D
//
//   kiwi-dll=Kiwi.dll
//
//   kiwic-dll=Kiwic.dll
//
//   kiwic-zerolength-arrays=disable
//
//   kiwifefpgaconsole-default=enable
//
//   kiwife-directorate-style=basic
//
//   postgen-optimise=enable
//
//   kiwife-cil-loglevel=20
//
//   kiwife-ataken-loglevel=20
//
//   kiwife-gtrace-loglevel=20
//
//   kiwife-firstpass-loglevel=20
//
//   kiwife-overloads-loglevel=20
//
//   root=$attributeroot
//
//   srcfile=emu_stats_pdf.dll
//
//   kiwic-autodispose=disable
//
//END OF KIWIC REPORT FILE
//

//----------------------------------------------------------

//Report from Abbreviation:::
//    setting up abbreviation SThThread for prefix System/Threading/Thread
//

//----------------------------------------------------------

//Report from Abbreviation:::
//    setting up abbreviation SThThreadStart for prefix System/Threading/ThreadStart
//

//----------------------------------------------------------

//Report from Abbreviation:::
//    setting up abbreviation EmTABLES for prefix Emu/TABLES
//

//----------------------------------------------------------

//Report from Abbreviation:::
//    setting up abbreviation EmTIMER for prefix Emu/TIMER
//

//----------------------------------------------------------

//Report from Abbreviation:::
//    setting up abbreviation EmRX for prefix Emu/RX
//

//----------------------------------------------------------

//Report from verilog_render:::
//2 vectors of width 2
//
//7 vectors of width 1
//
//17 vectors of width 64
//
//46 vectors of width 32
//
//3000 array locations of width 32
//
//32 bits in scalar variables
//
//Total state bits in module = 98603 bits.
//
//672 continuously assigned (wire/non-state) bits 
//
//Total number of leaf cells = 0
//

//Major Statistics Report:
//Thread .cctor uid=cctor10 has 3 CIL instructions in 1 basic blocks
//Thread .cctor uid=cctor12 has 2 CIL instructions in 1 basic blocks
//Thread .cctor uid=cctor16 has 7 CIL instructions in 1 basic blocks
//Thread .cctor uid=cctor14 has 7 CIL instructions in 1 basic blocks
//Thread EntryPoint uid=EntryPoint10 has 57 CIL instructions in 9 basic blocks
//Thread update_bw_tmp uid=updatebwtmp10 has 23 CIL instructions in 6 basic blocks
//Thread update_tables uid=updatetables10 has 26 CIL instructions in 7 basic blocks
//Thread start_rx uid=startrx10 has 32 CIL instructions in 13 basic blocks
//Thread start_timer uid=starttimer10 has 16 CIL instructions in 4 basic blocks
//Thread mpc10 has 3 bevelab control states (pauses)
//Thread mpc12 has 2 bevelab control states (pauses)
//Thread mpc14 has 2 bevelab control states (pauses)
//Thread mpc16 has 3 bevelab control states (pauses)
//Thread mpc18 has 2 bevelab control states (pauses)
// eof (HPR L/S Verilog)
