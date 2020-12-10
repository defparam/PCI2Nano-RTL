//============================================================================
//  PCI2Nano - PCI Core
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


module pcicore (
	inout [31:0]   AD,
	inout [3:0]    CBEn,
	input          PCI_CLK, 
    input          PCI_RSTn,
    inout          REQn,
    input          GNTn,
    output         INTDn,
    output         INTCn,
    output         INTBn,
    output         INTAn,
    inout          IDSEL,
    inout          IRDYn,
    inout          DEVSELn,
    inout          FRAMEn,
    inout          LOCKn,
    inout          TRDYn, 
    inout          PERRn,
    inout          STOPn,
    inout          SERRn, // open drain output
    inout          PAR,
	
	
	// Configuration Space Interface (Host to Device)
	output reg        down_config_read,
	output reg        down_config_write,
	output reg [3:0]  down_config_CBEn,
	output reg [1:0]  down_config_type,
	output reg [5:0]  down_config_dwnum,
	output reg [2:0]  down_config_func,
	output reg [4:0]  down_config_dev,
	output reg [7:0]  down_config_bus,
	output reg [31:0] down_config_writedata,
	input      [31:0] down_config_readdata,
	input             down_config_readdatavalid,
	
	// Memory Space Interface (Host to Device)
	output reg        down_mem_read,
	output reg        down_mem_write,
	output reg [3:0]  down_mem_CBEn,
	output reg [63:0] down_mem_addr,
	output reg [31:0] down_mem_writedata,
	input      [31:0] down_mem_readdata,
	input             down_mem_readdatavalid,
	
	// IO Space Interface (Host to Device)
	output reg        down_io_read,
	output reg        down_io_write,
	output reg [3:0]  down_io_CBEn,
	output reg [31:0] down_io_addr,
	output reg [31:0] down_io_writedata,
	input      [31:0] down_io_readdata,
	input             down_io_readdatavalid
	
);

assign INTAn = 1;
assign INTBn = 1;
assign INTCn = 1;
assign INTDn = 1;

reg [31:0] AD_OUT     ;
reg [3:0]  CBEn_OUT   ;
reg        REQn_OUT   ;
reg        IDSEL_OUT  ;
reg        IRDYn_OUT  ;
reg        DEVSELn_OUT;
reg        FRAMEn_OUT ;
reg        LOCKn_OUT  ;
reg        TRDYn_OUT  ;
reg        PERRn_OUT  ;
reg        STOPn_OUT  ;
reg        SERRn_OUT  ;
reg        PAR_OUT    ;
reg        AD_OE      ;
reg        CBEn_OE    ;
reg        REQn_OE    ;
reg        IDSEL_OE   ;
reg        IRDYn_OE   ;
reg        DEVSELn_OE ;
reg        FRAMEn_OE  ;
reg        LOCKn_OE   ;
reg        TRDYn_OE   ;
reg        PERRn_OE   ;
reg        STOPn_OE   ;
reg        SERRn_OE   ;
reg        PAR_OE     ;  

assign AD      = (AD_OE & PCI_RSTn)      ? AD_OUT      : 32'hZ;
assign CBEn    = (CBEn_OE & PCI_RSTn)    ? CBEn_OUT    : 4'bz;
assign REQn    = (REQn_OE & PCI_RSTn)    ? REQn_OUT    : 1'bz;
assign IDSEL   = (IDSEL_OE & PCI_RSTn)   ? IDSEL_OUT   : 1'bz;
assign IRDYn   = (IRDYn_OE & PCI_RSTn)   ? IRDYn_OUT   : 1'bz;
assign DEVSELn = (DEVSELn_OE & PCI_RSTn) ? DEVSELn_OUT : 1'bz;
assign FRAMEn  = (FRAMEn_OE & PCI_RSTn)  ? FRAMEn_OUT  : 1'bz;
assign LOCKn   = (LOCKn_OE & PCI_RSTn)   ? LOCKn_OUT   : 1'bz;
assign TRDYn   = (TRDYn_OE & PCI_RSTn)   ? TRDYn_OUT   : 1'bz;
assign PERRn   = (PERRn_OE & PCI_RSTn)   ? PERRn_OUT   : 1'bz;
assign STOPn   = (STOPn_OE & PCI_RSTn)   ? STOPn_OUT   : 1'bz;
assign SERRn   = (SERRn_OE & PCI_RSTn)   ? SERRn_OUT   : 1'bz;
assign PAR     = (PAR_OE & PCI_RSTn)     ? PAR_OUT     : 1'bz;

