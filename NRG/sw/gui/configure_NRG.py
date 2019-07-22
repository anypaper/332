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

from time import gmtime, strftime
import tkinter.messagebox
from tkinter import *
from fractions import Fraction
from decimal import Decimal
import math
import os


def loadBitfile(eBitfile, lStatus, sshConnection):
    path = eBitfile.get()
    command = "test -f " + path + " ; echo $?"  # test file exists on remote machine
    stdin, stdout, stderr = sshConnection.exec_command(command)
    out = stdout.read()
    if out != b'0\n':  # if file does not exist
        lStatus.config(text="Error - path does not exist on remote machine")
        return
    command = "/root/nrg/NetFPGA-SUME-dev/lib/sw/std/apps/sume_riffa_v1_0_0/load_image.sh " + path
    stdin, stdout, stderr = sshConnection.exec_command(command)  # flash file
    out = stdout.read()
    print(out)
    if out.find(b'ERROR: Failed to download the bit file') != -1:  # if XMD gives us an error while flashing
        lStatus.config(text="Error - file did not flash successfully")
        return
    lStatus.config(text="File successfully flashed")


def loadLocalBitfile(path, lStatus, sshConnection):
    if not os.path.exists(path):  # occurs if user deletes file between browsing and loading
        lStatus.config(text="Error - file no longer exists on local machine")
        return
    sftp = sshConnection.open_sftp()
    ctime = strftime("%Y%m%d%H%M%S", gmtime())  # date/time generation for unique filename
    remotePath = "/tmp/nrg_bitfile_" + ctime + ".bit"  # store in /tmp/
    sftp.put(path, remotePath)  # send to remote machine
    command = "test -f " + remotePath + " ; echo $?"  # tests it arrived ok
    stdin, stdout, stderr = sshConnection.exec_command(command)
    out = stdout.read()
    if out != b'0\n':  # if it didn't arrive ok
        lStatus.config(text="Error - file not successfully sent to remote machine")
        return
    command = "/root/nrg/NetFPGA-SUME-dev/lib/sw/std/apps/sume_riffa_v1_0_0/load_image.sh " + remotePath
    stdin, stdout, stderr = sshConnection.exec_command(command)  # flash it
    out = stdout.read()
    print(out)
    if out.find(b'ERROR: Failed to download the bit file') != -1:  # if XMD gives us an error while flashing
        lStatus.config(text="Error - file did not flash successfully")
        return
    lStatus.config(text="File successfully flashed")
    command = "rm " + remotePath  # delete the file we sent from remote machine
    sshConnection.exec_command(command)
    sftp.close()


def sendCommand(lLabel, eCmd, sCmd, sshConnection):
    if eCmd:
        command = eCmd.get()
    elif sCmd:
        command = sCmd
    else:
        return
    stdin, stdout, stderr = sshConnection.exec_command(command)
    out = stdout.read()
    if lLabel:
        lLabel.config(text=out)
    if out != b'':
        print(out)


def readRegister(lLabel, eReg, sshConnection):
    sAddress = '0x' + eReg.get()
    stdin, stdout, stderr = sshConnection.exec_command("./rwaxi -a " + sAddress)
    out = stdout.read()
    print(out)
    lLabel.config(text=out[5:-1])


def writeRegister(reg, val, sshConnection, lLabel=None):
    sReg = '0x' + reg
    sVal = '0x' + val
    stdin, stdout, stderr = sshConnection.exec_command("./rwaxi -a " + sReg + " -w " + sVal)
    out = stdout.read()
    print(out)
    if lLabel is not None:
        ctime = strftime("%H:%M:%S", gmtime())
        lLabel.config(text="Set at " + ctime)


def readRegisterIndirect(lLabel, eReg, eTab, eOff, sshConnection):
    sAddress = '0x' + eReg.get()
    sTable = eTab.get()
    sOffset = eOff.get()
    stdin, stdout, stderr = sshConnection.exec_command(
        "./read_indirect -a " + sAddress + " -t " + sTable + " -o " + sOffset)
    out = stdout.read()
    print(out)
    lLabel.config(text=out)


def writeRegisterIndirect(eReg, eTab, eOff, eVal, lLabel, sshConnection):
    sAddress = '0x' + eReg.get()
    sTable = eTab.get()
    sOffset = eOff.get()
    sVal = eVal.get()
    stdin, stdout, stderr = sshConnection.exec_command(
        "./write_indirect -a " + sAddress + " -t " + sTable + " -o " + sOffset + " -w " + sVal)
    out = stdout.read()
    print(out)
    ctime = strftime("%H:%M:%S", gmtime())
    lLabel.config(text="Set at " + ctime)


