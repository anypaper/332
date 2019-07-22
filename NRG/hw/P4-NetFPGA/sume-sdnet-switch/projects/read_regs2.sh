#!/bin/bash

# BASE ADDRESSES
FBA=0x44020
SBA=0x4402

# PKT SIZE 0800 ~ 0FFF
FN=PKS
FBX=0800
FB=$(echo "obase=10; ibase=16; ${FBX}" | bc)
FLX=0FFF
FL=$(echo "obase=10; ibase=16; ${FLX}" | bc)

# BURST GAP MEMORY 2800 ~ 2bff
SN=BGM
SBX=2800
SB=$(echo "obase=10; ibase=16; ${SBX}" | bc)
SLX=2BFF
SL=$(echo "obase=10; ibase=16; ${SLX}" | bc)

echo "" > ${FN}.txt
echo "" > ${SN}.txt

#FN
for (( index=${FB}; index<=${FL}; index++ ));
do
   FIDX=$(echo "obase=16; ibase=10; ${index}" | bc)
   ${RWAXI}/rwaxi -a ${FBA}${FIDX} >> ${FN}.txt
done

echo "DONE: ${FN}"

# SN
for (( index=${SB}; index<=${SL}; index++ ));
do
   SIDX=$(echo "obase=16; ibase=10; ${index}" | bc)
   ${RWAXI}/rwaxi -a ${SBA}${SIDX} >> ${SN}.txt
done

echo "DONE: ${SN}"
