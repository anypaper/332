# This document demonstrates an example parser for a custom experiment
# Custom parse scripts must generate a file named "custom_results_parsed.log"
# The structure of the generated log file must be as follows:
# Line 1 contains the int/float that represents the measured metric
# Line 2 contains a string for the y-axis of the generated graph
# Ensure you are reading from and writing to the current working directory

# This file parses iPerf results
# Custom experiment settings:
# Server: "iperf -s"
# Client: "iperf -c <ip> -y c"

# PARSE VALUE
fh = open("custom_results.log", "r")  # opens the generated output from the experiment
line = fh.readline()
bits = int(line[line.rfind(",") + 1:])
fh.close()

# CREATE METRIC AND Y-AXIS LABEL
mbits = bits / 1000000  # mbits contains the measured metric as a float
ylab = "Throughput (Mbits/s)"  # this is the label we would like our y-axis to have

# SAVE TO "custom_results_parsed.log"
fh = open("custom_results_parsed.log", "w+")  # create the log file
fh.write(str(mbits) + "\n")  # first line contains the metric
fh.write(ylab)  # second line contains the y-axis label
fh.close()
