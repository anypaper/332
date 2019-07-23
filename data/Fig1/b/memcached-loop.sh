#!/bin/bash
for i in {1..100}
do
  echo $i
  ./mutilate -s $server_ip --noload  -T 4 --affinity -K fb_key -V fb_value -i fb_ia -u 0.033 -c 32 -t 20 -q 100000 --save=out_$i   > stdout_$i
  sleep 60
done