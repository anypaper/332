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

// CLOCK
#define CLK_INDEX_WIDTH 1 // 2 REGs
#define CLK_BUS_WIDTH 32

// TIME UNIT
#define TU_INDEX_WIDTH 1 // 2 REGs
#define TU_BUS_WIDTH 32

// BW MEMORY
#define BWMEM_INDEX_WIDTH 1 // 2 REGs
#define BWMEM_BUS_WIDTH 64

// PKT MEMORY
#define PKTMEM_INDEX_WIDTH 1 // 2 REGs
#define PKTMEM_BUS_WIDTH 64

// PKT COUNTER
#define PKTCTR_INDEX_WIDTH 1 // 2 REGs
#define PKTCTR_BUS_WIDTH 32

// BYTES COUNTER
#define BYTESCTR_INDEX_WIDTH 1 // 2 REGs
#define BYTESCTR_BUS_WIDTH 32

// #############################################################################
//                  EXTERNS
// #############################################################################

// CLOCK
@Xilinx_MaxLatency(3)
@Xilinx_ControlWidth(CLK_INDEX_WIDTH)
extern void clock_reg_rizt(in bit<CLK_INDEX_WIDTH> index,
                         in bit<CLK_BUS_WIDTH> newVal,
                         in bit<8> opCode,
                         out bit<CLK_BUS_WIDTH> result);

// TIME UNIT
@Xilinx_MaxLatency(3)
@Xilinx_ControlWidth(TU_INDEX_WIDTH)
extern void tu_reg_rizt(in bit<TU_INDEX_WIDTH> index,
                         in bit<TU_BUS_WIDTH> newVal,
                         in bit<8> opCode,
                         out bit<TU_BUS_WIDTH> result);

// BW MEMORY
@Xilinx_MaxLatency(3)
@Xilinx_ControlWidth(BWMEM_INDEX_WIDTH)
extern void bwmem_reg_rizt(in bit<BWMEM_INDEX_WIDTH> index,
                         in bit<BWMEM_BUS_WIDTH> newVal,
                         in bit<8> opCode,
                         out bit<BWMEM_BUS_WIDTH> result);

// PKT MEMORY
@Xilinx_MaxLatency(3)
@Xilinx_ControlWidth(PKTMEM_INDEX_WIDTH)
extern void pktmem_reg_rizt(in bit<PKTMEM_INDEX_WIDTH> index,
                         in bit<PKTMEM_BUS_WIDTH> newVal,
                         in bit<8> opCode,
                         out bit<PKTMEM_BUS_WIDTH> result);

// PKT COUNTER
@Xilinx_MaxLatency(3)
@Xilinx_ControlWidth(PKTCTR_INDEX_WIDTH)
extern void pktctr_reg_rizt(in bit<PKTCTR_INDEX_WIDTH> index,
                         in bit<PKTCTR_BUS_WIDTH> newVal,
                         in bit<8> opCode,
                         out bit<PKTCTR_BUS_WIDTH> result);

// BYTES COUNTER
@Xilinx_MaxLatency(3)
@Xilinx_ControlWidth(BYTESCTR_INDEX_WIDTH)
extern void bytesctr_reg_rizt(in bit<BYTESCTR_INDEX_WIDTH> index,
                         in bit<BYTESCTR_BUS_WIDTH> newVal,
                         in bit<8> opCode,
                         out bit<BYTESCTR_BUS_WIDTH> result);

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

    // CLOCK
    bit<CLK_BUS_WIDTH> clock_in;
    bit<CLK_BUS_WIDTH> clock_out;
    bit<CLK_INDEX_WIDTH> clock_indx;
    bit<8> clock_op;

    // TIME UNIT
    bit<TU_BUS_WIDTH> tu_in;
    bit<TU_BUS_WIDTH> tu_out;
    bit<TU_INDEX_WIDTH> tu_indx;
    bit<8> tu_op;

    // BW MEMORY
    bit<BWMEM_BUS_WIDTH> bwmem_in;
    bit<BWMEM_BUS_WIDTH> bwmem_out;
    bit<BWMEM_INDEX_WIDTH> bwmem_indx;
    bit<8> bwmem_op;

    // PKT MEMORY
    bit<PKTMEM_BUS_WIDTH> pktmem_in;
    bit<PKTMEM_BUS_WIDTH> pktmem_out;
    bit<PKTMEM_INDEX_WIDTH> pktmem_indx;
    bit<8> pktmem_op;

    // PKT COUNTER
    bit<PKTCTR_BUS_WIDTH> pktctr_in;
    bit<PKTCTR_BUS_WIDTH> pktctr_out;
    bit<PKTCTR_INDEX_WIDTH> pktctr_indx;
    bit<8> pktctr_op;

    // BYTES COUNTER
    bit<BYTESCTR_BUS_WIDTH> bytesctr_in;
    bit<BYTESCTR_BUS_WIDTH> bytesctr_out;
    bit<BYTESCTR_INDEX_WIDTH> bytesctr_indx;
    bit<8> bytesctr_op;

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

        // READ TIME UNIT
        tu_reg_rizt(1, tu_in, READ_OP, tu_out);

        // READ, IF GT, ZERO CLOCK
        clock_reg_rizt(1, tu_out, RGTZ_OP, clock_out);

        // COMPARE CLOCK & TIME UNIT
        if (clock_out >= tu_out){

          // set write bw memory
          bwmem_op = WRITE_OP;

          // set write pkt memory
          pktmem_op = WRITE_OP;

          // set zero bytes counter
          bytesctr_op = RDZR_OP;

          // set zero pkt counter
          pktctr_op = RDZR_OP;

        }else{

          // set read bw memory
          bwmem_op = READ_OP;

          // set read pkt memory
          pktmem_op = READ_OP;

          // set add bytes counter
          bytesctr_op = ADD_OP;

          // set inc pkt counter
          pktctr_op = RDINC_OP;

        }

        // RDZR/ADD BYTES COUNTER
        bytesctr_reg_rizt(1, (16w0++sume_metadata.pkt_len), bytesctr_op, bytesctr_out);

        // RDZR/INC PKT COUNTER
        pktctr_reg_rizt(1, pktctr_in, pktctr_op, pktctr_out);

        // WRITE/READ BW MEMORY
        bwmem_reg_rizt(1, (bytesctr_out ++ clock_out), bwmem_op, bwmem_out);

        // WRITE/READ PKT MEMORY
        pktmem_reg_rizt(1, (pktctr_out ++ clock_out), pktmem_op, pktmem_out);

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
