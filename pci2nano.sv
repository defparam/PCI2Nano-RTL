//============================================================================
//  PCI2Nano - Top Level Wrapper
//  Copyright (C) 2020 Evan Custodio
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================ 

module pci2nano (
    //////////// CLOCK //////////
    input                       CLOCK_50,

    //////////// LED //////////
    output      reg     [7:0]   LED,

    //////////// KEY //////////
    input            [1:0]      KEY,

    //////////// SW //////////
    input            [3:0]      SW,

    //////////// SDRAM //////////
    output          [12:0]      DRAM_ADDR,
    output           [1:0]      DRAM_BA,
    output                      DRAM_CAS_N,
    output                      DRAM_CKE,
    output                      DRAM_CLK,
    output                      DRAM_CS_N,
    inout           [15:0]      DRAM_DQ,
    output           [1:0]      DRAM_DQM,
    output                      DRAM_RAS_N,
    output                      DRAM_WE_N,

    //////////// EPCS //////////
    output                      EPCS_ASDO,
    input                       EPCS_DATA0,
    output                      EPCS_DCLK,
    output                      EPCS_NCSO,

    //////////// EEPROM //////////
    output                      I2C_SCLK,
    inout                       I2C_SDAT,

    //////////// 2x13 GPIO Header //////////
    inout           [12:0]      GPIO_2,
    input            [2:0]      GPIO_2_IN,

    //////////// PCI ////////////
    inout           [31:0]      AD,
    inout            [3:0]      CBEn,
    input                       PCI_CLK, // 66 or 33 MHz
    input                       PCI_RSTn,
    inout                       REQn,
    input                       GNTn,
    output                      INTDn,
    output                      INTCn,
    output                      INTBn,
    output                      INTAn,
    inout                       IDSEL,
    inout                       IRDYn,
    inout                       DEVSELn,
    inout                       FRAMEn,
    inout                       LOCKn,
    inout                       TRDYn,
    inout                       PERRn,
    inout                       STOPn,
    inout                       SERRn,
    inout                       PAR,
    output                      M66EN
);

assign M66EN = 1; // Enable 66 MHz clocking

wire          down_config_read;
wire          down_config_write;
wire [3:0]    down_config_CBEn;
wire [1:0]    down_config_type;
wire [5:0]    down_config_dwnum;
wire [2:0]    down_config_func;
wire [4:0]    down_config_dev;
wire [7:0]    down_config_bus;
wire [31:0]   down_config_writedata;
wire [31:0]   down_config_readdata;
wire          down_config_readdatavalid; 
wire          down_mem_read;
wire          down_mem_write;
wire [3:0]    down_mem_CBEn;
wire [63:0]   down_mem_addr;
wire [31:0]   down_mem_writedata;
wire [31:0]   down_mem_readdata;
wire          down_mem_readdatavalid;
wire          down_io_read;
wire          down_io_write;
wire [3:0]    down_io_CBEn;
wire [31:0]   down_io_addr;
wire [31:0]   down_io_writedata;
wire [31:0]   down_io_readdata;
wire          down_io_readdatavalid;

pcicore u1(
	.AD                         (AD),                         //inout [31:0]   
	.CBEn                       (CBEn),                       //inout [3:0]    
	.PCI_CLK                    (PCI_CLK),                    //input          
    .PCI_RSTn                   (PCI_RSTn),                   //input          
    .REQn                       (REQn),                       //inout          
    .GNTn                       (GNTn),                       //input          
    .INTDn                      (INTDn),                      //output         
    .INTCn                      (INTCn),                      //output         
    .INTBn                      (INTBn),                      //output         
    .INTAn                      (INTAn),                      //output         
    .IDSEL                      (IDSEL),                      //inout          
    .IRDYn                      (IRDYn),                      //inout          
    .DEVSELn                    (DEVSELn),                    //inout          
    .FRAMEn                     (FRAMEn),                     //inout          
    .LOCKn                      (LOCKn),                      //inout          
    .TRDYn                      (TRDYn),                      //inout          
    .PERRn                      (PERRn),                      //inout          
    .STOPn                      (STOPn),                      //inout          
    .SERRn                      (SERRn),                      //inout          
    .PAR                        (PAR),                        //inout   
	
	// Configuration Space Interface (Host to Device)
	.down_config_read           (down_config_read),           //output reg        
	.down_config_write          (down_config_write),          //output reg        
	.down_config_CBEn           (down_config_CBEn),           //output reg [3:0]  
	.down_config_type           (down_config_type),           //output reg [1:0]  
	.down_config_dwnum          (down_config_dwnum),          //output reg [5:0]  
	.down_config_func           (down_config_func),           //output reg [2:0]  
	.down_config_dev            (down_config_dev),            //output reg [4:0]  
	.down_config_bus            (down_config_bus),            //output reg [7:0]  
	.down_config_writedata      (down_config_writedata),      //output reg [31:0] 
	.down_config_readdata       (down_config_readdata),       //input      [31:0] 
	.down_config_readdatavalid  (down_config_readdatavalid),  //input             
	
	// Memory Space Interface (Host to Device)
	.down_mem_read              (down_mem_read),              //output reg        
	.down_mem_write             (down_mem_write),             //output reg        
	.down_mem_CBEn              (down_mem_CBEn),              //output reg [3:0]  
	.down_mem_addr              (down_mem_addr),              //output reg [63:0] 
	.down_mem_writedata         (down_mem_writedata),         //output reg [31:0] 
	.down_mem_readdata          (down_mem_readdata),          //input      [31:0] 
	.down_mem_readdatavalid     (down_mem_readdatavalid),     //input             
	
	// IO Space Interface (Host to Device)
	.down_io_read               (down_io_read),               //output reg        
	.down_io_write              (down_io_write),              //output reg        
	.down_io_CBEn               (down_io_CBEn),               //output reg [3:0]  
	.down_io_addr               (down_io_addr),               //output reg [31:0] 
	.down_io_writedata          (down_io_writedata),          //output reg [31:0] 
	.down_io_readdata           (down_io_readdata),           //input      [31:0] 
	.down_io_readdatavalid      (down_io_readdatavalid)       //input
	
);

