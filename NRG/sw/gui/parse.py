#
# Copyright (c) 2015 
# All rights reserved.
#
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

import os


def parsePing(path):
    try:
        fh = open(path, "r")
        line = fh.readline()
    except IOError:
        print("Error reading Ping log file. Ensure file exists and is readable.")
        return
    if not line.startswith("rtt min/avg/max/mdev = "):
        print("Error parsing Ping log file")
        return
    slashIndex = line[23:].find("/")
    try:
        minLat = float(line[23:23 + slashIndex])
    except ValueError:
        print("Error parsing Ping log file")
        return
    return minLat


def parseIperf(path):
    try:
        fh = open(path, "r")
        line = fh.readline()
    except IOError:
        print("Error reading iPerf log file. Ensure file exists and is readable.")
        return
    try:
        bits = int(line[line.rfind(",") + 1:])
    except ValueError:
        print("Error parsing iPerf log file")
        return None
    return bits


def parseMemcached(path):
    try:
        fh = open(path, "r")
        line = fh.readline()
    except IOError:
        print("Error reading Memcached log file. Ensure file exists and is readable.")
        return
    if not line.startswith("Totals"):
        print("Error parsing Memcached log file")
        return
    started = False  # have we reached the float yet
    first = 0
    last = 0
    i = 6
    while True:
        if not started and line[i] == " ":  # get to the float
            i = i + 1
            continue
        elif started and line[i] == " ":  # we've reached the end of the float
            last = i
            break
        elif not started:  # we've reached the start of the float
            started = True
            first = i
        elif line[i] == "\n":  # we've failed at parsing
            print("Error parsing Memcached log file")
            return None
        i = i + 1
    try:
        value = float(line[first:last])
    except ValueError:
        print("Error parsing Memcached log file")
        return None
    return value


def customParse(parseFile):
    if not os.path.exists(parseFile):
        print("ERROR - Custom parse script file no longer exists")
        return
    local_dict = locals()
    global_dict = globals()
    with open(parseFile, 'rb') as file:
        # user script must create file custom_results_parsed.log in current working directory
        # the created file must contain the measured metric on the first line, and the y axis label on the second line
        exec(compile(file.read(), parseFile, 'exec'), global_dict, local_dict)
    try:
        fh = open("custom_results_parsed.log", "r")
        line1 = fh.readline().strip()
        line2 = fh.readline().strip()
    except IOError:
        print("Error reading 'custom_results_parsed.log'. Ensure file exists and is readable.")
        return
    try:
        metric = float(line1)
    except ValueError:
        print("Error parsing value from 'custom_results_parsed.log'.")
        return None, None
    return metric, line2


def parseBWLog(path):
    try:
        fh = open(path, "r")
    except IOError:
        print("Error reading NRG log file '" + path + "'. Ensure file exists and is readable.")
        return
    values = []
    for i in range(0, 4096):
        line = fh.readline()
        value = int(line[line.rfind(",") + 1:])
        if value != 0:
            values.append(value)
    return values


def parseIPGBurstLog(path):  # parses both IPG and Burst log files
    try:
        fh = open(path, "r")
    except IOError:
        print("Error reading NRG log file '" + path + "'. Ensure file exists and is readable.")
        return
    occurrences = []
    IPGBurst = []
    for i in range(0, 4096):
        line = fh.readline()
        value = int(line[line.rfind(",") + 1:])
        if value != 0:
            occurrences.append(value)
            ipgburst = int(line[0:line.find(",")])
            IPGBurst.append(ipgburst)
    return (IPGBurst, occurrences)
