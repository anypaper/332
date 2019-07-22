/*
 * 
 *
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

#define PKTSIZE_BASE                    0x0
#define IPG_BASE                        0x10000000
#define BURST_BASE			0x20000000
#define BW_BASE				0x30000000
#define BW_TS_BASE			0x40000000
#define PPS_BASE			0x50000000
#define FLOW_ID_BASE                    0x60000000
#define WINDOW_BASE                     0x70000000


static void
usage(const char *progname)
{

	printf("Usage: %s -a <base address> [-i <iface>]\n",
	    progname);
	_exit(1);
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


//Note: double factor takes the following values:
// 0 - maintain the original address value
// 1 - multiply by 1000 for every 1K entries
// any other value - multiply by the value (e.g. if the double_factor=16, all the address values will be printed *16)

static void read_table(uint32_t base, uint32_t table_base, int entries, int fd, char *ifnam, char *filename,int double_factor)
{

   FILE *f;
   int i;
   uint32_t value;

   f=fopen(filename,"w");
   for (i=0;i<entries;i++) {
      value=read_indirect(base, table_base+i, fd, ifnam);
      if (double_factor==1)
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
  	  if (double_factor==0) {
          	   fprintf(f,"%d,0x%08x,%u\n",i,value, value);
          }
          else
		   fprintf(f,"%d,0x%08x,%u\n",i*double_factor,value, value);	
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

        read_table(addr, IPG_BASE, 4096, fd, ifnam, "ipg.log",1);	
        read_table(addr, PKTSIZE_BASE, 2048, fd, ifnam, "pktsize.log",0);
	read_table(addr, BURST_BASE, 4096, fd, ifnam, "burstsize.log",0);
        read_table(addr, BW_BASE, 4096, fd, ifnam, "bw.log",0);
	read_table(addr, BW_TS_BASE, 4096, fd, ifnam, "bw_ts.log",0);
	read_table(addr, PPS_BASE, 4096, fd, ifnam, "pps_ts.log",0);
        read_table(addr, WINDOW_BASE, 4096, fd, ifnam, "window_size.log",16);

	close(fd);
	return (0);
}

/* end */