wire [7:0] txd;
reg  [7:0] rxd;
reg txfifo_rd;
reg rxfifo_wr;
wire txfifo_empty;
wire txfifo_full;
wire rxfifo_empty;
wire rxfifo_full;

uart u2 (
	// Clock and Reset
	.PCI_CLK                    (PCI_CLK),                    //input          
    .PCI_RSTn                   (PCI_RSTn),                   //input     
	// UART Configuration Space
	.down_config_read           (down_config_read),           
	.down_config_write          (down_config_write),          
	.down_config_CBEn           (down_config_CBEn),           
	.down_config_type           (down_config_type),           
	.down_config_dwnum          (down_config_dwnum),          
	.down_config_func           (down_config_func),           
	.down_config_dev            (down_config_dev),            
	.down_config_bus            (down_config_bus),            
	.down_config_writedata      (down_config_writedata),      
	.down_config_readdata       (down_config_readdata),       
	.down_config_readdatavalid  (down_config_readdatavalid),  
	// UART IO Space Interface
	.down_io_read               (down_io_read),        
	.down_io_write              (down_io_write),       
	.down_io_CBEn               (down_io_CBEn),        
	.down_io_addr               (down_io_addr),        
	.down_io_writedata          (down_io_writedata),   
	.down_io_readdata           (down_io_readdata),    
	.down_io_readdatavalid      (down_io_readdatavalid),
	
	// UART Transmit to the Nios (or any other FIFO-interface target)
	.txfifo_data(txd),
	.txfifo_rd(txfifo_rd),
	.txfifo_empty(txfifo_empty),
	.txfifo_full(txfifo_full),
	
	// UART Transmit from the Nios (or any other FIFO-interface target)
	.rxfifo_data(rxd),
	.rxfifo_wr(rxfifo_wr),
	.rxfifo_empty(rxfifo_empty),
	.rxfifo_full(rxfifo_full)
	
);

reg  [31:0] pci_uart_readdata;
reg         pci_uart_readdatavalid;
wire [31:0] pci_uart_writedata;
wire  [3:0] pci_uart_address;
wire        pci_uart_write;
wire        pci_uart_read;

nios cpu(
		.clk_50_clk(CLOCK_50),                           //   input  wire        
		.reset_reset_n(PCI_RSTn),                        //   input  wire        
		.pci_uart_waitrequest(0),                        //   input  wire        
		.pci_uart_readdata(pci_uart_readdata),           //   input  wire [31:0] 
		.pci_uart_readdatavalid(pci_uart_readdatavalid), //   input  wire        
		.pci_uart_burstcount(),                          //   output wire [0:0]  
		.pci_uart_writedata(pci_uart_writedata),         //   output wire [31:0] 
		.pci_uart_address(pci_uart_address),             //   output wire [3:0]  
		.pci_uart_write(pci_uart_write),                 //   output wire        
		.pci_uart_read(pci_uart_read),                   //   output wire        
		.pci_uart_byteenable(),                          //   output wire [3:0]  
		.pci_uart_debugaccess(),                         //   output wire        
		.pci_uart_clock_clk(PCI_CLK),                    //   input  wire        
		.pci_uart_reset_reset(~PCI_RSTn)                 //   input  wire        
	);
	
// This logic is used to stitch the UART Core to the Nios
always @(posedge PCI_CLK or negedge PCI_RSTn) begin
	if (PCI_RSTn == 1'b0) begin
		pci_uart_readdata <= 32'b0;
		pci_uart_readdatavalid <= 1'b0;
        rxd <= 8'h0;
        txfifo_rd <= 1'b0;
        rxfifo_wr <= 1'b0;
	end
	else begin
		pci_uart_readdatavalid <= pci_uart_read;
		txfifo_rd <= 1'b0;
        rxfifo_wr <= 1'b0;
		
		if (pci_uart_read) begin
			pci_uart_readdata <= 32'b0;
			if (pci_uart_address == 4'h0) begin
				pci_uart_readdata[0] <= txfifo_empty;
				pci_uart_readdata[1] <= txfifo_full;
				pci_uart_readdata[2] <= rxfifo_empty;
				pci_uart_readdata[3] <= rxfifo_full;
			end
			if (pci_uart_address == 4'h4) begin
				pci_uart_readdata[7:0] <= txd;
				txfifo_rd <= 1'b1;
			end
		end
		
		if (pci_uart_write) begin
			if (pci_uart_address == 4'h4) begin
				rxd <= pci_uart_writedata[7:0];
				rxfifo_wr <= 1'b1;
			end		
		end
	end
end


// Return 0s for mem space accesses
reg down_mem_readdatavalid_q;
assign down_mem_readdatavalid = down_mem_readdatavalid_q;
assign down_mem_readdata = 32'h0;
always @(posedge PCI_CLK) down_mem_readdatavalid_q <= down_mem_read;

// Heartbeat LED off of the 66MHz clock
reg [27:0] count;
always @(posedge PCI_CLK) begin
	begin
		count <= count + 1;
		if (count >= 28'h3EF1480) begin
			count <= 0;
			LED <= {8{~LED[0]}};
		end
	end
end


endmodule