// PCI Commands
`define PCI_CMD_ACK     4'b0000 // Not sure if I should support (research interrupts)
`define PCI_CMD_SPECIAL 4'b0001 // Not sure if I should support
`define PCI_CMD_IOREAD  4'b0010 // DONE
`define PCI_CMD_IOWRITE 4'b0011 // DONE
//`define PCI_CMD_RSVD0   4'b0100  // (reserved)
//`define PCI_CMD_RSVD1   4'b0101  // (reserved)
`define PCI_CMD_MEMRD   4'b0110 // DONE
`define PCI_CMD_MEMWR   4'b0111 // DONE
//`define PCI_CMD_RSVD2   4'b1000  // (reserved)
//`define PCI_CMD_RSVD3   4'b1001  // (reserved)
`define PCI_CMD_CFGRD   4'b1010 // DONE
`define PCI_CMD_CFGWR   4'b1011 // DONE
`define PCI_CMD_RDMUL   4'b1100 // Not sure if I should support
`define PCI_CMD_DAC     4'b1101 // In Progress - 64-bit addressing
`define PCI_CMD_RDLINE  4'b1110 // Not sure if I should support
`define PCI_CMD_WR_I    4'b1111 // Not sure if I should support

reg [3:0] state;
reg [3:0] next_state;

`define ST_IDLE             4'h0
`define ST_READ_TURNAROUND  4'h1
`define ST_WRITE            4'h2
`define ST_READ             4'h3

reg [3:0]  operation;
reg        latch_operation;
reg [63:0] reqAddr;
reg        latch_reqAddr;
reg        advance_dwnum;
reg        advance_addr;
reg        latch_config_readdata;
reg        latch_config_readdatavalid;
reg [31:0] config_readdata;
reg        config_readdatavalid;
reg        latch_mem_readdata;
reg        latch_mem_readdatavalid;
reg [31:0] mem_readdata;
reg        mem_readdatavalid;
reg        latch_io_readdata;
reg        latch_io_readdatavalid;
reg [31:0] io_readdata;
reg        io_readdatavalid;
reg        latch_dac;
reg        clear_dac;
reg [31:0] latch_dac_lowaddr;
reg        dac_operation;

wire [1:0] cfg_type;  assign cfg_type  = AD[1:0];
wire [5:0] cfg_dwnum; assign cfg_dwnum = AD[7:2];
wire [2:0] cfg_func;  assign cfg_func  = AD[10:8];
wire [4:0] cfg_dev;   assign cfg_dev   = AD[15:11];
wire [7:0] cfg_bus;   assign cfg_bus   = AD[23:16];

