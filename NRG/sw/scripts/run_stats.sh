#!/bin/sh
 # Copyright (c) 2016 
 # All rights reserved.
 #
 #  File:
 #        init_stats.c
 #
 # $Id: init_stats.c,v 1.0 2016/10/06 22:00:00 root Exp root $
 #
 # Author:
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
#

#Select statistics inputs
#port 0: 0 is input from port 0, 1 is output to port 1
PORT0_SEL=0
#port 1: 0 is input from port 1, 1 is output to port 0
PORT1_SEL=0
BURST_TH=10
BW_GRANULARITY=2000000
BW_DIVISOR=0
BW_DELAY=0 #Valud should be multiplied by 1024 cycles * 5ns
CYCLE_TIME=5
BW_UNIT=$(($BW_GRANULARITY * 5 / 1000))
BW_TRIGGER=$((BW_DELAY * 256 + 16 + 1))
LATENCY=$(($3 / 5))
#Latency DIR: 0 - port 0 only, 1 - port 1 only, 2 - both ports
LATENCY_DIR=2
JITTER=$4
#Jitter type: 0 - no jitter, 1 - uniform, 2- normal, 4- pareto, 8 - pareto normal, 16 - user distribution
JITTER_TYPE=$2
USER_DIST=$5
echo $USER_DIST
if [ $JITTER_TYPE -eq 16 ]
then
   ./write_distribution -a 0x44010000 -t 0x10000000 -f $USER_DIST
fi
if [ $JITTER_TYPE -eq 16 ]
 then
   ./write_distribution -a 0x44020000 -t 0x10000000 -f $USER_DIST
fi

#Rate configuration. LIMITER_ON=Packet size/32B, LIMITER_OFF=Inter packet gap. LIMITER_ON=0 is similar to "off"
LIMITER_ON=0
LIMITER_OFF=16
LIMITER_ALL=$(($LIMITER_ON + $LIMITER_OFF))
#Limiter DIR: 0 - port 0 only, 1 - port 1 only, 2 - both ports,3 - Don't Use
LIMITER_DIR=3
#Limiter Type configuration
LIMIT_PKT_BOUNDARY=1
LIMIT_VALID_IN_PKTS=1
LIMIT_CFG=$((LIMIT_VALID_IN_PKTS * 16 + LIMIT_PKT_BOUNDARY))

break
#remove old logs
rm p0_ipg.log p0_pktsize.log p0_burstsize.log p0_bw.log p1_ipg.log p1_pktsize.log p1_burstsize.log p1_bw.log stats.log

#initialize tables
./init_stats -a 0x44050000
./init_stats -a 0x44060000

#Configure statistics inputs
./rwaxi -a 0x4405003c -w $PORT0_SEL
./rwaxi -a 0x4406003c -w $PORT1_SEL
#Configure latency 
if [ $LATENCY_DIR -eq 0 ] || [ $LATENCY_DIR -eq 2 ] 
then
  ./rwaxi -a 0x4401001c -w $LATENCY
  ./rwaxi -a 0x44010020 -w $JITTER
  ./rwaxi -a 0x44010024 -w $JITTER_TYPE
else
  ./rwaxi -a 0x4401001c -w 0
  ./rwaxi -a 0x44010020 -w 0
  ./rwaxi -a 0x44010024 -w 0
fi

if [ $LATENCY_DIR -eq 1 ] || [ $LATENCY_DIR -eq 2 ] 
then
  ./rwaxi -a 0x4402001c -w $LATENCY
  ./rwaxi -a 0x44020020 -w $JITTER
  ./rwaxi -a 0x44020024 -w $JITTER_TYPE
else
  ./rwaxi -a 0x4402001c -w 0
  ./rwaxi -a 0x44020020 -w 0
  ./rwaxi -a 0x44020024 -w 0
fi

if [ $LIMITER_DIR -eq 1 ] || [ $LIMITER_DIR -eq 2 ]
then
  ./rwaxi -a 0x4404001c -w $LIMITER_ALL
  ./rwaxi -a 0x44040020 -w $LIMITER_ON
  ./rwaxi -a 0x44040024 -w $LIMIT_CFG
else
  ./rwaxi -a 0x4404001c -w 0
  ./rwaxi -a 0x44040020 -w 0
  ./rwaxi -a 0x44040024 -w 0
fi

if [ $LIMITER_DIR -eq 0 ] || [ $LIMITER_DIR -eq 2 ]
then
  ./rwaxi -a 0x4403001c -w $LIMITER_ALL
  ./rwaxi -a 0x44030020 -w $LIMITER_ON
  ./rwaxi -a 0x44030024 -w $LIMIT_CFG
else
  ./rwaxi -a 0x4403001c -w 0
  ./rwaxi -a 0x44030020 -w 0
  ./rwaxi -a 0x44030024 -w 0
fi


#reset counters
./rwaxi -a 0x44050008 -w 0x11
./rwaxi -a 0x44060008 -w 0x11
./rwaxi -a 0x44010008 -w 0x11
./rwaxi -a 0x44020008 -w 0x11
./rwaxi -a 0x44030008 -w 0x11
./rwaxi -a 0x44040008 -w 0x11

#configure burst size
./rwaxi -a 0x44050028  -w $BURST_TH
./rwaxi -a 0x44060028  -w $BURST_TH
./rwaxi -a 0x44050020  -w $BW_GRANULARITY
./rwaxi -a 0x44060020  -w $BW_GRANULARITY
./rwaxi -a 0x44050024  -w $BW_DIVISOR
./rwaxi -a 0x44060024  -w $BW_DIVISOR

#Trigger start (BW triggers on first packet)
./rwaxi -a 0x4405001c  -w $BW_TRIGGER & ./rwaxi -a 0x4406001c  -w $BW_TRIGGER

