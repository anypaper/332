/*
 * 
 *
 * @NETFPGA_LICENSE_HEADER_START@
 *
 * Licensed to NetFPGA C.I.C. (NetFPGA) under one or more contributor
 * license agreements.  See the NOTICE file distributed with this work for
 * additional information regarding copyright ownership.  NetFPGA licenses this
 * file to you under the NetFPGA Hardware-Software License, Version 1.0 (the
 * "License"); you may not use this file except in compliance with the
 * License.  You may obtain a copy of the License at:
 *
 *   http://www.netfpga-cic.org
 *
 * Unless required by applicable law or agreed to in writing, Work distributed
 * under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * @NETFPGA_LICENSE_HEADER_END@
 *
*/

#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <net/if.h>

#include <err.h>
#include <fcntl.h>
#include <limits.h>
#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "nf_sume.h"

#define	SUME_DEFAULT_TEST_ADDR		0x44050000

#define	HAVE_ADDR			0x01
#define	HAVE_VALUE			0x02
#define	HAVE_IFACE			0x04


#define INDIRECT_ADDR                   0x50
#define INDIRECT_WR_DATA                0x54
#define INDIRECT_CMD                    0x5C
#define INDIRECT_CFG                    0x60
#define INDIRECT_REPLY                  0x58


static void
usage(const char *progname)
{

	printf("Usage: %s -a <base address> -t <table base> -o <table offset> [-i <iface>]\n",
	    progname);
	_exit(1);
}


void write_indirect(uint32_t base, uint32_t addr, uint32_t value, int fd, char *ifnam)
{

	struct sume_ifreq sifr;
	struct ifreq ifr;
	size_t ifnamlen;
	int rc, req;
	
	ifnamlen = strlen(ifnam);
        memset(&sifr, 0, sizeof(sifr));
	memset(&ifr, 0, sizeof(ifr));
	if (ifnamlen >= sizeof(ifr.ifr_name))
		errx(1, "Interface name too long");
	memcpy(ifr.ifr_name, ifnam, ifnamlen);
	ifr.ifr_name[ifnamlen] = '\0';


        //First, write address
	sifr.addr = base+INDIRECT_ADDR;
	sifr.val = addr;
	req = SUME_IOCTL_CMD_WRITE_REG;
	ifr.ifr_data = (char *)&sifr;	
	rc = ioctl(fd, req, &ifr);
	if (rc == -1)
		err(1, "ioctl");
	//printf("write addr, addr 0x%08x val 0x%08x\n",sifr.addr,sifr.val);

        //next, write data
	sifr.addr = base+INDIRECT_WR_DATA;
	sifr.val = value;
	req = SUME_IOCTL_CMD_WRITE_REG;
	ifr.ifr_data = (char *)&sifr;	
	rc = ioctl(fd, req, &ifr);
	if (rc == -1)
		err(1, "ioctl");
	//printf("write data, addr 0x%08x val 0x%08x\n",sifr.addr,sifr.val);

       //Configure the command
	sifr.addr = base+INDIRECT_CFG;
	sifr.val = 0x000000061;
	req = SUME_IOCTL_CMD_WRITE_REG;
	ifr.ifr_data = (char *)&sifr;	
	rc = ioctl(fd, req, &ifr);
	if (rc == -1)
		err(1, "ioctl");
	//printf("config command, addr 0x%08x val 0x%08x\n",sifr.addr,sifr.val);

       //Now, write command
	sifr.addr = base+INDIRECT_CMD;
	sifr.val = 0x00;
	req = SUME_IOCTL_CMD_WRITE_REG;
	ifr.ifr_data = (char *)&sifr;	
	rc = ioctl(fd, req, &ifr);
	if (rc == -1)
		err(1, "ioctl");
	//printf("write command, addr 0x%08x val 0x%08x\n",sifr.addr,sifr.val);

      //Trigger command
	sifr.addr = base+INDIRECT_CMD;
	sifr.val = 0x01;
	req = SUME_IOCTL_CMD_WRITE_REG;
	ifr.ifr_data = (char *)&sifr;	
	rc = ioctl(fd, req, &ifr);
	if (rc == -1)
		err(1, "ioctl");
	//printf("trigger command, addr 0x%08x val 0x%08x\n",sifr.addr,sifr.val);

	//Check if the command is done
	sifr.addr = base+INDIRECT_CMD;
	req = SUME_IOCTL_CMD_READ_REG;
	ifr.ifr_data = (char *)&sifr;	
	rc = ioctl(fd, req, &ifr);
	if (rc == -1)
		err(1, "ioctl");
	//printf("trigger status, addr 0x%08x val 0x%08x\n",sifr.addr,sifr.val);

	//printf("Trigger status 0x%08x\n",sifr.val);
        int i=0;
	while ((sifr.val<4) && (i<5))
	{
		i++;
		rc = ioctl(fd, req, &ifr);
	        if (rc == -1)
		    err(1, "ioctl");
	}
        if (i==5)
		    err(1,"indirect");


}


int
main(int argc, char *argv[])
{
	char *ifnam;
	//struct sume_ifreq sifr;
	//struct ifreq ifr;
	//size_t ifnamlen;
	unsigned long l;
	uint32_t addr, value,offset,table;
	int fd, flags, rc;

	flags = 0x00;
	addr = SUME_DEFAULT_TEST_ADDR;
	ifnam = SUME_IFNAM_DEFAULT;
	value=0;
	//req = SUME_IOCTL_CMD_READ_REG;
	//value = 0;
	while ((rc = getopt(argc, argv, "+a:o:t:hi:w:")) != -1) {
		switch (rc) {
		case 'a':
			l = strtoul(optarg, NULL, 0);
			if (l == ULONG_MAX || l > UINT32_MAX)
				errx(1, "Invalid address");
			addr = (uint32_t)l;
			flags |= HAVE_ADDR;
			break;
		case 'w':
			l = strtoul(optarg, NULL, 0);
			if (l == ULONG_MAX || l > UINT32_MAX)
				errx(1, "Invalid value");
			value = (uint32_t)l;
			break;
		case 'o':
			l = strtoul(optarg, NULL, 0);
			if (l == ULONG_MAX || l > UINT32_MAX)
				errx(1, "Invalid offset");
			offset = (uint32_t)l;
			break;
		case 't':
			l = strtoul(optarg, NULL, 0);
			if (l == ULONG_MAX || l > UINT32_MAX)
				errx(1, "Invalid table base");
			table = (uint32_t)l;
			break;
		case 'i':
			ifnam = optarg;
			flags |= HAVE_IFACE;
			break;
		case 'h':
		case '?':
		default:
			usage(argv[0]);
			/* NOT REACHED */
		}
	}

	//ifnamlen = strlen(ifnam);

	if ((flags & HAVE_ADDR) == 0)
		fprintf(stderr, "WARNING: using default test address 0x%08x\n",
		    addr);

	fd = socket(AF_INET6, SOCK_DGRAM, 0);
	if (fd == -1) {
		fd = socket(AF_INET, SOCK_DGRAM, 0);
		if (fd == -1)
			err(1, "socket failed for AF_INET6 and AF_INET");
	}

	//printf("addr 0x%08x table 0x%08x offset 0x%08x value 0x%08x\n",addr,table,offset,value);
        write_indirect(addr, table+offset, value, fd, ifnam);
	printf("Reply value 0x%08x\n",value);


	close(fd);
	return (0);
}

/* end */
