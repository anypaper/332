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
################################################################################
#  File:
#        Makefile
#
#  Project:
#        Makes all the cores of NetFPGA library
#
#  Description:
#        This makefile is used to generate and compile SDK project for NetFPGA reference projects.
#        The first argument is target


SCRIPTS_DIR	= tools/
LIB_REPO	= lib/hw/ip_repo
LIB_HW_DIR	= hw/lib
LIB_SW_DIR	= lib/sw
LIB_HW_DIR_INSTANCES := $(shell cd $(LIB_HW_DIR) && find . -maxdepth 4 -type d)
LIB_HW_DIR_INSTANCES := $(basename $(patsubst ./%,%,$(LIB_HW_DIR_INSTANCES)))
LIB_SW_DIR_INSTANCES := $(shell cd $(LIB_SW_DIR) && find . -maxdepth 4 -type d)
LIB_SW_DIR_INSTANCES := $(basename $(patsubst ./%,%,$(LIB_SW_DIR_INSTANCES)))

TOOLS_DIR = tools
TOOLS_DIR_INSTANCES := $(shell cd $(TOOLS_DIR) && find . -maxdepth 3 -type d)
TOOLS_DIR_INSTANCES := $(basename $(patsubst ./%,%,$(TOOLS_DIR_INSTANCES)))

PROJECTS_DIR = projects
PROJECTS_DIR_INSTANCES := $(shell cd $(PROJECTS_DIR) && find . -maxdepth 1 -type d)
PROJECTS_DIR_INSTANCES := $(basename $(patsubst ./%,%,$(PROJECTS_DIR_INSTANCES)))

CONTRIBPROJECTS_DIR = contrib-projects
CONTRIBPROJECTS_DIR_INSTANCES := $(shell cd $(CONTRIBPROJECTS_DIR) && find . -maxdepth 1 -type d)
CONTRIBPROJECTS_DIR_INSTANCES := $(basename $(patsubst ./%,%,$(CONTRIBPROJECTS_DIR_INSTANCES)))

RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
$(eval $(RUN_ARGS):;@:)


all:	clean sume hwtestlib 

clean: libclean toolsclean projectsclean hwtestlibclean swclean
	@rm -rfv *.*~
	@rm -rfv ip_proj
	@rm -rfv ip_user_files
	@find . -type f -name '*.pyc' -delete
	@find . -type f -name '*.jou' -delete
	@find . -type f -name '*.log' -delete
	@find . -type f -name '*.coe' -delete
	@find . -type f -name '*.mif' -delete

sume:
	make -C $(LIB_HW_DIR)/fallthrough_small_fifo_v1_0_0/
	make -C $(LIB_HW_DIR)/axis_fifo_v1_0_0/
	make -C $(LIB_HW_DIR)/nf_axis_converter_v1_0_0/
	make -C $(LIB_HW_DIR)/nf_10ge_attachment_v1_0_0/
	make -C $(LIB_HW_DIR)/delay_v1_0_0/
	make -C $(LIB_HW_DIR)/rate_limiter_v1_0_0/
	make -C $(LIB_HW_DIR)/stats_v1_0_0/
	make -C $(LIB_HW_DIR)/nf_cmac_interface_0_v1_0_0/
	make -C $(LIB_HW_DIR)/nf_cmac_interface_1_v1_0_0/
	make -C $(LIB_HW_DIR)/nf_qdma_v1_0_0/
	@echo "/////////////////////////////////////////";
	@echo "//\tLibrary cores created.";
	@echo "/////////////////////////////////////////";


libclean:
	@rm -rf $(LIB_REPO)
	@for lib in $(LIB_HW_DIR_INSTANCES) ; do \
		if test -f $(LIB_HW_DIR)/$$lib/Makefile; then \
			$(MAKE) -C $(LIB_HW_DIR)/$$lib clean; \
		fi; \
	done;
	@echo "/////////////////////////////////////////";
	@echo "//\tLibrary cores cleaned.";
	@echo "/////////////////////////////////////////";


toolsclean:
	@if test -f $(TOOLS_DIR)/Makefile; then \
		$(MAKE) -C $(TOOLS_DIR) clean; \
	fi;
	@echo "/////////////////////////////////////////";
	@echo "//\tTools cleaned.";
	@echo "/////////////////////////////////////////";


projectsclean:
	@for lib in $(PROJECTS_DIR_INSTANCES) ; do \
		if test -f $(PROJECTS_DIR)/$$lib/Makefile; then \
			$(MAKE) -C $(PROJECTS_DIR)/$$lib/ clean; \
		fi; \
	done;
	@echo "/////////////////////////////////////////";
	@echo "//\tProjects cleaned.";
	@echo "/////////////////////////////////////////";


contribprojectsclean:
	@for lib in $(CONTRIBPROJECTS_DIR_INSTANCES) ; do \
		if test -f $(CONTRIBPROJECTS_DIR)/$$lib/Makefile; then \
			$(MAKE) -C $(CONTRIBPROJECTS_DIR)/$$lib/ clean; \
		fi; \
	done;
	@echo "/////////////////////////////////////////";
	@echo "//\tContrib-projects cleaned.";
	@echo "/////////////////////////////////////////";


contribprojects:
	@for lib in $(CONTRIBPROJECTS_DIR_INSTANCES) ; do \
		if test -f $(CONTRIBPROJECTS_DIR)/$$lib/Makefile; then \
			$(MAKE) -C $(CONTRIBPROJECTS_DIR)/$$lib/; \
		fi; \
	done;
	@echo "/////////////////////////////////////////";
	@echo "//\tContrib-projects created.";
	@echo "/////////////////////////////////////////";


hwtestlib:
	$(MAKE) -C lib/sw/std/hwtestlib
	@echo "/////////////////////////////////////////";
	@echo "//\tHW test Library created.";
	@echo "/////////////////////////////////////////";


hwtestlibclean:
	$(MAKE) -C lib/sw/std/hwtestlib clean
	@echo "/////////////////////////////////////////";
	@echo "//\tHW test Library cleaned.";
	@echo "/////////////////////////////////////////";


swclean:
	@for swlib in $(LIB_SW_DIR_INSTANCES) ; do \
		if test -f $(LIB_SW_DIR)/$$swlib/Makefile; then \
			$(MAKE) -C $(LIB_SW_DIR)/$$swlib clean; \
		fi; \
	done;
	@echo "/////////////////////////////////////////";
	@echo "//\tSW Library cleaned.";
	@echo "/////////////////////////////////////////";

