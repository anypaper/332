#!/bin/bash

for i in $(seq 0 3000);
	do
        addr=$((i+ 268435456))
	$APPS_FOLDER/rwaxi -a 0x44050024 -w $addr
	$APPS_FOLDER/rwaxi -a 0x44050030 -w 0x11
	$APPS_FOLDER/rwaxi -a 0x4405002c >> log.txt
	done

