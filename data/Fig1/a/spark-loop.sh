#!/bin/bash
for i in {1..100}
do
  echo 'in iteration'
  echo $i
  ./spark-perf/bin/run  > ./spark-out_$i
  sleep 20
done