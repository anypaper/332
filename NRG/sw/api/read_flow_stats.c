/*
 * This software was developed by
 * Stanford University and the University of Cambridge Computer Laboratory
 * under National Science Foundation under Grant No. CNS-0855268,
 * the University of Cambridge Computer Laboratory under EPSRC INTERNET Project EP/H040536/1 and
 * by the University of Cambridge Computer Laboratory under DARPA/AFRL contract FA8750-11-C-0249 ("MRC2"), 
 * as part of the DARPA MRC research programme.
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


#define INDIRECT_ADDR                   0x100
#define INDIRECT_WR_DATA                0x104
#define INDIRECT_CMD                    0x10C
#define INDIRECT_CFG                    0x110
#define INDIRECT_REPLY                  0x108

#define FLOWID_BASE			0x50000000

//List of flow statistics registers

#define ARPCOUNT_ADDR 0x40
#define IP4COUNT_ADDR 0x44
#define IP6COUNT_ADDR 0x48
#define TCPCOUNT_ADDR 0x4C
#define UDPCOUNT_ADDR 0x50
#define SYNCOUNT_ADDR 0x54
#define FINCOUNT_ADDR 0x58
#define FLOWIDCOUNT_ADDR 0x5C
#define MATCHCOUNT_ADDR 0xE0


static void
usage(const char *progname)
{

	printf("Usage: %s -a <base address> [-i <iface>]\n",
	    progname);
	_exit(1);
}


uint32_t read_reg(uint32_t base, uint32_t addr, int fd, char *ifnam)
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

	sifr.addr = base+addr;
	req = SUME_IOCTL_CMD_READ_REG;
	ifr.ifr_data = (char *)&sifr;	
	rc = ioctl(fd, req, &ifr);
	if (rc == -1)
		err(1, "ioctl");
        return(sifr.val);
}

uint32_t read_indirect(uint32_t base, uint32_t addr, int fd, char *ifnam)
{

	struct sume_ifreq sifr;
	struct ifreq ifr;
	size_t ifnamlen;
	uint32_t value;
	int rc, req;
	
	ifnamlen = strlen(ifnam);
        memset(&sifr, 0, sizeof(sifr));
	memset(&ifr, 0, sizeof(ifr));
	if (ifnamlen >= sizeof(ifr.ifr_name))
		errx(1, "Interface name too long");
	memcpy(ifr.ifr_name, ifnam, ifnamlen);
	ifr.ifr_name[ifnamlen] = '\0';


        //First, write address
	value = addr;
	sifr.addr = base+INDIRECT_ADDR;
	sifr.val = value;
	req = SUME_IOCTL_CMD_WRITE_REG;
	ifr.ifr_data = (char *)&sifr;	
	rc = ioctl(fd, req, &ifr);
	if (rc == -1)
		err(1, "ioctl");

       //Now, write command
	sifr.addr = base+INDIRECT_CMD;
	sifr.val = 0x10;
	req = SUME_IOCTL_CMD_WRITE_REG;
	ifr.ifr_data = (char *)&sifr;	
	rc = ioctl(fd, req, &ifr);
	if (rc == -1)
		err(1, "ioctl");

      //Trigger command
	sifr.addr = base+INDIRECT_CMD;
	sifr.val = 0x11;
	req = SUME_IOCTL_CMD_WRITE_REG;
	ifr.ifr_data = (char *)&sifr;	
	rc = ioctl(fd, req, &ifr);
	if (rc == -1)
		err(1, "ioctl");

	//Check if the command is done
	sifr.addr = base+INDIRECT_CMD;
	req = SUME_IOCTL_CMD_READ_REG;
	ifr.ifr_data = (char *)&sifr;	
	rc = ioctl(fd, req, &ifr);
	if (rc == -1)
		err(1, "ioctl");

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

	//Read Reply
	sifr.addr = base+INDIRECT_REPLY;
	req = SUME_IOCTL_CMD_READ_REG;
	ifr.ifr_data = (char *)&sifr;	
	rc = ioctl(fd, req, &ifr);
	if (rc == -1)
		err(1, "ioctl");

        //printf("Reply value 0x%08x\n",sifr.val);
	return(sifr.val);

}



static void read_table(uint32_t base, uint32_t table_base, int entries, int fd, char *ifnam, char *filename,int double_by_1000)
{

   FILE *f;
   int i;
   uint32_t value;

   f=fopen(filename,"w");
   for (i=0;i<entries;i++) {
      value=read_indirect(base, table_base+i, fd, ifnam);
      if (double_by_1000)
	{ 
	   if (i<1024)
		fprintf(f,"%d,0x%08x,%u\n",i,value,value);
	   else
	        if (i<2048)
		    fprintf(f,"%d,0x%08x,%u\n",(i-1024)*1024,value,value);
		else
		    fprintf(f,"%d,0x%08x,%u\n",(i-2048)*1024*1024,value,value);
	}
      else
           fprintf(f,"%d,0x%08x,%u\n",i,value, value);
   }
   fclose(f);

}

int
main(int argc, char *argv[])
{
	char *ifnam;
	//struct sume_ifreq sifr;
	//struct ifreq ifr;
	//size_t ifnamlen;
	unsigned long l;
	uint32_t addr;//, value;
	int fd, flags, rc;
	FILE *f;
   	uint32_t value;

	flags = 0x00;
	addr = SUME_DEFAULT_TEST_ADDR;
	ifnam = SUME_IFNAM_DEFAULT;
	//req = SUME_IOCTL_CMD_READ_REG;
	//value = 0;
	while ((rc = getopt(argc, argv, "+a:hi:w:")) != -1) {
		switch (rc) {
		case 'a':
			l = strtoul(optarg, NULL, 0);
			if (l == ULONG_MAX || l > UINT32_MAX)
				errx(1, "Invalid address");
			addr = (uint32_t)l;
			flags |= HAVE_ADDR;
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

   	f=fopen("flow_stats.log","w");



        value=read_reg(addr, ARPCOUNT_ADDR, fd, ifnam);
      	fprintf(f,"ARP Messages Count: 0x%08x,%u\n",value,value);

        value=read_reg(addr, IP4COUNT_ADDR, fd, ifnam);
      	fprintf(f,"IPv4 Messages Count: 0x%08x,%u\n",value,value);

        value=read_reg(addr, IP6COUNT_ADDR, fd, ifnam);
      	fprintf(f,"IPv6 Messages Count: 0x%08x,%u\n",value,value);

        value=read_reg(addr, TCPCOUNT_ADDR, fd, ifnam);
      	fprintf(f,"TCP Messages Count: 0x%08x,%u\n",value,value);

        value=read_reg(addr, UDPCOUNT_ADDR, fd, ifnam);
      	fprintf(f,"UDP Messages Count: 0x%08x,%u\n",value,value);

        value=read_reg(addr, SYNCOUNT_ADDR, fd, ifnam);
      	fprintf(f,"SYN Messages Count: 0x%08x,%u\n",value,value);

        value=read_reg(addr, FINCOUNT_ADDR, fd, ifnam);
      	fprintf(f,"FIN Messages Count: 0x%08x,%u\n",value,value);

        value=read_reg(addr, FLOWIDCOUNT_ADDR, fd, ifnam);
      	fprintf(f,"Distinct Flow ID Count: 0x%08x,%u\n",value,value);

        value=read_reg(addr, MATCHCOUNT_ADDR, fd, ifnam);
      	fprintf(f,"Pattern Match Messages Count: 0x%08x,%u\n",value,value);


        read_table(addr, FLOWID_BASE, 8192, fd, ifnam, "flowid.log",0);


	close(fd);
	return (0);
}

/* end */
