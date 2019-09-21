# NRG-100G-alpha

## Architecture
```
      FPGA
     +-------------------------------------------+
     |         +-----------+  +-----------+      |
qsfp0|----+--->|   Delay   |->|   rate    |--+-->|qsfp1
     |    |    |           |  |  limiter  |  |   |
     |    |    +-----------+  +-----------+  |   |       
     |    |                                  |   |
     |    |    +-----------+                 |   |
     |    |    |   stats   |                 |   |
     |    +--->|           |<----------------+   |
     |         +-----------+                     |
     |         +-----------+  +-----------+      | 		
qsfp1|----+--->|   Delay   |->|   rate    |--+-->|qsfp0 		
     |    |    |           |  |  limiter  |  |   |
     |    |    +-----------+  +-----------+  |   | 
     |    |                                  |   |
     |    |    +-----------+                 |   |
     |    |    |   stats   |                 |   |
     |    +--->|           |<----------------+   |
     |         +-----------+                     |
     +-------------------------------------------+

```

### Supported Boards
 - Xilinx VCU1525

### What is Required?
 - Ubuntu 18.04 LTS
 - Xilinx Vivado 2019.1.2

### How to Build
1) Prepare
```
$ git clone git@anonymous:anonymous/NRG-100G-alpha.git
$ cd NRG-100G-alpha.git
$ source /opt/Xilinx/Vivado/2019.1/settings64.sh
$ source settings.sh
```

2) To make IP cores, please make all of cores.
```
$ make
```
3) To make a bitfile, please use the command below.
```
$ make -C $NF_DESIGN_DIR/hw project
```
 
### To Access Registers on Hardware

1) Prepare
```
$ git clone https://github.com/Xilinx/dma_ip_drivers.git
$ cd dma_ip_drivers/QDMA/linux-kernel/
$ sudo apt install libaio-dev
$ make
$ sudo make install

# modprobe qdma mode=0x012222
```

2) Access the registers
```
# cd dma_ip_drivers/QDMA/linux-kernel/build
# ./dmactl dev list
qdma02000	0000:02:00.0	max QP: 0, -~-
qdma02001	0000:02:00.1	max QP: 0, -~-
qdma02002	0000:02:00.2	max QP: 0, -~-
qdma02003	0000:02:00.3	max QP: 0, -~-
# ./dmactl qdma02000 reg read bar 2 0x00000
qdma02000, 02:00.00, bar#2, 0x0 = 0xde00.
```
```
# ./dmactl qdma02000 reg write bar 2 0x00000010 0x1235
```
