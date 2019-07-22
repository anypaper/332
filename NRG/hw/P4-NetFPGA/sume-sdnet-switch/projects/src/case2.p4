//
// Copyright (c) 2019 -
// All rights reserved.
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

#include <core.p4>
#include <sume_switch.p4>

// SUME PORTS
#define NF0 0b0000_0001
#define NF1 0b0000_0100
#define NF2 0b0001_0000
#define NF3 0b0100_0000
#define DRP 0b0000_0000
#define BRD 0b0101_0101
#define BRD_0 0b0101_0100
#define BRD_1 0b0101_0001
#define BRD_2 0b0100_0101
#define BRD_3 0b0001_0101
#define UNK 0b1111_1111

// EXTERN RWI OPs
#define READ_OP     8w0
#define WRITE_OP    8w1
#define RDINC_OP    8w2
#define RDZR_OP     8w3
#define RDTS_OP     8w4
#define ADD_OP      8w5
#define RGTZ_OP     8w6

// PKTSIZE
#define PKTSIZE_INDEX_WIDTH 11 // 2048 REGs
#define PKTSIZE_BUS_WIDTH 8

// CLOCK
#define CLK_INDEX_WIDTH 1 // 2 REGs
#define CLK_BUS_WIDTH 32

// BURST SIZE
#define BSTSIZE_INDEX_WIDTH 2 // 4 REGs
#define BSTSIZE_BUS_WIDTH 10

// BURST GAP
#define BSTGAP_INDEX_WIDTH 2 // 4 REGs
#define BSTGAP_BUS_WIDTH 32

// BURST GAP MEM
#define BGM_INDEX_WIDTH 10 // 1024 REGs
#define BGM_BUS_WIDTH 8

// #############################################################################
//                  EXTERNS
// #############################################################################

// PACKET SIZE: INC (ops: RDINC-1)
// ctrlPort register (#REGs = 2^INDEX_WIDTH) (R 0 / W 1 / I 2)
// WARNING !!! Writing data to highest index resets the extern module
@Xilinx_MaxLatency(3)
@Xilinx_ControlWidth(PKTSIZE_INDEX_WIDTH)
extern void pktsize_reg_rizt(in bit<PKTSIZE_INDEX_WIDTH> index,
                         in bit<PKTSIZE_BUS_WIDTH> newVal,
                         in bit<8> opCode,
                         out bit<PKTSIZE_BUS_WIDTH> result);

// CLOCK: RD + ZR (ops: none)
// ctrlPort register (#REGs = 2^INDEX_WIDTH)
@Xilinx_MaxLatency(3)
@Xilinx_ControlWidth(CLK_INDEX_WIDTH)
extern void clock_reg_rizt(in bit<CLK_INDEX_WIDTH> index,
                         in bit<CLK_BUS_WIDTH> newVal,
                         in bit<8> opCode,
                         out bit<CLK_BUS_WIDTH> result);

// BURST SIZE: RD + INC / ZR (ops: RDINC-1)
// ctrlPort register (#REGs = 2^INDEX_WIDTH)
@Xilinx_MaxLatency(3)
@Xilinx_ControlWidth(BSTSIZE_INDEX_WIDTH)
extern void bstsize_reg_rizt(in bit<BSTSIZE_INDEX_WIDTH> index,
                         in bit<BSTSIZE_BUS_WIDTH> newVal,
                         in bit<8> opCode,
                         out bit<BSTSIZE_BUS_WIDTH> result);

// BURST GAP: RD (ops: RD-0)
// ctrlPort register (#REGs = 2^INDEX_WIDTH)
@Xilinx_MaxLatency(3)
@Xilinx_ControlWidth(BSTGAP_INDEX_WIDTH)
extern void bstgap_reg_rizt(in bit<BSTGAP_INDEX_WIDTH> index,
                         in bit<BSTGAP_BUS_WIDTH> newVal,
                         in bit<8> opCode,
                         out bit<BSTGAP_BUS_WIDTH> result);

// BURST GAP MEM: INC (ops: RDINC-1)
// ctrlPort register (#REGs = 2^INDEX_WIDTH)
@Xilinx_MaxLatency(3)
@Xilinx_ControlWidth(BGM_INDEX_WIDTH)
extern void bgm_reg_rizt(in bit<BGM_INDEX_WIDTH> index,
                         in bit<BGM_BUS_WIDTH> newVal,
                         in bit<8> opCode,
                         out bit<BGM_BUS_WIDTH> result);

