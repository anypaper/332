#!/bin/bash

# BASE ADDRESS
BA=0x44020

# BW MEM 500 ~ 501
BWM=501

# PKT MEM 600 ~ 601
PKTM=601

echo "-----------------------------------------------------------"
echo -n "READING FROM [BWMEM-REG01]: "
${RWAXI}/rwaxi -a ${BA}${BWM}
echo "-----------------------------------------------------------"

echo "-----------------------------------------------------------"
echo -n "READING FROM [PKTMEM-REG01]: "
${RWAXI}/rwaxi -a ${BA}${PKTM}
echo "-----------------------------------------------------------"
