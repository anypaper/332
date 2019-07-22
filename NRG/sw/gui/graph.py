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

import matplotlib.pyplot as plt
import parse


def createGraph(x, y, xlab, ylab, path=None, clear=True, legend=None):
    if legend is not None:
        plt.plot(x, y, marker='.', label=legend)
        plt.legend(loc='best')
    else:
        plt.plot(x, y, marker='.')
    plt.xlabel(xlab)
    plt.ylabel(ylab)
    if path is None:
        plt.savefig('out.png')
        plt.savefig('out.pdf')
    else:
        plt.savefig(path)
        plt.savefig(path[:-3] + "pdf")
    if clear:
        clearGraph()


def createLogLogGraph(x, y, xlab, ylab, path=None, clear=True, legend=None):
    if legend is not None:
        plt.loglog(x, y, marker='.', label=legend)
        plt.legend(loc='best')
    else:
        plt.loglog(x, y, marker='.')
    plt.xlabel(xlab)
    plt.ylabel(ylab)
    if path is None:
        plt.savefig('out.png')
        plt.savefig('out.pdf')
    else:
        plt.savefig(path)
        plt.savefig(path[:-3] + "pdf")
    if clear:
        clearGraph()


def clearGraph():
    plt.clf()


def generateBWGraph():
    graphVals = parse.parseBWLog("p1_bw.log")
    graphVals[:] = [x / 1250 for x in graphVals]  # divide all values by 1250 to obtain Mbits/s
    createGraph(range(graphVals.__len__()), graphVals, "Time since first packet (10ms)",
                "Throughput (Mbits/s)", "../Graphs/p1_bw.png")


def generateBWGraphCombined(numberOfExperiments, lat):
    for i in range(numberOfExperiments):
        graphVals = parse.parseBWLog("Experiment_" + str(i) + "/Logs/p1_bw.log")
        graphVals[:] = [x / 1250 for x in graphVals]  # divide all values by 1250 to obtain Mbits/s
        createGraph(range(graphVals.__len__()), graphVals, "Time since first packet (10ms)",
                    "Throughput (Mbits/s)", "p1_bw_combined.png", clear=False, legend=lat[i])
    clearGraph()


def generateIPGGraph():
    IPG, occurrences = parse.parseIPGBurstLog("p1_ipg.log")
    createLogLogGraph(IPG, occurrences, "Inter-packet gap (cycles)",
                      "Occurrences", "../Graphs/p1_ipg.png")


def generateIPGGraphCombined(numberOfExperiments, lat):
    for i in range(numberOfExperiments):
        IPG, occurrences = parse.parseIPGBurstLog("Experiment_" + str(i) + "/Logs/p1_ipg.log")
        createLogLogGraph(IPG, occurrences, "Inter-packet gap (cycles)",
                          "Occurrences", "p1_ipg_combined.png", clear=False, legend=lat[i])
    clearGraph()


def generateBurstGraph():
    burst, occurrences = parse.parseIPGBurstLog("p1_burstsize.log")
    createLogLogGraph(burst, occurrences, "Burst size (packets)",
                      "Occurrences", "../Graphs/p1_burstsize.png")


def generateBurstGraphCombined(numberOfExperiments, lat):
    for i in range(numberOfExperiments):
        burst, occurrences = parse.parseIPGBurstLog("Experiment_" + str(i) + "/Logs/p1_burstsize.log")
        createLogLogGraph(burst, occurrences, "Burst size (packets)",
                          "Occurrences", "p1_burstsize_combined.png", clear=False, legend=lat[i])
    clearGraph()