#Command 
#The command should appear as an argument within "" 
#$1
sleep $1

#Trigger stop
./rwaxi -a 0x4405001c  -w 0 & ./rwaxi -a 0x4406001c  -w 0

#read statistics
./read_stats -a 0x44050000
mv ipg.log p0_ipg.log
mv pktsize.log p0_pktsize.log
mv burstsize.log p0_burstsize.log
mv bw.log p0_bw.log
mv bw_ts.log p0_bw_ts.log
mv window_size.log p0_window_size.log

./read_stats -a 0x44060000
mv ipg.log p1_ipg.log
mv pktsize.log p1_pktsize.log
mv burstsize.log p1_burstsize.log
mv bw.log p1_bw.log
mv bw_ts.log p1_bw_ts.log
mv window_size.log p1_window_size.log

#read flow statistics
./read_flow_stats -a 0x44050000
mv flow_stats.log p0_flow_stats.log

./read_flow_stats -a 0x44060000
mv flow_stats.log p1_flow_stats.log

#Collect results

echo "Settings: Stats 0 is set to $PORT0_SEL (0-Port 0 input, 1-Port 1 output), Stats 1 is set to $PORT1_SEL (0-Port 1 input, 0 - Port 0 output)\nBurst TH $BURST_TH , BW Unit of observation (in micro seconds) $BW_UNIT (in cycles of 5ns) $BW_GRANULARITY , BW Results shifted by $BW_DIVISOR bits\n"> stats.log
echo "LIMITER Direction $LIMITER_DIR , LIMITER on cycles (32B) $LIMITER_ON, LIMITER Off cycles $LIMITER_OFF\n" >> stats.log
echo "Port 0 results\n===========\n" >> stats.log
echo "Number of packets: ">> stats.log
./rwaxi -a 0x44050014 >> stats.log
echo "First packet in: ">> stats.log
./rwaxi -a 0x44050030 >> stats.log
echo "Last packet in: ">> stats.log
./rwaxi -a 0x44050034 >> stats.log
echo "Last BW table entry number:">> stats.log
./rwaxi -a 0x44050038 >> stats.log
echo "Test end time (in cycles, port clocks are currently independent):">> stats.log
./rwaxi -a 0x4405002c >> stats.log
sleep 1
echo "Read latency watermark">> stats.log
./rwaxi -a 0x44010010 >> stats.log
echo "\n">> stats.log
echo "\nPacket Size [B]\n" >> stats.log
grep -v 0x00000000 p0_pktsize.log >>stats.log
echo "\nPacket Gap [cycles]\n" >> stats.log
grep -v 0x00000000 p0_ipg.log >>stats.log
echo "\nBurst Size [#pkts]\n" >> stats.log
grep -v 0x00000000 p0_burstsize.log >>stats.log
echo "\nBW [bytes per $BW_UNIT micro second]\n" >> stats.log
grep -v 0x00000000 p0_bw.log >>stats.log
echo "\nWindow Size [Bytes]\n" >> stats.log
grep -v 0x00000000 p0_window_size.log >>stats.log
echo "\nProtocol and Flow Statistics:\n" >> stats.log
cat p0_flow_stats.log  | grep -v 0x0000000 >> stats.log

echo "\n\nPort 1 results\n===========\n" >> stats.log
echo "Number of packets: ">> stats.log
./rwaxi -a 0x44060014 >> stats.log
echo "First packet in: ">> stats.log
./rwaxi -a 0x44060030 >> stats.log
echo "Last packet in: ">> stats.log
./rwaxi -a 0x44060034 >> stats.log
echo "Last BW table entry number:">> stats.log
./rwaxi -a 0x44060038 >> stats.log
echo "Test end time (in cycles, port clocks are currently independent):">> stats.log
./rwaxi -a 0x4406002c >> stats.log
echo "Read latency watermark">> stats.log
./rwaxi -a 0x44020010 >> stats.log
echo "\n">> stats.log
echo "\nPacket Size [B]\n" >> stats.log
grep -v 0x00000000 p1_pktsize.log >>stats.log
echo "\nPacket Gap [cycles]\n" >> stats.log
grep -v 0x00000000 p1_ipg.log >>stats.log
sleep 1
echo "\nBurst Size [#pkts]\n" >> stats.log
grep -v 0x00000000 p1_burstsize.log >>stats.log
echo "\nBW [bytes per $BW_UNIT micro second]\n" >> stats.log
grep -v 0x0000000 p1_bw.log >>stats.log
echo "\nWindow Size [Bytes]\n" >> stats.log
grep -v 0x00000000 p1_window_size.log >>stats.log
echo "\nProtocol and Flow Statistics:\n" >> stats.log
cat p1_flow_stats.log | grep -v 0x0000000 >> stats.log

#mkdir /root/dap53/sigmetrics-mutilate/fb-5clients-jittertype-${2}-latency-${3}-jitter-${4}-run-${5}
#mv *log /root/dap53/sigmetrics-mutilate/fb-5clients-jittertype-${2}-latency-${3}-jitter-${4}-run-${5}
#mkdir /root/dap53/sigmetrics-strads/lasso-6-machines-jittertype-${2}-latency-${3}-jitter-${4}-run-${5}
#mv *log /root/dap53/sigmetrics-strads/lasso-6-machines-jittertype-${2}-latency-${3}-jitter-${4}-run-${5}
#mkdir /root/dap53/ab/1client-jittertype-${2}-latency-${3}-jitter-${4}-run-${5}
#mv *log /root/dap53/ab/1client-jittertype-${2}-latency-${3}-jitter-${4}-run-${5}
