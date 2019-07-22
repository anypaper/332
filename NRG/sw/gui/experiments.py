#
# Copyright (c) 2015 University of Cambridge
# All rights reserved.
#
# This software was developed by Stanford University and the University of Cambridge Computer Laboratory
# under National Science Foundation under Grant No. CNS-0855268,
# the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
# by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"),
# as part of the DARPA MRC research programme.
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

import configure_NRG as conf
import tkinter.messagebox
from tkinter import *
import math
import os
import graph
import parse
import time


def executeExperiments(exp, startLat, endLat, strideLat, timeUnit, sExpLength, sPort, jitterType,
                       userDistPath, eJitterVal, experimentDirectory, serverConnection, clientConnection,
                       experimentDictionary, lExperimentStatus, root, defaultPath):
    os.chdir(defaultPath)
    if not os.path.exists("Results"):
        os.makedirs("Results")
    os.chdir("Results")
    if not os.path.exists(experimentDirectory):
        try:
            os.makedirs(experimentDirectory)
        except OSError:
            print("Error creating experiment directory. Ensure name meets directory name requirements.")
            tkinter.messagebox.showerror("Error",
                                         "Error creating experiment directory. "
                                         "Ensure name meets directory name requirements.")
            return
    elif os.listdir(experimentDirectory):
        print("Error: Experiment directory already exists and is not empty.")
        tkinter.messagebox.showerror("Error",
                                     "Experiment directory already exists and is not empty. Exiting experiment.")
        return
    os.chdir(experimentDirectory)
    conf.writeRegister("4401001c", "0", clientConnection)  # zero latency/jitter on both ports
    conf.writeRegister("44010020", "0", clientConnection)
    conf.writeRegister("44010024", "0", clientConnection)
    conf.writeRegister("4402001c", "0", clientConnection)
    conf.writeRegister("44020020", "0", clientConnection)
    conf.writeRegister("44020024", "0", clientConnection)
    latReg = None
    if sPort == "Port 0":
        latReg = "4401001c"
    elif sPort == "Port 1":
        latReg = "4402001c"
    elif sPort != "Both":
        return
    conf.writeRegister("4403001c", "0", clientConnection)  # reset rate limiters
    conf.writeRegister("44030020", "0", clientConnection)
    try:
        expLength = int(sExpLength)
    except ValueError:
        print("Error: experiment length is not an integer")
        tkinter.messagebox.showerror("Error", "Experiment length must be a positive integer")
        return
    if expLength <= 0:
        print("Error: experiment length is not a positive integer")
        tkinter.messagebox.showerror("Error", "Experiment length must be a positive integer")
        return
    experimentNumber = 0
    latArray = list()
    configuredLat = list()
    perfMetric = list()
    timeUnitConversion = {1: "ns", 1000: "μs", 1000000: "ms", 1000000000: "s"}
    try:
        startLat = int(float(startLat) * timeUnit)
        endLat = int(float(endLat) * timeUnit)
        strideLat = int(float(strideLat) * timeUnit)
    except ValueError:
        print("Error: Latency start, end, and stride must be positive integers.")
        tkinter.messagebox.showerror("Error", "Latency start, end, and stride must be positive integers.")
        return
    if strideLat < 0 or startLat < 0 or endLat < 0:
        print("Error: Latency start, end, and stride must be non-negative integers.")
        tkinter.messagebox.showerror("Error", "Latency start, end, and stride must be non-negative integers.")
        return
    elif startLat > endLat:
        print("Error: Latency start must be less than or equal to latency end.")
        tkinter.messagebox.showerror("Error", "Latency start must be less than or equal to latency end.")
        return
    elif strideLat == 0 and startLat != endLat:
        print("Error: Latency stride must be a positive integer if start and end latency are different.")
        tkinter.messagebox.showerror("Error",
                                     "Latency stride must be a positive integer"
                                     " if start and end latency are different.")
        return
    elif strideLat == 0:  # i.e. if startLat == endLat then we can have 0 stride
        strideLat = 1  # set to 1 to ensure for loop exits after 1 run
    if setExpJitter(sPort, eJitterVal, jitterType, userDistPath, clientConnection, root) != 0:
        return
    sftp = clientConnection.open_sftp()
    customParse = False
    ylabel = None
    for i in range(startLat, endLat + 1, strideLat):
        estTime = round((((endLat - startLat) / strideLat) + 1 - experimentNumber) * (expLength + 11))
        lExperimentStatus.config(text="Experiment started. Estimated time = " + str(estTime) + " seconds")
        root.update()  # update label
        expDir = "Experiment_" + str(experimentNumber)
        os.makedirs(expDir)  # the cwd is necessarily empty at this point
        os.chdir(expDir)
        os.makedirs("Graphs")
        os.makedirs("Logs")
        os.chdir("Logs")
        if sPort == "Both":
            conf.writeRegister("4401001c", hex(int(i / 5))[2:], clientConnection)
            conf.writeRegister("4402001c", hex(int(i / 5))[2:], clientConnection)
        else:
            conf.writeRegister(latReg, hex(int(i / 5))[2:], clientConnection)
        if exp == "Ping":  # hard-coded default experiments
            clientString = 'ping 10.0.0.1 -c 64 -f | grep min > ping_lat_' + str(experimentNumber) + '.log'
            serverString = ''
        elif exp == "iPerf":
            clientString = 'iperf -c 10.0.0.1 -y c > iperf_' + str(experimentNumber) + '.log'
            serverString = 'iperf -s'
        elif exp == "Memcached":
            clientString = 'memtier_benchmark -s 10.0.0.1 -p 11211 -P memcache_binary ' \
                           '-x 1 -c 20 -d 16 -t 18 --test-time=5 | grep Totals > /tmp/memcached_' + str(
                experimentNumber) + '.log'
            serverString = 'memcached -t 4 -c 32768 -l 10.0.0.1 -u memcache'
        else:  # user-added experiment
            server, client, parseLocation = experimentDictionary[exp]
            clientString = client
            serverString = server
            parseFile = parseLocation
            if parseFile is not None:
                customParse = True
                clientString = clientString + " > /tmp/custom_results.log"
        executeExperiment(clientString, serverString, expLength, clientConnection, serverConnection)
        time.sleep(expLength + 2)

        if exp == "Ping":  # ping, iperf, and memcached have built in parse scripts
            getFile("/root/ping_lat_" + str(experimentNumber) + ".log",
                    "ping_lat_" + str(experimentNumber) + ".log", sftp)
        elif exp == "iPerf":
            getFile("/root/iperf_" + str(experimentNumber) + ".log",
                    "iperf_" + str(experimentNumber) + ".log", sftp)
        elif exp == "Memcached":
            getFile("/tmp/memcached_" + str(experimentNumber) + ".log",
                    "memcached_" + str(experimentNumber) + ".log", sftp)
        elif customParse:
            getFile("/tmp/custom_results.log", "custom_results.log", sftp)
        configuredLat.append(i / timeUnit)
        measuredMetric = None
        if exp == "Ping":
            measuredMetric = parse.parsePing("ping_lat_" + str(experimentNumber) + ".log")
        elif exp == "iPerf":
            measuredMetric = parse.parseIperf("iperf_" + str(experimentNumber) + ".log")
        elif exp == "Memcached":
            measuredMetric = parse.parseMemcached("memcached_" + str(experimentNumber) + ".log")
        elif customParse:
            measuredMetric, ylabel = parse.customParse(parseFile)
        if measuredMetric is None and (exp == "Ping" or exp == "iPerf" or exp == "Memcached"):
            tkinter.messagebox.showerror("Error",
                                         "Error parsing results. Experiment failed. Ensure that enough time has"
                                         " been given for each experiment, and that the experiment is able"
                                         " to run on host machines.")
            lExperimentStatus.config(text="Experiment failed.")
            return
        if measuredMetric is None and customParse:
            tkinter.messagebox.showerror("Error",
                                         "Error parsing results. Experiment failed. Ensure that enough time has"
                                         " been given for each experiment, and that the experiment is able"
                                         " to run on host machines. Additionally, check that the provided parse script"
                                         " is correct.")
            lExperimentStatus.config(text="Experiment failed.")
        if exp == "Ping" or exp == "iPerf" or exp == "Memcached" or customParse:
            perfMetric.append(measuredMetric)
        getStats(clientConnection)
        getFiles("./", clientConnection)
        graph.generateBWGraph()
        graph.generateIPGGraph()
        graph.generateBurstGraph()
        os.chdir("../..")
        latArray.append(str(i / timeUnit) + timeUnitConversion[timeUnit])  # used to generate the legends
        experimentNumber += 1
    graph.generateBWGraphCombined(experimentNumber, latArray)
    graph.generateIPGGraphCombined(experimentNumber, latArray)
    graph.generateBurstGraphCombined(experimentNumber, latArray)
    if exp == "Ping" or exp == "iPerf" or exp == "Memcached" or customParse:
        fh = open("experiment_results.txt", "w+")
        fh.write("# configured latency (ns), measured metric\n")
        for i in range(0, experimentNumber):
            fh.write(str(int(configuredLat[i] * timeUnit)) + "," + str(perfMetric[i]) + "\n")
        fh.close()
        xlab = "Configured Latency (" + timeUnitConversion[timeUnit] + ")"
        if exp == "Ping":
            ylab = "Min Latency (ms)"
        elif exp == "iPerf":
            for i in range(0, experimentNumber):
                perfMetric[i] = perfMetric[i] / 1000000
            ylab = "Throughput (Mbits/s)"
        elif exp == "Memcached":
            for i in range(0, experimentNumber):
                perfMetric[i] = perfMetric[i] / 1000
            ylab = "Rate of Operations (KOps/s)"
        else:  # customParse
            ylab = ylabel
        graph.createGraph(configuredLat, perfMetric, xlab, ylab, "MeasuredMetric.png")
    fh = open("experiment_settings.txt", "w+")
    writeSettings(fh, exp, startLat / timeUnit, endLat / timeUnit, strideLat / timeUnit, timeUnit, sExpLength, sPort,
                  eJitterVal.get(), jitterType, userDistPath)
    fh.close()
    sftp.close()
    os.chdir("../..")  # back to main directory (with interface.py)
    lExperimentStatus.config(text="Experiment finished.")
    tkinter.messagebox.showinfo("Experiment Complete", "Results are in Results/" + experimentDirectory)
    os.startfile("Results\\" + experimentDirectory)