// #############################################################################

// Fake header
#define FAKE_SIZE 12
header Fake_h {
    bit<48> field1;
    bit<48> field2;
}

// List of all recognized headers
struct Parsed_packet {
    Fake_h fake;
}

// user defined metadata: can be used to shared information between
// TopParser, TopPipe, and TopDeparser
struct user_metadata_t {
    bit<8>  unused;
}

// digest data to send to cpu if desired. MUST be 80 bits!
struct digest_data_t {
    bit<80>  unused;
}

// Parser Implementation
@Xilinx_MaxPacketRegion(8192)
parser TopParser(packet_in b,
                 out Parsed_packet p,
                 out user_metadata_t user_metadata,
                 out digest_data_t digest_data,
                 inout sume_metadata_t sume_metadata) {

    state start {
        transition accept;
    }

}

// match-action pipeline
control TopPipe(inout Parsed_packet p,
                inout user_metadata_t user_metadata,
                inout digest_data_t digest_data,
                inout sume_metadata_t sume_metadata) {

    // #########################################################################
    //                  TEMPORARY VARIABLES
    // #########################################################################

    // PACKET SIZE
    bit<PKTSIZE_BUS_WIDTH> pktsize_in;
    bit<PKTSIZE_BUS_WIDTH> pktsize_out;

    // CLOCK
    bit<CLK_BUS_WIDTH> clock_in;
    bit<CLK_BUS_WIDTH> clock_out;

    // BURST GAP
    bit<BSTGAP_BUS_WIDTH> bstgap_in;
    bit<BSTGAP_BUS_WIDTH> bstgap_out;

    // BURST SIZE
    bit<BSTSIZE_INDEX_WIDTH> bstsize_indx;
    bit<BSTSIZE_BUS_WIDTH> bstsize_in;
    bit<BSTSIZE_BUS_WIDTH> bstsize_out;
    bit<8> bstsize_op;

    // BURST bstgap_in MEMORY
    bit<BGM_INDEX_WIDTH> bgm_index;
    bit<BGM_BUS_WIDTH> bgm_in;
    bit<BGM_BUS_WIDTH> bgm_out;
    bit<8> bgm_op;

    // #########################################################################

    // TABLE: DONOTHING
    table donothing {
        key = {sume_metadata.meta_0: exact;}

        actions = {
            NoAction;
        }

        size = 64;
        default_action = NoAction;
    }

    apply {

        // APPLY TABLE
        donothing.apply();

        //INCREMENT PACKET SIZE
        pktsize_reg_rizt((sume_metadata.pkt_len[10:0]), pktsize_in, RDINC_OP, pktsize_out);

        // RD + ZERO CLOCK
        clock_reg_rizt(1, clock_in, RDTS_OP, clock_out);

        // RD BURST GAP
        bstgap_reg_rizt(1, bstgap_in, READ_OP, bstgap_out);

        // COMPARE CLOCK & BURST GAP
        if (clock_out < bstgap_out){

          // set increment burst size
          bstsize_op = RDINC_OP;

          // set no increment memory
          bgm_op = READ_OP;

        }else{

          // set zero burst size
          bstsize_op = RDZR_OP;

          // set increment memory
          bgm_op = RDINC_OP;

        }

        // RD + INC/ZR BURST SIZE
        bstsize_reg_rizt(1, bstsize_in, bstsize_op, bstsize_out);

        bgm_index = (bstsize_out+1);

        // INC/NOP BURST GAP MEMORY[BURST SIZE]
        bgm_reg_rizt(bgm_index, bgm_in, bgm_op, bgm_out);

        // SET OUTPUT PORT
        sume_metadata.dst_port = NF1;

    } // apply

} // control

// Deparser Implementation
@Xilinx_MaxPacketRegion(8192)
control TopDeparser(packet_out b,
                    in Parsed_packet p,
                    in user_metadata_t user_metadata,
                    inout digest_data_t digest_data,
                    inout sume_metadata_t sume_metadata) {
    apply {

        b.emit(p);

    }
}


// Instantiate the switch
SimpleSumeSwitch(TopParser(), TopPipe(), TopDeparser()) main;
