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

from tkinter import *
from tkinter import tix
import tkinter.messagebox
import tkinter.font
import tkinter.simpledialog
import paramiko

from tkinter.filedialog import askopenfilename
from tkinter.filedialog import asksaveasfilename
from socket import error as socket_error
import os
import experiment_configuration as exp
import configure_NRG as conf
import experiments


class Tab(Frame):
    def __init__(self, master, name):
        Frame.__init__(self, master)
        self.name = name


class TabBar(Frame):
    def __init__(self, master, connectionFrame, mainFrame):
        Frame.__init__(self, master)
        self.connectionFrame = connectionFrame
        self.mainFrame = mainFrame
        self.tabs = {}  # keeps track of the tabs we have added
        self.tabCurrent = None  # what is the tab the user is currently on
        self.tabButtons = {}  # keeps track of the buttons for each tab

    def addTab(self, tab):
        self.tabs[tab.name] = tab  # add new tab to the list of tabs
        tabButton = Button(self, text=tab.name, width=18, command=lambda: self.changeTab(tab.name))
        tabButton.pack(side=TOP)  # display the new button for the tab
        self.tabButtons[tab.name] = tabButton  # add it to the list of buttons

    def changeTab(self, name):
        if name == "SSH Connections" or name == "Run Experiments" or name == "Add Experiments":
            self.connectionFrame.pack_forget()  # remove the option to select the connection to control
        elif self.tabCurrent == "SSH Connections" or self.tabCurrent == "Run Experiments" \
                or self.tabCurrent == "Add Experiments":
            self.mainFrame.pack_forget()
            self.connectionFrame.pack(side=TOP, fill=BOTH)  # add it back in on top
            self.mainFrame.pack(side=TOP, fill=BOTH)
        if self.tabCurrent is not None:  # only None when first launching GUI to SSH Connections
            self.tabButtons[self.tabCurrent].config(relief=RAISED)
            self.tabs[self.tabCurrent].pack_forget()  # hide the tab we're currently on
        self.tabs[name].pack()  # display the new tab
        self.tabCurrent = name  # change the current tab to the new one
        self.tabButtons[name].config(relief=FLAT)  # set its relief to flat, the style for selected buttons


