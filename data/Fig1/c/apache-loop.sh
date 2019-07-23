#!/bin/bash
export APACHE_REQ_COUNT=1000000
export APACHE_REQ_CONCURRENCY=100
export server_ip=10.0.0.2
for i in {1..100}
do
  echo 'in iteration'
  echo $i
  sudo ab -n $APACHE_REQ_COUNT -c $APACHE_REQ_CONCURRENCY -e /root/apache-benchmark/apache_ab_log_$i http://$server_ip/index.html  > /root/apache-benchmark/apache_ab_out_$i
  sleep 120
done