def executeExperiment(clientString, serverString, experimentLength, clientConnection, serverConnection):
    if serverString != '':
        command = 'echo "' + serverString + '" | at now'
        print("Sending to server: " + command)
        conf.sendCommand(None, None, command, serverConnection)
    # initialize tables
    conf.sendCommand(None, None, "/root/init_stats -a 0x44050000", clientConnection)
    conf.sendCommand(None, None, "/root/init_stats -a 0x44060000", clientConnection)
    # configure statistics inputs
    conf.writeRegister("4405003c", "0", clientConnection)
    conf.writeRegister("4406003c", "0", clientConnection)
    # reset counters
    conf.writeRegister("44050008", "11", clientConnection)
    conf.writeRegister("44060008", "11", clientConnection)
    conf.writeRegister("44010008", "11", clientConnection)
    conf.writeRegister("44020008", "11", clientConnection)
    conf.writeRegister("44030008", "11", clientConnection)
    conf.writeRegister("44040008", "11", clientConnection)
    startExperiment = "/root/rwaxi -a 0x4405001c -w 0x11 & /root/rwaxi -a 0x4406001c -w 0x11"
    command = 'echo "sleep 1; ' + startExperiment + '" | at now'
    print(command)
    # start experiment in 2 seconds
    conf.sendCommand(None, None, command, clientConnection)
    command = 'echo "sleep 2; ' + clientString + '" | at now'
    print(command)
    conf.sendCommand(None, None, command, clientConnection)
    stopExperiment = "/root/rwaxi -a 0x4405001c -w 0x0 & /root/rwaxi -a 0x4406001c -w 0x0"
    # stop experiment in 2 + experimentLength seconds
    sExperimentLength = str(int(experimentLength) + 2)
    command = 'echo "sleep ' + sExperimentLength + '; ' + stopExperiment + '" | at now'
    print(command)
    conf.sendCommand(None, None, command, clientConnection)