def setRate(eBw, eBurst, lLabel, sshConnection):
    sBw = eBw.get()
    sBurst = eBurst.get()
    try:
        bw = float(sBw)
    except ValueError:
        print("Bandwidth must be a positive decimal number less than 10")
        tkinter.messagebox.showerror("Error", "Bandwidth must be a decimal number")
        return
    if bw != 10:
        if bw > 10 or bw <= 0:
            print("Bandwidth must be a positive decimal number less than 10")
            tkinter.messagebox.showerror("Error", "Bandwidth must be a positive decimal number less than 10")
            return
        if sBurst == '':  # no burst size override, so find the most accurate representation possible on NRG
            fraction = Fraction(Decimal(str(200 * 256 / bw))).limit_denominator(100000000)
            iBaseRate = fraction.denominator
            iValidRate = fraction.numerator
        else:
            try:
                burst = int(sBurst)
            except ValueError:
                print("Burst size must be a positive integer")
                tkinter.messagebox.showerror("Error", "Burst size must be a positive integer")
                return
            if burst <= 0:
                print("Burst size must be a positive integer")
                tkinter.messagebox.showerror("Error", "Burst size must be a positive integer")
                return
            elif burst > 1000000000:
                print("Burst size must be a positive integer, and less than 1000000000")
                tkinter.messagebox.showerror("Error",
                                             "Burst size must be a positive integer, and less than 1000000000")
                return
            iBaseRate = round(burst * 200 * 256 / bw)
            iValidRate = burst
            if iBaseRate > 2000000000:
                iBaseRate = 2000000000
    else:  # bandwidth = 10, i.e. full line rate so set both to 0
        iBaseRate = 0
        iValidRate = 0
    hBaseRate = hex(iBaseRate)[2:]
    hValidRate = hex(iValidRate)[2:]
    baseRegister = "4403001c"
    validRegister = "44030020"
    writeRegister(baseRegister, hBaseRate, sshConnection)
    writeRegister(validRegister, hValidRate, sshConnection)
    baseRegister = "4404001c"
    validRegister = "44040020"
    writeRegister(baseRegister, hBaseRate, sshConnection)
    writeRegister(validRegister, hValidRate, sshConnection)
    if bw == 10:
        bandwidth = "10.000000"
    else:
        bandwidth = "%.6f" % (10 * iValidRate / iBaseRate)
    lLabel.config(text="Bandwidth = " + bandwidth + "Gb/s")


def setLatency(eLatency, timeUnit, portSel, jitterType, userDistPath, eJitterVal, lLabel, sshConnection):
    sLatency = eLatency.get()
    if sLatency == '':
        iLatency = 0
    else:
        try:
            iLatency = int(sLatency)
        except ValueError:
            print("Error converting string to integer")
            tkinter.messagebox.showerror("Error", "Latency must be a non-negative integer")
            return
    if iLatency < 0:
        print("Latency must be a non-negative number")
        tkinter.messagebox.showerror("Error", "Latency must be a non-negative integer")
        return
    if timeUnit == 1 and iLatency % 5 != 0:
        tkinter.messagebox.showwarning("Warning",
                                       "Latency should be a multiple of 5ns. Rounding down to nearest 5ns.")
        iLatency = iLatency - (iLatency % 5)
        eLatency.delete(0, END)
        eLatency.insert(0, str(iLatency))

    elif timeUnit * iLatency > 20000000000:
        tkinter.messagebox.showwarning("Warning",
                                       "Latency should not exceed 20s. Setting to 20s.")
        eLatency.delete(0, END)
        eLatency.insert(0, "20")
        iLatency = 20
    latency = hex(int((iLatency / 5) * timeUnit))[2:]
    if portSel == 0:
        latencyRegister = "4401001c"
        jitterValReg = "44010020"
        jitterTypeReg = "44010024"
    else:
        latencyRegister = "4402001c"
        jitterValReg = "44020020"
        jitterTypeReg = "44020024"
    jitterIntToWrite = 0
    if eJitterVal.get() != '':
        try:
            jitterInt = int(eJitterVal.get())
        except ValueError:
            print("Error converting string to integer")
            tkinter.messagebox.showerror("Error", "Jitter value must be a non-negative integer")
            return
        if jitterInt < 0:
            tkinter.messagebox.showerror("Error", "Jitter value can not be negative.")
            return
        elif jitterInt >= 5:
            jitterIntToWrite = round(math.log2(jitterInt / 5))
            if jitterIntToWrite != math.log2(jitterInt / 5):
                tkinter.messagebox.showinfo("Information",
                                            "Jitter value has rounded to nearest supported value: " + str(
                                                (1 << jitterIntToWrite) * 5))
                eJitterVal.delete(0, END)
                eJitterVal.insert(0, str((1 << jitterIntToWrite) * 5))
        elif jitterInt != 0:  # i.e. is between 1 and 4
            tkinter.messagebox.showerror("Error", "Jitter value can not be less than 5ns.")
            return
    writeRegister(latencyRegister, latency, sshConnection)
    writeRegister(jitterValReg, hex(jitterIntToWrite)[2:], sshConnection)
    writeRegister(jitterTypeReg, hex(jitterType)[2:], sshConnection)
    if jitterType == 16:
        sendCommand(None, None, "./write_distribution -a 0x44010000 -t 0x10000000 -f " + userDistPath, sshConnection)
        sendCommand(None, None, "./write_distribution -a 0x44020000 -t 0x10000000 -f " + userDistPath, sshConnection)
    ctime = strftime("%H:%M:%S", gmtime())
    lLabel.config(text="Set at " + ctime)
