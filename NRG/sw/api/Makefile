#
# Copyright (c) 2015 Bjoern A. Zeeb
# All rights reserved.
#
#  File:
#        Makefile
#
#	Author:
#	Modified from a code originally written by Bjoern A. Zeeb
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

#all:	rwaxi register_read.sh register_write.sh
all:	rwaxi stats init_stats read_indirect write_indirect read_flow_stats write_distribution

rwaxi:	rwaxi.c ${DRIVER_FOLDER}/nf_sume.h
	cc -Wall -Werror -o rwaxi rwaxi.c \
		-I${DRIVER_FOLDER}

stats:  read_stats.c ${DRIVER_FOLDER}/nf_sume.h
	cc -Wall -Werror -o read_stats read_stats.c \
                -I${DRIVER_FOLDER}

init_stats:  init_stats.c ${DRIVER_FOLDER}/nf_sume.h
	cc -Wall -Werror -o init_stats init_stats.c \
                -I${DRIVER_FOLDER}

read_dist: read_dist.c ${DRIVER_FOLDER}/nf_sume.h
	cc -Wall -Werror -o read_dist read_dist.c \
		-I${DRIVER_FOLDER}

read_indirect:  read_indirect.c ${DRIVER_FOLDER}/nf_sume.h
	cc -Wall -Werror -o read_indirect read_indirect.c \
                -I${DRIVER_FOLDER}

write_indirect:  write_indirect.c ${DRIVER_FOLDER}/nf_sume.h
	cc -Wall -Werror -o write_indirect write_indirect.c \
                -I${DRIVER_FOLDER}

write_distribution:  write_distribution.c ${DRIVER_FOLDER}/nf_sume.h
	cc -Wall -Werror -o write_distribution write_distribution.c \
                -I${DRIVER_FOLDER}


read_flow_stats:  read_flow_stats.c ${DRIVER_FOLDER}/nf_sume.h
	cc -Wall -Werror -o read_flow_stats read_flow_stats.c \
                -I${DRIVER_FOLDER}

register_read.sh:	generate_register_read.sh ${NF_DESIGN_DIR}/sw/embedded/src/sume_register_defines.h
	sh generate_register_read.sh

register_write.sh:	generate_register_read.sh ${NF_DESIGN_DIR}/sw/embedded/src/sume_register_defines.h
	sh generate_register_write.sh

clean:
	rm -f rwaxi register_read.sh register_write.sh read_stats init_stats read_indirect write_indirect read_flow_stats *.log *.c~ Makefile~

# end