def setExpJitter(sPort, eJitterVal, jitterType, userDistPath, sshConnection, root):
    if sPort == "Port 0" or sPort == "Both":
        jitterValReg = "44010020"
        jitterTypeReg = "44010024"
    elif sPort == "Port 1":
        jitterValReg = "44020020"
        jitterTypeReg = "44020024"
    else:
        return -1
    jitterIntToWrite = 0
    if eJitterVal.get() != '':
        try:
            jitterInt = int(eJitterVal.get())
        except ValueError:
            print("Error converting string to integer")
            tkinter.messagebox.showerror("Error", "Jitter value must be a non-negative integer")
            return -1
        if jitterInt < 0:
            tkinter.messagebox.showerror("Error", "Jitter value can not be negative.")
            return -1
        elif jitterInt >= 5:
            jitterIntToWrite = round(math.log2(jitterInt / 5))
            if round(math.log2(jitterInt / 5)) != math.log2(jitterInt / 5):
                tkinter.messagebox.showinfo("Information",
                                            "Jitter value has rounded to nearest supported value: " + str(
                                                (1 << jitterIntToWrite) * 5))
            eJitterVal.delete(0, END)
            eJitterVal.insert(0, str((1 << jitterIntToWrite) * 5))
            root.update()
        elif jitterInt != 0:  # i.e. is between 1 and 4
            tkinter.messagebox.showerror("Error", "Jitter value can not be less than 5ns.")
            return -1
    conf.writeRegister(jitterValReg, hex(jitterIntToWrite)[2:], sshConnection)
    conf.writeRegister(jitterTypeReg, hex(jitterType)[2:], sshConnection)
    if sPort == "Both":
        jitterValReg = "44020020"
        jitterTypeReg = "44020024"
        conf.writeRegister(jitterValReg, hex(jitterIntToWrite)[2:], sshConnection)
        conf.writeRegister(jitterTypeReg, hex(jitterType)[2:], sshConnection)
    if jitterType == 16:  # if it's a user distribution
        conf.sendCommand(None, None, "./write_distribution -a 0x44010000 -t 0x10000000 -f " + userDistPath,
                         sshConnection)
        conf.sendCommand(None, None, "./write_distribution -a 0x44020000 -t 0x10000000 -f " + userDistPath,
                         sshConnection)
    return 0


