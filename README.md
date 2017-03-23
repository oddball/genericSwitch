genericSwitch
-------------
 * genericSwitch is the concept of a L2 ASIC/FPGA switch.
 * It has a generic number of ports.
 * It has a generic size of buffer memory.
 * It can be modified to have any speed of the ports i.e 100Mbit/1Gbit/10Gbit etc.
 * It utilizes the concept of a "Ping Pong Buffer" described in [Doubling Memory Bandwidth for Network Buffers](http://yuba.stanford.edu/~nickm/papers/Infocom98_pingpong.pdf) , although indenpendently invented.

It is has low verification quality, mainly used to have a look at if the parameter feature of SystemVerilog was enough to design a generic semiconductor switch.







