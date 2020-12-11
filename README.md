# PCI2Nano-RTL - "Make PCI cool again!"

<p align="center">
<img src="https://github.com/defparam/PCI2Nano-PCB/raw/main/images/banner.png" width="800" >
</p>

Welcome to the PCI2Nano-RTL repo. In this repo you'll find a bunch of design files which target the PCI2Nano Reference Platform found here: https://github.com/defparam/PCI2Nano-PCB. These design files come with a verilog implementation of a PCI core, a 8250-Compatible PCI-based UART core and Nios II example design driving the UART.

# Demo
<p align="center">
<img src="https://github.com/defparam/PCI2Nano-PCB/raw/main/images/pci2nano.gif" width="1000" >
</p>

# What is this?
This is a turnkey set of open source design files and reference information for anyone to be able to start tinkering with PCI/PCIe on low end FPGAs. If you have a desire to interface to a host which supports PCIe and would like a quick way to design PCI functions which interface to the host, this project may be for you!

# Why?
With Gen4/5/6 of PCIe in the works the PCIe protocol is becoming more complex, difficult and expensive for tinkerers to tinker. The great news about PCIe is that it is completely backwards compatible with PCI. Why target PCI? PCI is a wide bus protocol which supports 3.3v GPIO and does not require any special hard silicon from an FPGA. This means that the PCI core in this repo can be ported to any FPGA! (More imporantly it can be ported to low cost FPGA/CPLDs). The heavy lifting translating from PCI to PCIe is done using a PCIe-to-PCI bridge chip (our reference uses a pericom chip). Also, because we are using low end simple FPGAs/CPLDs, our compile times to build PCI functions become minutes/seconds. This gives a great platform to design PCI functions, iterate and test them in a matter of minutes.

# Where to start?
Go over to the reference platform repo: https://github.com/defparam/PCI2Nano-PCB and build out your own reference platform. Come back to this repo and using the free version of Quartus 13.1 compile this design as is. Or simply open the programmer and load in the bitstream SOF file found in this repo directly to your DE0-Nano.

<p align="center">
<img src="https://raw.githubusercontent.com/defparam/PCI2Nano/main/images/image6.jpg" width="550">
</p>

# Technical Information
## PCI Core
The PCI Core is not a finished design. It currently supports downstream memory writes/reads, downstream configuration writes/read and downstream IO writes and reads. The PCI core still requires upstream memory writes/reads to be added and also various fixes and tweaks. This functionality will be added in the future
## PCI Core Interfaces
On the host facing side of the PCI core is the actual PCI bus implementation. Refer to the PCI Express Base Specification, Revision 1.1 for information on how the PCI local bus operates.

On the device facing side of the PCI core are very simple 32-bit data bus protocol interfaces. There are interfaces for Config, Memory and IO. Refer to the UART function for an example of how to interface to these interfaces. (In the future as I clean up the PCI core i'll have better documentation on how these interfaces work).

## 8250-Compitable PCI UART Function
To get our feet wet with PCI and the PCI core in general, I have implemented a PCI UART function to add a serial bus communication layer from the FPGA to the x86 host. This function identifies as a standard serial port in linux. The standard upstream linux drivers are able to interface with this UART core to be able to send byte streams to/from the host. In this specific example the project sends bytestreams to/from a Nios processor to the x86 host.

# Enjoy!
Have fun tinkering with PCI. I'm happy to take any pull requests and suggestions.

Best,

Evan
