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

import tkinter.messagebox
from tkinter.filedialog import askopenfilename
from tkinter.filedialog import asksaveasfilename


def saveExperiment(experimentOptions, experimentOptionMenu, experimentDictionary, name, server, client, parseScript):
    if name in experimentDictionary or name == "Ping" or name == "iPerf" or name == "Memcached":
        print("Experiment name \"" + name + "\" already used")
        tkinter.messagebox.showerror("Error", "Experiment name \"" + name + "\" already in use")
        return
    if parseScript == "No file selected":
        parseScript = None
    experimentDictionary[name] = (server, client, parseScript)
    experimentOptions.append(name)
    refreshExperimentMenu(experimentOptionMenu, experimentOptions)


def refreshExperimentMenu(experimentOptionMenu, experimentOptions):
    experimentOptionMenu.var.set('')
    experimentOptionMenu['menu'].delete(0, 'end')  # delete old options
    for exp in experimentOptions:
        experimentOptionMenu['menu'].add_command(label=exp,  # add the options back
                                                 command=tkinter._setit(experimentOptionMenu.var, exp))
        experimentOptionMenu.var.set(exp)


def writeExperiments(filename, experimentDictionary):
    fh = open(filename, "w+")
    for name, configs in experimentDictionary.items():
        server, client, parseFile = configs
        fh.write("experiment_name=" + name + "\n")
        fh.write("server_command=" + server + "\n")
        fh.write("client_command=" + client + "\n")
        if parseFile is None:
            parseFile = "None"
        fh.write("parse_file=" + parseFile + "\n")
    fh.close()


def readExperiments(filename, experimentOptions, experimentOptionMenu, experimentDictionary):
    fh = open(filename, "r")
    state = 0
    name, server_command, client_command = "", "", ""

    for line in fh:
        if state == 0 and line.startswith("experiment_name="):
            name = line[line.find("=") + 1:-1]
            state = 1
            continue
        elif state == 1 and line.startswith("server_command="):
            server_command = line[line.find("=") + 1:-1]
            state = 2
        elif state == 2 and line.startswith("client_command="):
            client_command = line[line.find("=") + 1:-1]
            state = 3
        elif state == 3 and line.startswith("parse_file="):
            parse_file = line[line.find("=") + 1:-1]
            if parse_file == "None":
                parse_file = "No file selected"
            saveExperiment(experimentOptions, experimentOptionMenu, experimentDictionary, name, server_command,
                           client_command, parse_file)
            state = 0
        elif state == 0:  # ignore any line while in state 0 and the line isn't experiment_name
            continue
        else:  # i.e. in state 1 or 2 so are expecting and command, error if we don't have that
            print("Error parsing experiment file")
            experimentDictionary.clear()
            fh.close()
            return -1
    fh.close()
    return 0


def importExperiments(experimentOptions, experimentOptionMenu, experimentsDictionary, label):
    filename = askopenfilename(title="Select file", filetypes=(("Config files", "*.conf"), ("All files", "*.*")))
    if filename == '':
        return
    ret = readExperiments(filename, experimentOptions, experimentOptionMenu, experimentsDictionary)
    if ret != 0:
        print("Experiments have not been imported")
    else:
        label.config(text="Import from \"" + filename + "\" complete")


def exportExperiments(experimentDictionary, label):
    filename = asksaveasfilename(title="Select file", filetypes=(("Config files", "*.conf"), ("All files", "*.*")),
                                 defaultextension='.conf')
    if filename is '':
        return
    writeExperiments(filename, experimentDictionary)
    label.config(text="Export to \"" + filename + "\" complete")