class ControlInterface:
    def __init__(self, master):
        self.sshConnections = {}  # {connectionName: client}
        self.sshDetails = {}  # {connectionName: (host, port, username, password, usePrivateKey, key, passphrase)}
        self.experimentDictionary = {}  # {experimentName: (server_command, client_command, parse_file)}

        master.minsize(width=500, height=400)
        master.maxsize(width=1500, height=950)

        self.mainScreen = Frame(master, width=400, height=400)
        self.connectionFrame = Frame(self.mainScreen, width=400)  # frame with connection select on it
        self.mainFrame = Frame(self.mainScreen, width=400, height=400)  # contains the content of the tab
        self.sideFrame = Frame(master, width=100, height=100, bg="grey")  # contains the tab bar

        self.tabs = TabBar(self.sideFrame, self.connectionFrame, self.mainFrame)
        self.conNumber = 0  # used for creating unique connection names when none is specified

        # Connection frame - to select a remote host to control
        Label(self.connectionFrame, text="Connection Selected: ").grid(row=0, column=0)
        self.controlledConnectionVar = StringVar(master)
        self.controlledConnectionVar.set(None)  # default value
        self.controlledConnectionOptions = [None]  # populated with connection names as connections are made
        self.controlledSelect = OptionMenu(self.connectionFrame, self.controlledConnectionVar,
                                           *self.controlledConnectionOptions)
        self.controlledSelect.grid(row=0, column=1, sticky=W)

        ### Set Latency + Rate limiter
        self.latbw = Tab(self.mainFrame, "Latency & Bandwidth")

        ## Latency
        Label(self.latbw, text="Port select:").grid(row=0, column=0, sticky=E)
        self.portVar = IntVar(value=0)
        Radiobutton(self.latbw, text="0", variable=self.portVar, value=0).grid(row=0, column=1, sticky=W)
        Radiobutton(self.latbw, text="1", variable=self.portVar, value=1).grid(row=0, column=2, sticky=W)
        Label(self.latbw, text="Latency:").grid(row=1, column=0, sticky=E)
        self.eLatency = Entry(self.latbw, width=4)
        self.eLatency.insert(0, "0")
        self.eLatency.grid(row=1, column=1, sticky=W)

        self.v = IntVar(value=1)  # defaults to ns
        Radiobutton(self.latbw, text="ns", variable=self.v, value=1).grid(row=1, column=2, sticky=W)
        Radiobutton(self.latbw, text="μs", variable=self.v, value=1000).grid(row=1, column=3, sticky=W)
        Radiobutton(self.latbw, text="ms", variable=self.v, value=1000000).grid(row=1, column=4, sticky=W)
        Radiobutton(self.latbw, text="s", variable=self.v, value=1000000000).grid(row=1, column=5, sticky=W)
        # value is multiplier
        ##

        ## Jitter distribution
        Label(self.latbw, text="Jitter distribution:").grid(row=2, column=0, sticky=E)
        distVar = StringVar(master)
        distVar.set("No Jitter")  # default value
        self.distributions = {"No Jitter": 0, "Uniform": 1, "Normal": 2, "Pareto": 4, "Pareto Normal": 8,
                              "User Defined": 16}  # value is the value to write to NRG to select that dist
        menu = OptionMenu(self.latbw, distVar, *self.distributions, command=self.toggleUserDistField)
        # toggleUserDistField enables the entry for a user distribution if that option is selected
        menu.grid(row=2, column=1, columnspan=3, sticky=W)
        self.lDistPath = Label(self.latbw, text="Distribution path:")
        self.userDistEntryField = Entry(self.latbw, width=60)  # Entry for use with user defined dist
        Label(self.latbw, text="Jitter value (ns):").grid(row=4, column=0, sticky=E)
        self.eJitterVal = Entry(self.latbw, width=10)
        self.eJitterVal.insert(0, "0")
        self.eJitterVal.grid(row=4, column=1, sticky=W, columnspan=2)
        ##

        ## Button to set latency and jitter, label to state time set
        self.bSet = Button(self.latbw, text="Set Latency Values", fg="blue",
                           command=lambda: conf.setLatency(self.eLatency, self.v.get(), self.portVar.get(),
                                                           self.distributions[distVar.get()],
                                                           self.userDistEntryField.get(), self.eJitterVal,
                                                           self.lLastSetLatency,
                                                           self.sshConnections[self.controlledConnectionVar.get()]))
        self.bSet.grid(row=5, column=3, columnspan=3, pady=(0, 40), sticky=W)
        self.lLastSetLatency = Label(self.latbw, text='')  # used to state the time of last set latency
        self.lLastSetLatency.grid(row=5, column=5, sticky=N)
        ##

        ## Set Rate Limiter
        Label(self.latbw, text="(default value: leave blank)").grid(row=8, column=3, columnspan=5, sticky=W)
        Label(self.latbw, text="Override burst size*:").grid(row=8, column=0, sticky=E)
        self.eBurst = Entry(self.latbw, width=10)
        self.eBurst.grid(row=8, column=1, sticky=W, columnspan=2)
        Label(self.latbw, text="(default value: 10)").grid(row=7, column=3, columnspan=5, sticky=W)
        Label(self.latbw, text="Bandwidth (Gb/s):").grid(row=7, column=0, sticky=E)
        self.eBandwidth = Entry(self.latbw, width=10)
        self.eBandwidth.grid(row=7, column=1, sticky=W, columnspan=2)

        self.bSetRate = Button(self.latbw, text="Set Rate Values", fg="blue",
                               command=lambda: conf.setRate(self.eBandwidth, self.eBurst, self.lCurrentBandwidth,
                                                            self.sshConnections[self.controlledConnectionVar.get()]))
        self.bSetRate.grid(row=9, column=3, columnspan=2)
        self.lCurrentBandwidth = Label(self.latbw, text='Bandwidth = 10.000000Gb/s')
        self.lCurrentBandwidth.grid(row=9, column=5)
        Label(self.latbw,
              text="*Warning: overriding burst size may lead to an approximation to your set bandwidth value").grid(
            row=10, column=0, sticky=W, columnspan=10)
        ##
        ###

        ### Read/Write Register
        self.regs = Tab(self.mainFrame, "Read/Write Register")

        ## Read/write direct
        Label(self.regs, text="Read/write direct", background="lightgrey").grid(row=0, column=0, columnspan=2, sticky=W)
        Label(self.regs, text="Read Register: 0x").grid(row=1, column=0)

        self.eRRegVar = StringVar()
        self.eRRegVar.trace('w', lambda aa, bb, cc: self.limitEntryLength(self.eRRegVar))  # limits to 8 characters
        self.eRReg = Entry(self.regs, width=8, textvariable=self.eRRegVar)
        self.eRReg.grid(row=1, column=1, sticky=W)
        self.bRead = Button(self.regs, text="Read", fg="blue",
                            command=lambda: conf.readRegister(self.lValue, self.eRReg,
                                                              self.sshConnections[self.controlledConnectionVar.get()]))
        self.bRead.grid(row=1, column=2, sticky=W)
        self.lValue = Label(self.regs, text="")
        self.lValue.grid(row=2, column=0, columnspan=8, sticky=W)

        Label(self.regs, text="Write Register: 0x").grid(row=3, column=0)
        self.eWRegVar = StringVar()
        self.eWRegVar.trace('w', lambda aa, bb, cc: self.limitEntryLength(self.eWRegVar))  # limits to 8 characters
        self.eWReg = Entry(self.regs, width=8, textvariable=self.eWRegVar)
        self.eWReg.grid(row=3, column=1, sticky=W)
        Label(self.regs, text="Value: 0x").grid(row=3, column=2)
        self.eWValVar = StringVar()
        self.eWValVar.trace('w', lambda aa, bb, cc: self.limitEntryLength(self.eWValVar))  # limits to 8 characters
        self.eWVal = Entry(self.regs, width=8, textvariable=self.eWValVar)
        self.eWVal.grid(row=3, column=3)
        self.bWrite = Button(self.regs, text="Write", fg="blue",
                             command=lambda: conf.writeRegister(self.eWReg.get(), self.eWVal.get(),
                                                                self.sshConnections[self.controlledConnectionVar.get()],
                                                                self.lWriteDirectStatus))
        self.bWrite.grid(row=3, column=4)
        self.lWriteDirectStatus = Label(self.regs, text="")
        self.lWriteDirectStatus.grid(row=3, column=5, columnspan=4, sticky=W)
        ##

        ## Read/write indirect
        Label(self.regs, text="Read/write indirect", background="lightgrey").grid(row=4, column=0, columnspan=2,
                                                                                  sticky=W, pady=(30, 0))
        Label(self.regs, text="Read Address: 0x").grid(row=5, column=0)
        self.eRReg2Var = StringVar()
        self.eRReg2Var.trace('w', lambda aa, bb, cc: self.limitEntryLength(self.eRReg2Var))  # limits to 8 characters
        self.eRReg2 = Entry(self.regs, width=8, textvariable=self.eRReg2Var)
        self.eRReg2.grid(row=5, column=1, sticky=W)
        Label(self.regs, text="Table:").grid(row=5, column=2, sticky=E)
        self.eRTabVar = StringVar()
        self.eRTabVar.trace('w', lambda aa, bb, cc: self.limitEntryLength(self.eRTabVar))  # limits to 8 characters
        self.eRTab = Entry(self.regs, width=8, textvariable=self.eRTabVar)
        self.eRTab.grid(row=5, column=3, sticky=W)
        Label(self.regs, text="Offset:").grid(row=5, column=4, sticky=E)
        self.eROffVar = StringVar()
        self.eROffVar.trace('w', lambda aa, bb, cc: self.limitEntryLength(self.eROffVar))  # limits to 8 characters
        self.eROff = Entry(self.regs, width=8, textvariable=self.eROffVar)
        self.eROff.grid(row=5, column=5, sticky=W)
        self.bRead2 = Button(self.regs, text="Read", fg="blue",
                             command=lambda: conf.readRegisterIndirect(self.lValue2, self.eRReg2, self.eRTab,
                                                                       self.eROff,
                                                                       self.sshConnections[
                                                                           self.controlledConnectionVar.get()]))
        self.bRead2.grid(row=5, column=6, sticky=W)
        self.lValue2 = Label(self.regs, text="")
        self.lValue2.grid(row=6, column=0, columnspan=8, sticky=W)

        Label(self.regs, text="Write Address: 0x").grid(row=7, column=0)
        self.eWReg2Var = StringVar()
        self.eWReg2Var.trace('w', lambda aa, bb, cc: self.limitEntryLength(self.eWReg2Var))  # limits to 8 characters
        self.eWReg2 = Entry(self.regs, width=8, textvariable=self.eWReg2Var)
        self.eWReg2.grid(row=7, column=1, sticky=W)
        Label(self.regs, text="Table:").grid(row=7, column=2, sticky=E)
        self.eWTabVar = StringVar()
        self.eWTabVar.trace('w', lambda aa, bb, cc: self.limitEntryLength(self.eWTabVar))  # limits to 8 characters
        self.eWTab = Entry(self.regs, width=8, textvariable=self.eWTabVar)
        self.eWTab.grid(row=7, column=3)
        Label(self.regs, text="Offset:").grid(row=7, column=4, sticky=E)
        self.eWOffVar = StringVar()
        self.eWOffVar.trace('w', lambda aa, bb, cc: self.limitEntryLength(self.eWOffVar))  # limits to 8 characters
        self.eWOff = Entry(self.regs, width=8, textvariable=self.eWOffVar)
        self.eWOff.grid(row=7, column=5, sticky=W)
        Label(self.regs, text="Value: 0x").grid(row=7, column=6, sticky=E)
        self.eWVal2Var = StringVar()
        self.eWVal2Var.trace('w', lambda aa, bb, cc: self.limitEntryLength(self.eWVal2Var))  # limits to 8 characters
        self.eWVal2 = Entry(self.regs, width=8, textvariable=self.eWVal2Var)
        self.eWVal2.grid(row=7, column=7, sticky=W)
        self.bWrite2 = Button(self.regs, text="Write", fg="blue",
                              command=lambda: conf.writeRegisterIndirect(self.eWReg2, self.eWTab, self.eWOff,
                                                                         self.eWVal2, self.lWriteIndirectStatus,
                                                                         self.sshConnections[
                                                                             self.controlledConnectionVar.get()]))
        self.bWrite2.grid(row=7, column=8)
        self.lWriteIndirectStatus = Label(self.regs, text="")
        self.lWriteIndirectStatus.grid(row=8, column=5, sticky=E, columnspan=4)
        ##
        ###

        ### Load bitfile
        self.loadBit = Tab(self.mainFrame, "Load Bitfile")
        Label(self.loadBit, text="Warning: This can take approximately 1 minute.").grid(row=0, column=0, sticky=W)

        ## Local bitfile
        Label(self.loadBit, text="Upload and flash local bitfile:", background="lightgrey").grid(row=1, column=0,
                                                                                                 sticky=W)
        self.lLocalBitfilePath = Label(self.loadBit, text="No file selected")
        self.lLocalBitfilePath.grid(row=2, column=0)
        self.bBrowseBitfile = Button(self.loadBit, text="Browse", fg="blue",
                                     command=lambda: self.openBitfile(self.lLocalBitfilePath, self.bLoadLocalBitfile))
        self.bBrowseBitfile.grid(row=2, column=1)
        self.bLoadLocalBitfile = Button(self.loadBit, text="Load", fg="blue", state=DISABLED,
                                        command=lambda: conf.loadLocalBitfile(self.lLocalBitfilePath.cget("text"),
                                                                              self.lLocalBitfileStatus,
                                                                              self.sshConnections[
                                                                                  self.controlledConnectionVar.get()]))
        self.bLoadLocalBitfile.grid(row=2, column=2)
        self.lLocalBitfileStatus = Label(self.loadBit, text="")
        self.lLocalBitfileStatus.grid(row=3, column=0)
        ##

        ## Remote bitfile
        Label(self.loadBit, text="Specify remote bitfile path to flash:", background="lightgrey").grid(row=4, column=0,
                                                                                                       sticky=W, pady=(30,0))
        self.eBitfile = Entry(self.loadBit, width=65)
        self.eBitfile.grid(row=5, column=0, sticky=W)
        self.bLoadBitfile = Button(self.loadBit, text="Load", fg="blue",
                                   command=lambda: conf.loadBitfile(self.eBitfile, self.lRemoteBitfileStatus,
                                                                    self.sshConnections[
                                                                        self.controlledConnectionVar.get()]))
        self.bLoadBitfile.grid(row=5, column=1)
        self.lRemoteBitfileStatus = Label(self.loadBit, text="")
        self.lRemoteBitfileStatus.grid(row=6, column=0)
        ##
        ###

        ### SSH connections
        self.ssh = Tab(self.mainFrame, "SSH Connections")
        self.addHostFrame = Frame(self.ssh, width=400, height=175)  # for the entries, labels etc to add a host
        self.addHostFrame.pack()
        self.buttonsFrame = Frame(self.ssh, width=400, height=25)  # for the import/export/delete buttons
        self.buttonsFrame.pack(pady=20)
        self.addedHostsFrame = Frame(self.ssh, width=400, height=225)  # for the labels for details of added hosts
        self.addedHostsFrame.pack()

        ## Add host
        # row0
        Label(self.addHostFrame, text="Hostname:").grid(row=0, column=0)
        self.eHostname = Entry(self.addHostFrame, width=35)
        self.eHostname.grid(row=0, column=1, columnspan=3, sticky=W)
        Label(self.addHostFrame, text="Port:").grid(row=0, column=7, sticky=E)
        self.ePort = Entry(self.addHostFrame, width=5)
        self.ePort.insert(0, "22")
        self.ePort.grid(row=0, column=9, sticky=W)
        # row1
        Label(self.addHostFrame, text="Username:").grid(row=1, column=0)
        self.eUsername = Entry(self.addHostFrame, width=16)
        self.eUsername.grid(row=1, column=1, columnspan=3, sticky=W)
        Label(self.addHostFrame, text="Password:").grid(row=1, column=7, sticky=E)
        self.ePassword = Entry(self.addHostFrame, width=20, show="*")
        self.ePassword.grid(row=1, column=9, sticky=W)
        # row2
        Label(self.addHostFrame, text="Private key").grid(row=2, column=0)
        self.cbVar = IntVar(value=0)
        self.cbUsePrivateKey = Checkbutton(self.addHostFrame, variable=self.cbVar, command=lambda: self.togglePKey())
        self.cbUsePrivateKey.grid(row=2, column=1, sticky=W)
        self.lPrivateKeyFileString = Label(self.addHostFrame, text="No file selected")
        self.lPrivateKeyFileString.grid(row=2, column=2)
        self.bBrowse = Button(self.addHostFrame, text="Browse", fg="blue", state=DISABLED,
                              command=lambda: self.getKeyPath(self.lPrivateKeyFileString, self.bAddHost))
        self.bBrowse.grid(row=2, column=3)
        Label(self.addHostFrame, text="Passphrase:").grid(row=2, column=7, sticky=E)
        self.ePassphrase = Entry(self.addHostFrame, width=20, show="*", state=DISABLED)
        self.ePassphrase.grid(row=2, column=9, sticky=W)
        # row3
        Label(self.addHostFrame, text="Unique connection name (leave blank for default value):").grid(row=3, column=0,
                                                                                                      columnspan=9,
                                                                                                      sticky=E)
        self.connectionName = Entry(self.addHostFrame, width=20)
        self.connectionName.grid(row=3, column=9, sticky=W)
        # row4
        self.bAddHost = Button(self.addHostFrame, text="Connect + add host", fg="blue",
                               command=lambda: self.addHost(self.eHostname.get(), self.ePort.get(),
                                                            self.eUsername.get(), self.ePassword.get(),
                                                            self.cbVar.get(),
                                                            self.lPrivateKeyFileString.cget("text"),
                                                            self.ePassphrase.get(), self.tabs,
                                                            self.connectionState, self.connectionName.get(),
                                                            self.sshConnections),
                               state=NORMAL)
        self.bAddHost.grid(row=4, column=9, sticky=E)
        ##

        ## Import/export/delete hosts
        self.bExportHosts = Button(self.buttonsFrame, text="Export hosts file", fg="blue", command=self.saveSSHDetails)
        self.bExportHosts.grid(row=0, column=0, sticky=W)
        self.bImportHosts = Button(self.buttonsFrame, text="Import hosts file", fg="blue", command=self.readSSHDetails)
        self.bImportHosts.grid(row=0, column=1, sticky=W, padx=40)
        self.bDeleteHosts = Button(self.buttonsFrame, text="Delete selected", fg="blue", state=DISABLED,
                                   command=lambda: self.deleteSelected(self.connectionNameLabels, self.hostLabels,
                                                                       self.keyLabels, self.buttons, self.boxes))
        self.bDeleteHosts.grid(row=0, column=2)
        self.connectionState = Label(self.addHostFrame, text="Disconnected")
        ##

        ## Added hosts
        self.scrollWindow = tix.ScrolledWindow(self.addedHostsFrame, scrollbar=tix.Y)
        self.connectionNameLabels = []  # labels/buttons/boxes for added hosts
        self.hostLabels = []
        self.keyLabels = []
        self.buttons = []
        self.boxes = []  # checkboxes used to delete added hosts
        ##
        ###

        ### Command Interface
        self.term = Tab(self.mainFrame, "Terminal")
        self.eCommand = Entry(self.term, width=50)
        self.eCommand.grid(row=1, column=0)
        self.bSend = Button(self.term, text="Send", fg="blue",
                            command=lambda: conf.sendCommand(self.lCommandReturn, self.eCommand, None,
                                                             self.sshConnections[self.controlledConnectionVar.get()]))
        self.bSend.grid(row=1, column=1)

        self.lCommandReturn = Label(self.term, text="", wraplength=1000)
        self.lCommandReturn.grid(row=2, column=0)
        ###

        ### Run experiments
        self.exps = Tab(self.mainFrame, "Run Experiments")

        ## Configure
        Label(self.exps, text="Experiment:").grid(row=0, column=0, sticky=E)
        # Experiment select
        self.expVar = StringVar(master)
        self.expVar.set("Ping")  # default value
        self.experimentOptions = ["Ping", "iPerf", "Memcached"]
        self.experimentSelect = OptionMenu(self.exps, self.expVar, *self.experimentOptions)
        self.experimentSelect.var = self.expVar
        self.experimentSelect.grid(row=0, column=1, sticky=W)

        # Latency select
        Label(self.exps, text="Latency time unit:").grid(row=1, column=0, sticky=E)
        self.timeUnitVar = StringVar(master)
        self.timeUnitVar.set("ns")  # default value
        self.timeUnitOptions = {"ns": 1, "μs": 1000, "ms": 1000000, "s": 1000000000}
        self.timeUnitSelect = OptionMenu(self.exps, self.timeUnitVar, *self.timeUnitOptions)
        self.timeUnitSelect.grid(row=1, column=1, sticky=W)
        Label(self.exps, text="Latency start:").grid(row=2, column=0, sticky=E)
        self.latStart = Entry(self.exps, width=5)
        self.latStart.grid(row=2, column=1, sticky=W)
        Label(self.exps, text="Latency end:").grid(row=3, column=0, sticky=E)
        self.latEnd = Entry(self.exps, width=5)
        self.latEnd.grid(row=3, column=1, sticky=W)
        Label(self.exps, text="Latency stride:").grid(row=4, column=0, sticky=E)
        self.latStride = Entry(self.exps, width=5)
        self.latStride.grid(row=4, column=1, sticky=W)

        # Length
        Label(self.exps, text="Experiment length at each latency (s):").grid(row=5, column=0, sticky=E)
        self.eLength = Entry(self.exps, width=5)
        self.eLength.grid(row=5, column=1, sticky=W)
        # Port
        Label(self.exps, text="Port:").grid(row=6, column=0, sticky=E)
        self.portSelectVar = StringVar(master)
        self.portSelectVar.set("Port 0")  # default value
        self.portOptions = ["Port 0", "Port 1", "Both"]
        self.portSelect = OptionMenu(self.exps, self.portSelectVar, *self.portOptions)
        self.portSelect.grid(row=6, column=1, sticky=W)
        # Jitter
        Label(self.exps, text="Jitter distribution:").grid(row=7, column=0, sticky=E)
        self.expDistVar = StringVar(master)
        self.expDistVar.set("No Jitter")  # default value
        self.expDistMenu = OptionMenu(self.exps, self.expDistVar, *self.distributions,
                                      command=self.toggleExpUserDistField)
        self.expDistMenu.grid(row=7, column=1, columnspan=3, sticky=W)
        self.lExpDistPath = Label(self.exps, text="Distribution path:")
        self.expUserDistEntryField = Entry(self.exps, width=60)  # Entry for use with user defined dist
        Label(self.exps, text="Jitter value (ns):").grid(row=10, column=0, sticky=E)
        self.eExpJitterVal = Entry(self.exps, width=10)
        self.eExpJitterVal.insert(0, "0")
        self.eExpJitterVal.grid(row=10, column=1, sticky=W, columnspan=2)
        # Server
        Label(self.exps, text="Server:").grid(row=11, column=0, sticky=E)
        self.controlledServerVar = StringVar(master)
        self.controlledServerVar.set(None)  # default value
        self.controlledServerSelect = OptionMenu(self.exps, self.controlledServerVar,
                                                 *self.controlledConnectionOptions)
        self.controlledServerSelect.grid(row=11, column=1, sticky=W)
        # Client
        Label(self.exps, text="Client:").grid(row=12, column=0, sticky=E)
        self.controlledClientVar = StringVar(master)
        self.controlledClientVar.set(None)  # default value
        self.controlledClientSelect = OptionMenu(self.exps, self.controlledClientVar,
                                                 *self.controlledConnectionOptions)
        self.controlledClientSelect.grid(row=12, column=1, sticky=W)
        # Directory
        Label(self.exps, text="Enter name of directory to save experiment results in:").grid(row=13, column=0, sticky=E)
        self.eExperimentDirectory = Entry(self.exps, width=25)
        self.eExperimentDirectory.grid(row=14, column=0, sticky=E)
        self.lExperimentStatus = Label(self.exps, text="")
        self.lExperimentStatus.grid(row=15, column=0, sticky=E)
        # Launch
        self.bLaunch = Button(self.exps, text="Launch", fg="blue", width=7,
                              command=lambda: experiments.executeExperiments(self.expVar.get(), self.latStart.get(),
                                                                             self.latEnd.get(), self.latStride.get(),
                                                                             self.timeUnitOptions[
                                                                                 self.timeUnitVar.get()],
                                                                             self.eLength.get(),
                                                                             self.portSelectVar.get(),
                                                                             self.distributions[self.expDistVar.get()],
                                                                             self.expUserDistEntryField.get(),
                                                                             self.eExpJitterVal,
                                                                             self.eExperimentDirectory.get(),
                                                                             self.sshConnections[
                                                                                 self.controlledServerVar.get()],
                                                                             self.sshConnections[
                                                                                 self.controlledClientVar.get()],
                                                                             self.experimentDictionary,
                                                                             self.lExperimentStatus, root, defaultPath))
        self.bLaunch.grid(row=15, column=1, sticky=W)
        # Import experiment
        self.bImport = Button(self.exps, text="Import settings", fg="blue", command=lambda: self.importExp())
        self.bImport.grid(row=16, column=0, sticky=W)
        ##
        ###


        ### Add Experiments
        self.addExps = Tab(self.mainFrame, "Add Experiments")

        ## Config
        # Name
        Label(self.addExps, text="Experiment name:").grid(row=0, column=0, sticky=E)
        self.eExpName = Entry(self.addExps, width=30)
        self.eExpName.grid(row=0, column=1, sticky=W)
        # Server command
        Label(self.addExps, text="Server command:").grid(row=1, column=0, sticky=E)
        self.eServerCommand = Entry(self.addExps, width=60)
        self.eServerCommand.grid(row=1, column=1, sticky=W)
        # Client command
        Label(self.addExps, text="Client command:").grid(row=2, column=0, sticky=E)
        self.eClientCommand = Entry(self.addExps, width=60)
        self.eClientCommand.grid(row=2, column=1, sticky=W)
        # Parse script select
        Label(self.addExps, text="Parse script:").grid(row=3, column=0, sticky=E)
        self.lScriptPath = Label(self.addExps, text="No file selected")
        self.lScriptPath.grid(row=3, column=1)
        self.bBrowseScript = Button(self.addExps, text="Browse", fg="blue",
                                    command=lambda: self.openParseScript(self.lScriptPath))
        self.bBrowseScript.grid(row=3, column=2)
        # Save experiment
        self.bSaveExperiment = Button(self.addExps, text="Save Experiment", fg="blue",
                                      command=lambda: exp.saveExperiment(self.experimentOptions, self.experimentSelect,
                                                                         self.experimentDictionary,
                                                                         self.eExpName.get(),
                                                                         self.eServerCommand.get(),
                                                                         self.eClientCommand.get(),
                                                                         self.lScriptPath.cget("text")))
        self.bSaveExperiment.grid(row=4, column=0, sticky=E, pady=(0, 40))
        ##

        ## Import/export custom experiment
        self.bImportExperiments = Button(self.addExps, text="Import Experiments", fg="blue",
                                         command=lambda: exp.importExperiments(self.experimentOptions,
                                                                               self.experimentSelect,
                                                                               self.experimentDictionary,
                                                                               self.lImportExportStatus))
        self.bImportExperiments.grid(row=5, column=0, sticky=W)
        self.bExportExperiments = Button(self.addExps, text="Export Experiments", fg="blue",
                                         command=lambda: exp.exportExperiments(self.experimentDictionary,
                                                                               self.lImportExportStatus))
        self.bExportExperiments.grid(row=5, column=1, sticky=W)
        self.lImportExportStatus = Label(self.addExps, text="")
        self.lImportExportStatus.grid(row=6, column=0, sticky=W, columnspan=2)
        ##
        ###

        # add all the tabs to the tab bar
        self.tabs.addTab(self.ssh)
        self.tabs.addTab(self.latbw)
        self.tabs.addTab(self.regs)
        self.tabs.addTab(self.loadBit)
        self.tabs.addTab(self.term)
        self.tabs.addTab(self.exps)
        self.tabs.addTab(self.addExps)

        for button in self.tabs.tabButtons.values():  # on first launch, disable all tabs but "SSH Connections"
            if button['text'] != 'SSH Connections':
                button.config(state=DISABLED)

        ## Menu
        self.menu = Menu(master)
        master.config(menu=self.menu)
        self.subMenu = Menu(self.menu)
        self.menu.add_cascade(label="File", menu=self.subMenu)
        self.subMenu.add_command(label="Quit", command=self.mainFrame.quit)
        ##

        self.sideFrame.pack(side=LEFT, fill=Y)
        self.connectionFrame.pack(side=TOP, fill=BOTH)
        self.mainFrame.pack(side=TOP, fill=BOTH)
        self.mainScreen.pack(side=TOP, fill=BOTH)

        self.tabs.pack(side=TOP, fill=X)  # display the bar itself
        self.tabs.changeTab("SSH Connections")  # change tab to default tab, SSH Connections

    def addConnectionNameLabel(self, label):
        Label(self.scrollWindow.window, text="NAME").grid(row=0, column=0, padx=5)
        self.connectionNameLabels.append(label)
        i = 1
        for labs in self.connectionNameLabels:
            labs.grid(row=i, column=0, padx=5)
            i += 1

    def addHostLabel(self, label):
        Label(self.scrollWindow.window, text="HOST").grid(row=0, column=1, padx=5)
        self.hostLabels.append(label)
        i = 1
        for labs in self.hostLabels:
            labs.grid(row=i, column=1, padx=5)
            i += 1

    def addKeyLabel(self, label):
        Label(self.scrollWindow.window, text="KEY PATH").grid(row=0, column=2, padx=5)
        self.keyLabels.append(label)
        i = 1
        for labs in self.keyLabels:
            labs.grid(row=i, column=2, padx=5)
            i += 1

    def addConnectionButton(self, button):
        self.buttons.append(button)
        i = 1
        for butt in self.buttons:
            butt.grid(row=i, column=3, padx=5)
            i += 1

    def addSelectBox(self, box):
        self.boxes.append(box)
        i = 1
        for box in self.boxes:
            box.grid(row=i, column=4, padx=5)
            i += 1

    def addHost(self, host, port, username, password,
                usePrivateKey, key, passphrase, tabs, lConnectionState, conName, sshConnections):
        if conName == '':
            while True:
                # here to ensure that a connection name is always found, increments number again in the case of the user
                # choosing a connection of the form "Connection<number>"
                conName = "Connection" + str(self.conNumber)
                if conName in self.sshConnections:
                    self.conNumber += 1  # if it does exist, increment by 1 and try again
                else:
                    break
        elif conName.startswith("#"):  # cannot start with # as this is used to denote comments in the hosts file
            print("Connection names cannot start with a '#'")
            lConnectionState.config(text="Name Error")
            lConnectionState.grid(row=5, column=9, sticky=E)
            return
        if conName in self.sshConnections:  # if the name the user chose is already in sshConnections
            x = self.sshConnections[conName]
            if x is None:  # check if the entry is None, in which case it is from a disconnected connection
                print("Connection name is taken by a disconnected connection")
            else:  # otherwise its from one that is currently connected
                print("Connection name is taken by another connection")
            return
        else:
            print("Connection name \"" + conName + "\" is unique")

        self.SSHConnect(conName, host, port, username, password, usePrivateKey, key, passphrase, tabs, lConnectionState,
                        sshConnections)  # make the connection

        if conName not in self.sshConnections:  # if it failed, return
            return

        self.conNumber += 1
        try:
            port = int(port)
        except ValueError:
            port = 22  # warning is already displayed to user in SSHConnect
        if not usePrivateKey:
            key = None
            passphrase = None
        if passphrase == '':
            passphrase = None
        conNameLabel = Label(self.scrollWindow.window, text=conName)
        self.addConnectionNameLabel(conNameLabel)
        hostText = username + "@" + host + ":" + str(port)
        hostLab = Label(self.scrollWindow.window, text=hostText)
        self.addHostLabel(hostLab)
        keyLab = Label(self.scrollWindow.window, text=key)
        self.addKeyLabel(keyLab)
        connectionButton = Button(self.scrollWindow.window, text="Disconnect", fg="blue",  # make a button to disconnect
                                  command=lambda: self.disconnect(conName, connectionButton))
        self.addConnectionButton(connectionButton)
        cbVar = IntVar(value=0)
        cbSelected = Checkbutton(self.scrollWindow.window, variable=cbVar)
        cbSelected.var = cbVar

        self.addSelectBox(cbSelected)

        # add details to dictionary for later connections after disconnections
        self.sshDetails[conName] = (host, port, username, password, usePrivateKey, key, passphrase)
        self.bImportHosts.config(state=DISABLED)  # can not import more hosts when hosts already exist
        self.bDeleteHosts.config(state=NORMAL)  # we have at least 1 host, so enable deletion
        self.scrollWindow.pack(fill=tix.BOTH, expand=1, pady=(20, 0))

    def disconnect(self, conName, button=None):
        self.sshConnections[conName].close()  # close the connection
        self.sshConnections[conName] = None  # keeps conName as a key so it can't be used elsewhere
        if button is not None:  # make a button to connect (if button is None then the entry is being deleted)
            button.config(text="Connect", command=lambda: self.connect(button, conName, *self.sshDetails[conName]))
        print("Disconnected from \"" + conName + "\"")
        self.controlledConnectionOptions.remove(conName)  # remove the option to select this connection
        self.refreshControlledOptions()  # refresh the menu widgets

    def deleteSelected(self, connectionNameLabels, hostLabels, keyLabels, buttons, boxes):
        i = 0
        indexesToDel = []  # maintains a list of indexes that need to be deleted
        for box in boxes:
            if box.var.get():  # if this box is selected
                indexesToDel.append(i)  # mark the index
                box.destroy()  # destroy the box, labels, button
                lConName = connectionNameLabels[i]
                self.delete(lConName.cget("text"))  # disconnect connection, and delete the entries in dictionaries
                lConName.destroy()
                hostLabels[i].destroy()
                keyLabels[i].destroy()
                buttons[i].destroy()
            i += 1
        j = 0
        for i in indexesToDel:
            del boxes[i - j]  # "-j" as we shorten the list as we delete entries
            del hostLabels[i - j]
            del keyLabels[i - j]
            del buttons[i - j]
            del connectionNameLabels[i - j]
            j += 1
        self.refreshButtons()  # ensure the import and delete buttons are in the correct state

    def delete(self, conName):
        if self.sshConnections[conName] is not None:  # want to delete connection, disconnect it first if connected
            self.disconnect(conName)
        del self.sshConnections[conName]
        del self.sshDetails[conName]

    def connect(self, button, conName, sHost, iPort, sUsername, sPassword, usePrivateKey, sKey, sPassphrase):
        # called if previously connected + disconnected, and want to reconnect
        k = None
        if usePrivateKey:
            print("Using key: " + sKey)
            try:
                k = paramiko.RSAKey.from_private_key_file(sKey, password=sPassphrase)
            except IOError:
                print("Error reading key file")
                tkinter.messagebox.showerror("Error", "Error reading key file")
                return
            except paramiko.PasswordRequiredException:
                print("Private key file is encrypted and no password is supplied")
                tkinter.messagebox.showerror("Error", "Private key file is encrypted and needs passphrase")
                return
            except paramiko.SSHException:
                print("Key file is invalid or passphrase is incorrect")
                tkinter.messagebox.showerror("Error", "Private key file is invalid or passphrase is incorrect")
                return
        client = paramiko.SSHClient()
        client.load_system_host_keys()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        try:
            client.connect(sHost, port=iPort, username=sUsername, password=sPassword, pkey=k)
        except paramiko.AuthenticationException:
            print("Bad authentication")
            return
        except paramiko.SSHException:
            print("Error connecting")
            return
        except socket_error:
            print("Socket error")
            return
        print("Connected")
        self.sshConnections[conName] = client
        for tabButton in self.tabs.tabButtons.values():
            tabButton.config(state=NORMAL)  # enable other tabs
        button.config(text="Disconnect", command=lambda: self.disconnect(conName, button))  # add button to disconenct

        # refresh the list of connections that can be selected
        self.controlledConnectionOptions.append(conName)
        self.refreshControlledOptions()
        self.controlledConnectionVar.set(conName)

    def SSHConnect(self, conName, host, port, username, password,
                   usePrivateKey, key, passphrase, tabs, lConnectionState, sshConnections):
        lConnectionState.config(text="Connecting...")
        lConnectionState.grid(row=5, column=9, sticky=E)
        root.update()  # updates the label
        try:
            port = int(port)
        except ValueError:
            tkinter.messagebox.showwarning("Warning", "Invalid port number. Defaulting to 22.")
            port = 22
            self.ePort.delete(0, END)
            self.ePort.insert(0, str(22))
        if passphrase == '':
            passphrase = None
        k = None
        if usePrivateKey:
            print("Using key: " + key)
            try:
                k = paramiko.RSAKey.from_private_key_file(key, password=passphrase)
            except IOError:
                print("Error reading key file")
                tkinter.messagebox.showerror("Error", "Error reading key file")
                return
            except paramiko.PasswordRequiredException:
                print("Private key file is encrypted and no password is supplied")
                tkinter.messagebox.showerror("Error", "Private key file is encrypted and needs passphrase")
                return
            except paramiko.SSHException:
                print("Key file is invalid or passphrase is incorrect")
                tkinter.messagebox.showerror("Error", "Private key file is invalid or passphrase is incorrect")
                return
            finally:
                lConnectionState.config(text="Key Error")
        client = paramiko.SSHClient()
        client.load_system_host_keys()
        client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        try:
            client.connect(host, port=port, username=username, password=password, pkey=k)
        except paramiko.AuthenticationException:
            print("Bad authentication")
            lConnectionState.config(text="Authentication failed")
            return
        except paramiko.SSHException:
            print("Error connecting")
            lConnectionState.config(text="Error connecting")
            return
        except socket_error:
            print("Socket error")
            lConnectionState.config(text="Failed to connect")
            return
        print("Connected")
        sshConnections[conName] = client  # save the client in sshConnections
        for button in tabs.tabButtons.values():
            button.config(state=NORMAL)  # make sure the buttons to other tabs are enabled
        lConnectionState.grid_forget()  # once we're connected, the connection is in the list so don't need state label
        self.controlledConnectionOptions.append(conName)
        self.refreshControlledOptions()
        self.controlledConnectionVar.set(conName)

    def toggleUserDistField(self, value):
        if self.distributions[value] == 16:
            self.userDistEntryField.grid(row=3, column=1, columnspan=6, sticky=W)
            self.lDistPath.grid(row=3, column=0, sticky=E)
        else:
            self.userDistEntryField.grid_forget()
            self.lDistPath.grid_forget()

    def toggleExpUserDistField(self, value):
        if self.distributions[value] == 16:
            self.expUserDistEntryField.grid(row=9, column=0, sticky=W)
            self.lExpDistPath.grid(row=8, column=0, sticky=E)
        else:
            self.expUserDistEntryField.grid_forget()
            self.lExpDistPath.grid_forget()

    def getKeyPath(self, lKeyPath, bSSHConnect):
        filename = askopenfilename()
        if filename == '':
            filename = "No file selected"
            bSSHConnect.config(state=DISABLED)
        else:
            bSSHConnect.config(state=NORMAL)
        lKeyPath.config(text=filename)

    def togglePKey(self):
        if self.cbVar.get():
            if self.lPrivateKeyFileString.cget("text") == "No file selected":
                self.bAddHost.config(state=DISABLED)
            self.ePassphrase.config(state=NORMAL)
            self.bBrowse.config(state=NORMAL)
            self.ePassword.delete(0, END)
            self.ePassword.insert(0, "")
            self.ePassword.config(state=DISABLED)
        else:
            self.bAddHost.config(state=NORMAL)
            self.ePassphrase.delete(0, END)
            self.ePassphrase.insert(0, "")
            self.ePassphrase.config(state=DISABLED)
            self.bBrowse.config(state=DISABLED)
            self.ePassword.config(state=NORMAL)
            self.lPrivateKeyFileString.config(text="No file selected")

    def limitEntryLength(self, var):
        value = var.get()
        if len(value) > 8:
            var.set(value[:8])
            print("\a")  # produces error sound

    def importExp(self):
        filename = askopenfilename()
        if filename == '':
            return
        fh = open(filename, "r")
        for line in fh:
            if line.startswith("Experiment: "):
                self.expVar.set(line[line.find(": ") + 2:-1])
            elif line.startswith("Latency multiplier: "):
                timeUnitConversion = {1: "ns", 1000: "μs", 1000000: "ms", 1000000000: "s"}
                self.timeUnitVar.set(timeUnitConversion[int(line[line.find(": ") + 2:-1])])
            elif line.startswith("Start latency: "):
                self.latStart.delete(0, END)
                self.latStart.insert(0, line[line.find(": ") + 2:-1])
            elif line.startswith("End latency: "):
                self.latEnd.delete(0, END)
                self.latEnd.insert(0, line[line.find(": ") + 2:-1])
            elif line.startswith("Stride latency: "):
                self.latStride.delete(0, END)
                self.latStride.insert(0, line[line.find(": ") + 2:-1])
            elif line.startswith("Per experiment length: "):
                self.eLength.delete(0, END)
                self.eLength.insert(0, line[line.find(": ") + 2:-1])
            elif line.startswith("Port select: "):
                self.portSelectVar.set(line[line.find(": ") + 2:-1])
            elif line.startswith("Jitter value: "):
                self.eExpJitterVal.delete(0, END)
                self.eExpJitterVal.insert(0, line[line.find(": ") + 2:-1])
            elif line.startswith("Jitter type: "):
                distributionConversion = {0: "No Jitter", 1: "Uniform", 2: "Normal", 4: "Pareto", 8: "Pareto Normal",
                                          16: "User Defined"}
                self.expDistVar.set(distributionConversion[int(line[line.find(": ") + 2:-1])])
            elif line.startswith("User dist path: "):
                self.expUserDistEntryField.delete(0, END)
                self.expUserDistEntryField.insert(0, line[line.find(": ") + 2:-1])
        fh.close()

    def refreshControlledOptions(self):
        self.controlledConnectionVar.set('')
        self.controlledServerVar.set('')
        self.controlledClientVar.set('')
        self.controlledSelect['menu'].delete(0, 'end')  # delete old options
        self.controlledServerSelect['menu'].delete(0, 'end')
        self.controlledClientSelect['menu'].delete(0, 'end')
        removeNone = False
        for conName in self.controlledConnectionOptions:
            if conName is None and self.controlledConnectionOptions.__len__() != 1:
                removeNone = True
                continue
            self.controlledSelect['menu'].add_command(label=conName,  # add the options back
                                                      command=tkinter._setit(self.controlledConnectionVar, conName))
            self.controlledConnectionVar.set(conName)
            self.controlledServerSelect['menu'].add_command(label=conName,  # add the options back
                                                            command=tkinter._setit(self.controlledServerVar, conName))
            self.controlledServerVar.set(conName)
            self.controlledClientSelect['menu'].add_command(label=conName,  # add the options back
                                                            command=tkinter._setit(self.controlledClientVar, conName))
            self.controlledClientVar.set(conName)
        if removeNone:
            self.controlledConnectionOptions.remove(None)
        if self.controlledConnectionOptions.__len__() == 0:
            for button in self.tabs.tabButtons.values():
                if button['text'] != 'SSH Connections':
                    button.config(state=DISABLED)

    def refreshButtons(self):
        if self.connectionNameLabels.__len__() == 0:
            self.bImportHosts.config(state=NORMAL)
            self.bDeleteHosts.config(state=DISABLED)

    def saveSSHDetails(self):
        f = asksaveasfilename(title="Select file", filetypes=(("Config files", "*.conf"), ("All files", "*.*")),
                              defaultextension='.conf')
        if f is '':
            return
        fh = open(f, "w+")
        for conName in self.sshDetails:
            print("Saving details for " + conName)
            host, port, username, password, usePrivateKey, key, passphrase = self.sshDetails[conName]
            usePassword = 0
            if not usePrivateKey and password != '':
                usePassword = 1
            usePassphrase = 0
            if usePrivateKey and passphrase != '':
                usePassphrase = 1
            if key is None:
                key = "No key"
            fh.write(conName + "\n" + host + "\n" + str(port) + "\n" + username + "\n" + str(usePassword) + "\n" + str(
                usePrivateKey) + ":" + key + "\n" + str(usePassphrase) + "\n\n")
        fh.close()

    def readSSHDetails(self):
        filename = askopenfilename(title="Select file", filetypes=(("Config files", "*.conf"), ("All files", "*.*")))
        if not os.path.exists(filename):
            return
        fh = open(filename, "r")
        i = 0
        conName = None
        host = None
        port = None
        username = None
        usePassword = None
        useKeyAndPath = None
        usePassphrase = None
        for line in fh:
            if line.startswith("#"):
                continue
            if i == 0:
                conName = line[:-1]
            elif i == 1:
                host = line[:-1]
            elif i == 2:
                port = int(line[:-1])
            elif i == 3:
                username = line[:-1]
            elif i == 4:
                usePassword = int(line[:-1])
            elif i == 5:
                useKeyAndPath = line[:-1]
            elif i == 6:
                usePassphrase = int(line[:-1])
            elif i == 7:
                self.createImportedHost(conName, host, port, username, usePassword, useKeyAndPath, usePassphrase)
                i = 0
                continue
            i += 1
        fh.close()

    def openBitfile(self, label, bLoadBitfile):
        filename = askopenfilename(title="Select bitfile", filetypes=(("Bitfiles", "*.bit"), ("All files", "*.*")))
        if not os.path.exists(filename):
            label.config(text="No file selected")
            bLoadBitfile.config(state=DISABLED)
            return
        label.config(text=filename)
        bLoadBitfile.config(state=NORMAL)

    def openParseScript(self, label):
        filename = askopenfilename(title="Select parse script",
                                   filetypes=(("Python file", "*.py"), ("All files", "*.*")))
        if not os.path.exists(filename):
            label.config(text="No file selected")
            return
        label.config(text=filename)

    def createImportedHost(self, conName, host, port, username, usePassword, useKeyAndPath, usePassphrase):
        # create labels, prompt for passwords/passphrases, add to sshDetails
        password = ''
        if usePassword:  # password is not stored on file, so prompt for it
            password = tkinter.simpledialog.askstring("Password",
                                                      "Enter password for " + username + "@" + host + ":" + str(port),
                                                      show='*')
        if useKeyAndPath.startswith("1:"):
            usePrivateKey = 1
            key = useKeyAndPath[2:]
        else:
            usePrivateKey = 0
            key = None
        if usePassphrase:  # passphrase is not stored on file, so prompt for it
            passphrase = tkinter.simpledialog.askstring("Passphrase", "Enter passphrase for " + key, show='*')
        else:
            passphrase = ''
        self.addHost(host, port, username, password, usePrivateKey, key, passphrase, self.tabs, self.connectionState,
                     conName, self.sshConnections)


defaultPath = os.path.dirname(os.path.realpath(__file__))
os.chdir(defaultPath)
root = tix.Tk()
root.title("NRG Control Interface")
default_font = tkinter.font.nametofont("TkDefaultFont")
default_font.configure(size=10)
root.option_add("*Font", default_font)
b = ControlInterface(root)
root.mainloop()
