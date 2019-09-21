#!/bin/bash

source /root/myname/scripts/general/remote_run.sh

#Set parameters
port1='ens8'
port2='ens8d1'
outfolder=/home/myname/nrg_ping/
outfile=$outfolder/$1_trace
outcmd=$outfolder/$1_cmd
outdelay=$outfolder/$1_delay
outcdf=$outfolder/$1_cdf.txt
cpus='1:2,3:4,5,6,7,8,9,10,11,12'
sleep_time=10
script_path=/root/myname/scripts/hpt/
exclude='ARP'
src_ip='192.168.0.10'
mid_ip='192.168.0.1'
dst_ip='192.168.0.1'
source_machine='server1'
dest_machine='server2'
nrg_machine='server3'
port=5111
runs=10
pkts=1000000

#setup the test
mkdir -p $outfolder
for delay in {0..100000..10000}; do
	remote_run_command $nrg_machine "/root/myname/scripts/nrg/set_delay.sh $delay"
	mkdir -p $outfolder/out_$delay/
    #run $runs iterations
	for run in $(seq 1 $runs); do
      outfile=$outfolder/out_$delay/$run\_trace
      outcmd=$outfolder/out_$delay/$run\_cmd
      outdelay=$outfolder/out_$delay/$run\_delay
      outcdf=$outfolder/out_$delay/$run\_cdf
      ./record_port.sh $port1 $outfile-1 $cpus $outcmd-1
	  ./record_port.sh $port2 $outfile-2 $cpus $outcmd-2 
      sleep 3
      remote_run_command $source_machine "ping $mid_ip -c $pkts -f "
      sleep 1
      $script_path/stop_recording.sh
      $script_path/extract_pcap.sh $outfile-1-0.expcap $outfile-1-0.pcap
      $script_path/extract_pcap.sh $outfile-2-0.expcap $outfile-2-0.pcap
	  bzip2 $outfile-1-0.expcap
	  bzip2 $outfile-2-0.expcap
	  tcpdump -r $outfile-1-0.pcap -tt --time-stamp-precision=nano |grep -v $exclude |grep $dst_ip |cut -d' ' -f1,12|cut -d, -f1>tmpout
      tcpdump -r $outfile-2-0.pcap -tt --time-stamp-precision=nano |grep -v $exclude |grep $dst_ip |cut -d' ' -f1,12|cut -d, -f1>tmpin
      paste tmpout tmpin |awk '{if ($2-$4==0) print $1-$3}'>$outdelay
      rm tmpout tmpin $outfile-1-0.pcap $outfile-2-0.pcap
      lines=`wc -l $outdelay | cut -d" " -f 1`
      sort -g $outdelay | nawk -vlines=$lines '{if ((i%(int(lines/100))==0)||(i==lines-1)){printf ("%g %s\n",(float)i/lines,$1);} i++;}' > $outcdf
      head -n 51 $outcdf |tail -n 1 >>$outfolder/out_$delay/median
	  head -n 1 $outcdf  >>$outfolder/out_$delay/min 
	  tail -n 1 $outcdf  >>$outfolder/out_$delay/max
   done
done

#clean up