always_comb begin
	// default signal decodes
	latch_operation       = 0;
	latch_reqAddr         = 0;
	advance_dwnum         = 0;
	advance_addr          = 0;
	latch_config_readdata      = 0; // Save the result from the read
	latch_config_readdatavalid = 0; 
	latch_io_readdata      = 0; // Save the result from the read
	latch_io_readdatavalid = 0; 
	latch_mem_readdata      = 0; // Save the result from the read
	latch_mem_readdatavalid = 0; 
	down_config_read      = 0;
	down_config_write     = 0;
    down_config_type      = cfg_type;
	down_config_dwnum     = cfg_dwnum;
	down_config_func      = cfg_func;
	down_config_dev       = cfg_dev;
	down_config_bus       = cfg_bus;
	down_config_CBEn      = 4'h0;
	down_config_writedata = 32'h0;
	down_mem_read         = 1'h0;
	down_mem_write        = 1'h0;
	down_mem_CBEn         = 4'h0;
	down_mem_addr         = 64'h0;
	down_mem_writedata    = 32'h0;
	down_io_read          = 1'h0;
	down_io_write         = 1'h0;
	down_io_CBEn          = 4'h0;
	down_io_addr          = 32'h0;
	down_io_writedata     = 32'h0;
    AD_OE                 = 0;
    CBEn_OE               = 0;
    REQn_OE               = 1;
    IDSEL_OE              = 0;
    IRDYn_OE              = 0;
    DEVSELn_OE            = 1;
    FRAMEn_OE             = 0;
    LOCKn_OE              = 1;
    TRDYn_OE              = 1;
    PERRn_OE              = 1;
    STOPn_OE              = 1;
    SERRn_OE              = 1;
    PAR_OE                = 1;  
    AD_OUT                = 32'h0;
    CBEn_OUT              = 4'h0;
    REQn_OUT              = 1;
    IDSEL_OUT             = 0;
    IRDYn_OUT             = 1;
    DEVSELn_OUT           = 1;
    FRAMEn_OUT            = 1;
    LOCKn_OUT             = 1;
    TRDYn_OUT             = 1;
    PERRn_OUT             = 1;
    STOPn_OUT             = 1;
    SERRn_OUT             = 1;
    PAR_OUT               = 0;
	latch_dac             = 0;
	clear_dac             = 0;
	next_state            = `ST_IDLE;

	// state outputs
	case (state)
	// --------------------------------------- //
	// --------------- ST_IDLE --------------- //
	// --------------------------------------- //
	`ST_IDLE: begin
		next_state = `ST_IDLE;
		if (~FRAMEn) begin
			// For all commands we are latching the operation and the address
			latch_operation       = 1;
			latch_reqAddr         = 1;
			
			case (CBEn)
			
			// On downstream CFG Read Operations
			`PCI_CMD_CFGRD: begin
				// Only proceed if type == 0 with IDSEL, or type == 1 IDSEL don't care
				if (((cfg_type == 2'b00) && (IDSEL)) || (cfg_type == 2'b01)) begin
					next_state = `ST_READ_TURNAROUND;
				end
				if (dac_operation) begin
					next_state = `ST_IDLE; // We only support DAC on mem operations
					clear_dac  = 1;
				end
			end
			
			// On downstream CFG Write Operations
			`PCI_CMD_CFGWR: begin
				// Only proceed if type == 0 with IDSEL, or type == 1 IDSEL don't care
				if (((cfg_type == 2'b00) && (IDSEL)) || (cfg_type == 2'b01)) begin
					latch_operation = 1;
					latch_reqAddr   = 1;
					next_state = `ST_WRITE;
				end
				if (dac_operation) begin
					next_state = `ST_IDLE; // We only support DAC on mem operations
					clear_dac  = 1;
				end
			end
			
			// On downstream MEM Read Operations
			`PCI_CMD_MEMRD: begin
				next_state = `ST_READ_TURNAROUND;
			end
			
			// On downstream MEM Write Operations
			`PCI_CMD_MEMWR: begin
				next_state = `ST_WRITE;
			end
			
			// On downstream IO Read Operations
			`PCI_CMD_IOREAD: begin
				next_state = `ST_READ_TURNAROUND;
				if (dac_operation) begin
					next_state = `ST_IDLE; // We only support DAC on mem operations
					clear_dac  = 1;
				end
			end
			
			// On downstream IO Write Operations
			`PCI_CMD_IOWRITE: begin
				next_state = `ST_WRITE;
				if (dac_operation) begin
					next_state = `ST_IDLE; // We only support DAC on mem operations
					clear_dac  = 1;
				end
			end
			
			// On downstream 64-bit memory operations
			`PCI_CMD_DAC: begin
				latch_dac = 1;
				next_state = `ST_IDLE;
				// We stay in idle but the difference is we are in a DAC operation
			end
			
			endcase
		end
	end
	// --------------------------------------- //
	// --------------------------------------- //
	
	
	// --------------------------------------- //
	// --------------- ST_WRITE --------------- //
	// --------------------------------------- //
	`ST_WRITE: begin
		case (operation)
		`PCI_CMD_CFGWR: begin
			DEVSELn_OE  = 1; DEVSELn_OUT = 0; // assert DEVSELn to indicate we will take the transaction
			TRDYn_OE    = 1; TRDYn_OUT   = 0; // assert Target Ready to indicate we are ready
			down_config_type      = reqAddr[1:0];
			down_config_dwnum     = reqAddr[7:2];
			down_config_func      = reqAddr[10:8];
			down_config_dev       = reqAddr[15:11];
			down_config_bus       = reqAddr[23:16];
			down_config_writedata = AD;
			down_config_CBEn      = CBEn;
			// Write Accepted
			if (~IRDYn && ~TRDYn_OUT) begin
				down_config_write     = 1'b1;
				if (FRAMEn) begin
					// Write has been accepted, no further bursts
					next_state            = `ST_IDLE;
					clear_dac             = 1;
				end else begin
					// If FRAME is still asserted, we are in a burst
					next_state            = `ST_WRITE;
					advance_dwnum         = 1; // Add 4 to the dwnum to advance a word
				end
			end
		end
		`PCI_CMD_MEMWR: begin
			DEVSELn_OE  = 1; DEVSELn_OUT = 0; // assert DEVSELn to indicate we will take the transaction
			TRDYn_OE    = 1; TRDYn_OUT   = 0; // assert Target Ready to indicate we are ready
			if (dac_operation)
				down_mem_addr    = reqAddr;
			else
				down_mem_addr    = {32'h0,reqAddr[31:0]}; // handle wrap around condition on non-DAC
			down_mem_writedata = AD;
			down_mem_CBEn      = CBEn;
			// Write Accepted
			if (~IRDYn && ~TRDYn_OUT) begin
				down_mem_write        = 1'b1;
				if (FRAMEn) begin
					// Write has been accepted, no further bursts
					next_state            = `ST_IDLE;
					clear_dac             = 1;
				end else begin
					// If FRAME is still asserted, we are in a burst
					next_state            = `ST_WRITE;
					advance_addr          = 1; // Add 4 to the addr to advance a word
				end
			end
		end
		`PCI_CMD_IOWRITE: begin
			DEVSELn_OE  = 1; DEVSELn_OUT = 0; // assert DEVSELn to indicate we will take the transaction
			TRDYn_OE    = 1; TRDYn_OUT   = 0; // assert Target Ready to indicate we are ready
			down_io_addr      = reqAddr[31:0];
			down_io_writedata = AD;
			down_io_CBEn      = CBEn;
			// Write Accepted
			if (~IRDYn && ~TRDYn_OUT) begin
				down_io_write        = 1'b1;
				if (FRAMEn) begin
					// Write has been accepted, no further bursts
					next_state            = `ST_IDLE;
					clear_dac             = 1;
				end else begin
					// If FRAME is still asserted, we are in a burst
					next_state            = `ST_WRITE;
					advance_addr          = 1; // Add 4 to the addr to advance a word
				end
			end
		end
		default: begin
			next_state = `ST_IDLE; // All other undefined operations go back to idle
			clear_dac  = 1;
		end
		endcase
	end
	// --------------------------------------- //
	// --------------------------------------- //		
		
	// -------------------------------------------------- //
	// --------------- ST_READ_TURNAROUND --------------- //
	// -------------------------------------------------- //
	`ST_READ_TURNAROUND: begin
		case (operation)
		`PCI_CMD_CFGRD: begin
			DEVSELn_OE  = 1; DEVSELn_OUT = 0; // assert DEVSELn to indicate we will take the transaction
			TRDYn_OE    = 1; TRDYn_OUT   = 1; // assert Target Ready to indicate we are ready
			down_config_type      = reqAddr[1:0];
			down_config_dwnum     = reqAddr[7:2];
			down_config_func      = reqAddr[10:8];
			down_config_dev       = reqAddr[15:11];
			down_config_bus       = reqAddr[23:16];
			down_config_CBEn      = CBEn;
			down_config_read      = 1'b1;
			next_state            = `ST_READ;
			if (~FRAMEn) advance_dwnum = 1; // Add 4 to the dwnum to advance a word
		end
		`PCI_CMD_MEMRD: begin
			DEVSELn_OE  = 1; DEVSELn_OUT = 0; // assert DEVSELn to indicate we will take the transaction
			TRDYn_OE    = 1; TRDYn_OUT   = 1; // assert Target Ready to indicate we are ready
			down_mem_addr         = reqAddr;
			down_mem_CBEn         = CBEn;
			down_mem_read         = 1'b1;
			next_state            = `ST_READ;
			if (~FRAMEn) advance_addr = 1; // Add 4 to the addr to advance a word
		end
		`PCI_CMD_IOREAD: begin
			DEVSELn_OE  = 1; DEVSELn_OUT = 0; // assert DEVSELn to indicate we will take the transaction
			TRDYn_OE    = 1; TRDYn_OUT   = 1; // assert Target Ready to indicate we are ready
			down_io_addr          = reqAddr[31:0];
			down_io_CBEn          = CBEn;
			down_io_read          = 1'b1;
			next_state            = `ST_READ;
			if (~FRAMEn) advance_addr = 1; // Add 4 to the addr to advance a word
		end
		default: begin
			next_state = `ST_IDLE; // All other undefined operations go back to idle
		end
		endcase
	end
	// --------------------------------------- //
	// --------------------------------------- //
	
	// --------------------------------------- //
	// --------------- ST_READ --------------- //
	// --------------------------------------- //
	`ST_READ: begin
		case (operation)
		`PCI_CMD_CFGRD: begin
			DEVSELn_OE  = 1; DEVSELn_OUT = 0; // assert DEVSELn to indicate we will take the transaction
			
			down_config_type      = reqAddr[1:0];
			down_config_dwnum     = reqAddr[7:2];
			down_config_func      = reqAddr[10:8];
			down_config_dev       = reqAddr[15:11];
			down_config_bus       = reqAddr[23:16];
			down_config_CBEn      = CBEn;
			
			if (config_readdatavalid) begin
				AD_OE = 1; AD_OUT = config_readdata;
				TRDYn_OE    = 1; TRDYn_OUT   = 0; // This is the condition where we have config readdata already latched			
			end
			else begin
				AD_OE = 1; AD_OUT = down_config_readdata;
				TRDYn_OE    = 1; TRDYn_OUT   = ~down_config_readdatavalid; // assert Target Ready to indicate we are ready			
			end

			// Read Accepted
			if (~IRDYn && ~TRDYn_OUT) begin
				if (FRAMEn) begin
					// Read has been accepted, no further bursts
					next_state            = `ST_IDLE;
				end else begin
					// If FRAME is still asserted, we are in a burst
					next_state            = `ST_READ;
					down_config_read      = 1;
					advance_dwnum         = 1; // Add 4 to the dwnum to advance a word
					down_config_dwnum     = reqAddr[7:2];
				end
			end
			else // This is the condition where backpressure is applied when data is ready 
			if (down_config_readdatavalid) begin
				latch_config_readdata      = 1; // Save the result from the read
				latch_config_readdatavalid = 1; 
			end
		end
		
		
		`PCI_CMD_MEMRD: begin
			DEVSELn_OE  = 1; DEVSELn_OUT = 0; // assert DEVSELn to indicate we will take the transaction
			
			down_mem_addr      = reqAddr;
			down_mem_CBEn      = CBEn;
			
			if (mem_readdatavalid) begin
				AD_OE = 1; AD_OUT = mem_readdata;
				TRDYn_OE    = 1; TRDYn_OUT   = 0; // This is the condition where we have mem readdata already latched			
			end
			else begin
				AD_OE = 1; AD_OUT = down_mem_readdata;
				TRDYn_OE    = 1; TRDYn_OUT   = ~down_mem_readdatavalid; // assert Target Ready to indicate we are ready			
			end

			// Read Accepted
			if (~IRDYn && ~TRDYn_OUT) begin
				if (FRAMEn) begin
					// Read has been accepted, no further bursts
					next_state            = `ST_IDLE;
				end else begin
					// If FRAME is still asserted, we are in a burst
					next_state       = `ST_READ;
					down_mem_read    = 1;
					advance_addr     = 1; // Add 4 to the addr to advance a word
					if (dac_operation)
						down_mem_addr    = reqAddr;
					else
						down_mem_addr    = {32'h0,reqAddr[31:0]}; // handle wrap around condition on non-DAC
				end
			end
			else // This is the condition where backpressure is applied when data is ready 
			if (down_mem_readdatavalid) begin
				latch_mem_readdata      = 1; // Save the result from the read
				latch_mem_readdatavalid = 1; 
			end
		end
		
		`PCI_CMD_IOREAD: begin
			DEVSELn_OE  = 1; DEVSELn_OUT = 0; // assert DEVSELn to indicate we will take the transaction
			
			down_io_addr      = reqAddr;
			down_io_CBEn      = CBEn;
			
			if (io_readdatavalid) begin
				AD_OE = 1; AD_OUT = io_readdata;
				TRDYn_OE    = 1; TRDYn_OUT   = 0; // This is the condition where we have io readdata already latched			
			end
			else begin
				AD_OE = 1; AD_OUT = down_io_readdata;
				TRDYn_OE    = 1; TRDYn_OUT   = ~down_io_readdatavalid; // assert Target Ready to indicate we are ready			
			end

			// Read Accepted
			if (~IRDYn && ~TRDYn_OUT) begin
				if (FRAMEn) begin
					// Read has been accepted, no further bursts
					next_state            = `ST_IDLE;
				end else begin
					// If FRAME is still asserted, we are in a burst
					next_state       = `ST_READ;
					down_io_read     = 1;
					advance_addr     = 1; // Add 4 to the addr to advance a word
					down_io_addr     = reqAddr[31:0];
				end
			end
			else // This is the condition where backpressure is applied when data is ready 
			if (down_io_readdatavalid) begin
				latch_io_readdata      = 1; // Save the result from the read
				latch_io_readdatavalid = 1; 
			end
		end
		
		
		default: begin
			next_state = `ST_IDLE; // All other undefined operations go back to idle
		end
		endcase
	end
	// --------------------------------------- //
	// --------------------------------------- //	
	
	
	default:
		begin
			next_state = `ST_IDLE;
		end
	endcase
	
end



always @(posedge PCI_CLK or negedge PCI_RSTn) begin
	if (~PCI_RSTn) begin
		state                <= `ST_IDLE;
		operation            <= 4'b0000;
		config_readdata      <= 32'h0;
		config_readdatavalid <= 1'b0;
		mem_readdata         <= 32'h0;
		mem_readdatavalid    <= 1'b0;
		io_readdata          <= 32'h0;
		io_readdatavalid     <= 1'b0;
		latch_dac_lowaddr    <= 32'h0;
		dac_operation        <= 1'b0;
	end
	else begin
		// defaults
		
		// state change
		state <= next_state;
		
		// latch requests
		if (latch_operation) operation <= CBEn;
		
		// non DAC operations the lower 32-bits is AD, upper is zerod out
		if (latch_reqAddr) reqAddr <= {32'h0,AD};
		
		// On a memory DAC we latch the low 32-bit from DAC cycle, and 
		// and the upper 32-bits from AD on the operation cycle (this can only occur on mem operations)
		if (latch_reqAddr && dac_operation) reqAddr <= {AD, latch_dac_lowaddr}; 
		
		if (advance_dwnum) reqAddr[7:2] <= reqAddr[7:2] + 4;
		if (latch_config_readdata) config_readdata <= down_config_readdata;
		if (latch_config_readdatavalid) config_readdatavalid <= 1;
		if (latch_mem_readdata) mem_readdata <= down_mem_readdata;
		if (latch_mem_readdatavalid) mem_readdatavalid <= 1;
		if (latch_io_readdata) io_readdata <= down_io_readdata;
		if (latch_io_readdatavalid) io_readdatavalid <= 1;
		if (~IRDYn && ~TRDYn_OUT) config_readdatavalid <= 0;
		if (~IRDYn && ~TRDYn_OUT) mem_readdatavalid <= 0;
		if (~IRDYn && ~TRDYn_OUT) io_readdatavalid <= 0;
		if (advance_addr) reqAddr <= reqAddr + 4;
		if (latch_dac) begin
			latch_dac_lowaddr <= AD;
			dac_operation     <= 1'b1;
		end
		// Upon the end of any operation clear the DAC bit before going to IDLE
		if (clear_dac) dac_operation <= 1'b0;
	end
end


endmodule