def getStats(sshConnection):
    conf.sendCommand(None, None, "/root/read_stats -a 0x44050000", sshConnection)
    conf.sendCommand(None, None,
                     ("mv ipg.log p0_ipg.log; mv pktsize.log p0_pktsize.log; mv burstsize.log p0_burstsize.log; "
                      "mv bw.log p0_bw.log; mv bw_ts.log p0_bw_ts.log; mv window_size.log p0_window_size.log"),
                     sshConnection)
    conf.sendCommand(None, None, "/root/read_stats -a 0x44060000", sshConnection)
    conf.sendCommand(None, None,
                     ("mv ipg.log p1_ipg.log; mv pktsize.log p1_pktsize.log; mv burstsize.log p1_burstsize.log; "
                      "mv bw.log p1_bw.log; mv bw_ts.log p1_bw_ts.log; mv window_size.log p1_window_size.log"),
                     sshConnection)


def getFiles(rootPath, sshConnection):
    sftp = sshConnection.open_sftp()
    basepath = rootPath
    if not basepath.endswith('/'):
        basepath = rootPath + "/"
    getFile("/root/p0_ipg.log", basepath + "p0_ipg.log", sftp)
    getFile("/root/p0_pktsize.log", basepath + "p0_pktsize.log", sftp)
    getFile("/root/p0_burstsize.log", basepath + "p0_burstsize.log", sftp)
    getFile("/root/p0_bw.log", basepath + "p0_bw.log", sftp)
    getFile("/root/p0_bw_ts.log", basepath + "p0_bw_ts.log", sftp)
    getFile("/root/p0_window_size.log", basepath + "p0_window_size.log", sftp)
    getFile("/root/p1_ipg.log", basepath + "p1_ipg.log", sftp)
    getFile("/root/p1_pktsize.log", basepath + "p1_pktsize.log", sftp)
    getFile("/root/p1_burstsize.log", basepath + "p1_burstsize.log", sftp)
    getFile("/root/p1_bw.log", basepath + "p1_bw.log", sftp)
    getFile("/root/p1_bw_ts.log", basepath + "p1_bw_ts.log", sftp)
    getFile("/root/p1_window_size.log", basepath + "p1_window_size.log", sftp)
    sftp.close()


def getFile(source, dest, sftp):
    try:
        sftp.get(source, dest)
    except IOError:
        print("File " + source + " does not exist on the remote filesystem")


def writeSettings(fh, exp, startLat, endLat, strideLat, timeUnit, sExpLength, sPort, sJitterVal, jitterType,
                  userDistPath):
    fh.write("# These values can be read by the \"Import settings\" button on the experiments tab\n")
    fh.write("# Do not manually edit this file\n")
    fh.write("Experiment: " + exp + "\n")
    fh.write("Latency multiplier: " + str(timeUnit) + "\n")
    fh.write("Start latency: " + str(startLat) + "\n")
    fh.write("End latency: " + str(endLat) + "\n")
    fh.write("Stride latency: " + str(strideLat) + "\n")
    fh.write("Per experiment length: " + sExpLength + "\n")
    fh.write("Port select: " + sPort + "\n")
    fh.write("Jitter value: " + sJitterVal + "\n")
    fh.write("Jitter type: " + str(jitterType) + "\n")
    fh.write("User dist path: " + userDistPath + "\n")
