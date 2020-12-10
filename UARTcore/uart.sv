//============================================================================
//  PCI2Nano - 8250-Compatible PCI UART Core
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


module uart
(
    input              PCI_CLK,
    input              PCI_RSTn,
	
	input              down_config_read,           
	input              down_config_write,          
	input      [3:0]   down_config_CBEn,           
	input      [1:0]   down_config_type,           
	input      [5:0]   down_config_dwnum,          
	input      [2:0]   down_config_func,           
	input      [4:0]   down_config_dev,            
	input      [7:0]   down_config_bus,            
	input      [31:0]  down_config_writedata,      
	output reg [31:0]  down_config_readdata,       
	output reg         down_config_readdatavalid,  
	
	input              down_io_read,               
	input              down_io_write,              
	input      [3:0]   down_io_CBEn,               
	input      [31:0]  down_io_addr,               
	input      [31:0]  down_io_writedata,          
	output reg [31:0]  down_io_readdata,           
	output reg         down_io_readdatavalid,
	
	output [7:0]       txfifo_data,
	input              txfifo_rd,
	output             txfifo_empty,
	output             txfifo_full,
	
	input [7:0]        rxfifo_data,
	input              rxfifo_wr,
	output             rxfifo_empty,
	output             rxfifo_full
);


reg [31:0] config_space[0:9];
always @(posedge PCI_CLK or negedge PCI_RSTn) begin
	if (~PCI_RSTn) begin
		config_space[0]   <= 32'h1337_1172; // DeviceID VendorID
		config_space[1]   <= 32'h0020_0001;
		config_space[2]   <= 32'h0700_0101; // Class Code == PCI Serial Port, Revision ID == 1
		config_space[3]   <= 32'h0000_0000; // Header Byte == 0x00 for single dev endpoints
		config_space[4]   <= 32'h0000_0000;
		config_space[5]   <= 32'h0000_0000;
		config_space[6]   <= 32'h0000_0000;
		config_space[7]   <= 32'h0000_0000;
		config_space[8]   <= 32'h0000_0000;
		config_space[9]   <= 32'h0000_0000;
        down_config_readdata      <= 32'h0;
        down_config_readdatavalid <= 1'h0; 
		
		
	end else
	begin
		down_config_readdatavalid <= 1'h0;
		
		 if (down_config_write & (down_config_type == 2'b00)) begin
			case (down_config_dwnum)
			0,5,6,7,8,9:begin end // Prohibit overwriting VID/PID and all the bar registers
			4: begin // Bar 0 is open as an 8 byte IO space
				config_space[down_config_dwnum]   <= {down_config_writedata[31:3] & {28'hFFFFFFF,1'b1},3'b001};
			end
			1,2,3: begin
				config_space[down_config_dwnum]   <= down_config_writedata;
			end
			default: begin end // do nothing
			endcase
		 end
		 
		 if (down_config_read & (down_config_type == 2'b00)) begin
			case (down_config_dwnum)
			0,1,2,3,4,5,6,7,8,9: begin
				down_config_readdata <= config_space[down_config_dwnum];
			end
			default: begin
				down_config_readdata <=  32'h0;
			end
			endcase
			down_config_readdatavalid <= 1'h1; 
		 end
		 
	end
end

reg [7:0] recbyte;
reg [7:0] divlow;
reg [7:0] divhigh;
reg [7:0] scratch;
reg [7:0] IER;
reg [7:0] LCR;
reg [7:0] FCR;
reg [7:0] MCR;
reg [7:0] MSR;
reg [7:0] IIR;
reg data_ready;
wire dlab;
assign dlab = LCR[7];

reg MSR_inten = 0;
reg LSR_inten = 0;
reg TX_inten = 0;
reg RX_inten = 0;
reg TX_int = 0;
reg RX_int = 0;
reg LSR_int = 0;

wire [7:0]  fifo_data;
reg rxfifo_empty_q;
reg txfifo_empty_q;

wire [7:0] LSR;
reg LSR_q;
assign LSR = {1'b0,rxfifo_empty,txfifo_empty,4'b0,~rxfifo_empty};


always @(posedge PCI_CLK or negedge PCI_RSTn) begin
	if (~PCI_RSTn) begin
		recbyte <= 8'b0;
		divlow  <= 8'b0;
		divhigh <= 8'b0;
		IER     <= 8'h0;
		scratch <= 8'h0;
		LCR     <= 8'h0;
		FCR     <= 8'h0;
		MCR     <= 8'h0;
		MSR     <= 8'h0;
		IIR     <= 8'hC1;
        MSR_inten <= 0;
        LSR_inten <= 0;
		LSR_int   <= 0;
        TX_inten  <= 0;
        RX_inten  <= 0;
		
		TX_int  <= 0;
        RX_int  <= 0;
		down_io_readdatavalid <= 1'b0;
		
		rxfifo_empty_q <= 1'b0;
		txfifo_empty_q <= 1'b0;
		LSR_q <= 8'b0;

	end else begin
		down_io_readdatavalid <= 1'b0;
		txfifo_empty_q <= txfifo_empty;
		rxfifo_empty_q <= rxfifo_empty;
		LSR_q <= LSR;
		
		if (down_io_write) begin
			case (down_io_addr[2:0])
			3'd0: begin
				if (dlab) divlow <= down_io_writedata[7:0];
				else begin
					recbyte <= down_io_writedata[7:0];
					TX_int <= 1'b0;
				end
			end
			3'd1: begin
				if (dlab) divhigh <= down_io_writedata[15:8];
				else begin
					IER <= down_io_writedata[15:8];
					MSR_inten <= down_io_writedata[11];
					LSR_inten <= down_io_writedata[10];
					TX_inten  <= down_io_writedata[9];
					TX_int <= down_io_writedata[9];
					RX_inten  <= down_io_writedata[8];
				end
			end
			3'd2: begin
				// FCR
				FCR <= down_io_writedata[23:16]; 
			end
			3'd3: begin
				// LCR
				LCR <= down_io_writedata[31:24]; 
			end
			3'd4: begin
				// MCR
				MCR <= down_io_writedata[7:0];
			end
			3'd7: begin
				scratch <= down_io_writedata[31:24];
			end
			endcase
		end
		
		if (down_io_read) begin
			down_io_readdatavalid <= 1'b1;
			case (down_io_addr[2:0])
			3'd0: begin
				if (dlab) down_io_readdata <= {8'h0,8'h0,8'h0,divlow};
				else begin
					down_io_readdata <= {8'h0,8'h0,8'h0,fifo_data};
					RX_int <= 1'b0;
				end
			end
			3'd1: begin
				if (dlab) down_io_readdata <= {8'h0,8'h0,divhigh,8'h0};
				else down_io_readdata <= {8'h0,8'h0,IER,8'h0};
			end
			3'd2: begin
				down_io_readdata <= {8'h0,IIR,8'h0,8'h0};
				TX_int <= 1'b0;
			end
			3'd3: begin
				down_io_readdata <= {LCR,8'h0,8'h0,8'h0};
			end
			3'd4: begin
				down_io_readdata <= {8'h0,8'h0,8'h0,MCR};
			end
			3'd5: begin
				down_io_readdata <= {8'h0,8'h0,LSR,8'h0};
				LSR_int <= 1'b0;
			end
			3'd6: begin
				down_io_readdata <= {8'h0,8'hF0,8'h0,8'h0};
			end			
			3'd7: begin
				down_io_readdata <= {scratch,8'h0,8'h0,8'h0};
			end
			endcase
		end

		if (0 & MSR_inten) IIR <= 8'hC0;
		else if (TX_int & TX_inten) IIR <= 8'hC2;
		else if (RX_int & RX_inten) IIR <= 8'hC4;
		else if (LSR_int & LSR_inten) IIR <= 8'hC6;
		else IIR <= 8'hC1;
		
		
		if (~txfifo_empty_q & txfifo_empty) TX_int <= 1'b1;
		if (rxfifo_empty_q & ~rxfifo_empty) RX_int <= 1'b1;
		if (LSR != LSR_q) LSR_int <= 1'b1;

	end
end



	scfifo	txfifo_component (
				.clock (PCI_CLK),          //input	  clock;
				.wrreq (down_io_write & (down_io_addr[2:0] == 3'b0)),          //input	  wrreq;
				.aclr  (~FCR[0]),           //input	  aclr;
				.data  (down_io_writedata[7:0]),           //input	[7:0]  data;
				.rdreq (txfifo_rd),          //input	  rdreq;
				.usedw (),      //output	[2:0]  usedw;
				.empty (txfifo_empty),      //output	  empty;
				.full  (txfifo_full),      //output	  full;
				.q     (txfifo_data),      //output	[7:0]  q;
				.almost_empty (),
				.almost_full (),
				.sclr (FCR[2]));
	defparam
		txfifo_component.add_ram_output_register = "OFF",
		txfifo_component.intended_device_family = "Cyclone IV E",
		txfifo_component.lpm_numwords = 8,
		txfifo_component.lpm_showahead = "ON",
		txfifo_component.lpm_type = "scfifo",
		txfifo_component.lpm_width = 8,
		txfifo_component.lpm_widthu = 3,
		txfifo_component.overflow_checking = "ON",
		txfifo_component.underflow_checking = "ON",
		txfifo_component.use_eab = "ON";
		
	scfifo	rxfifo_component (
				.clock (PCI_CLK),          //input	  clock;
				.wrreq (rxfifo_wr),          //input	  wrreq;
				.aclr  (~FCR[0]),           //input	  aclr;
				.data  (rxfifo_data),           //input	[7:0]  data;
				.rdreq (down_io_read & (down_io_addr[2:0] == 3'b0)),          //input	  rdreq;
				.usedw (),      //output	[2:0]  usedw;
				.empty (rxfifo_empty),      //output	  empty;
				.full  (rxfifo_full),      //output	  full;
				.q     (fifo_data),      //output	[7:0]  q;
				.almost_empty (),
				.almost_full (),
				.sclr (FCR[1]));
	defparam
		rxfifo_component.add_ram_output_register = "OFF",
		rxfifo_component.intended_device_family = "Cyclone IV E",
		rxfifo_component.lpm_numwords = 8,
		rxfifo_component.lpm_showahead = "ON",
		rxfifo_component.lpm_type = "scfifo",
		rxfifo_component.lpm_width = 8,
		rxfifo_component.lpm_widthu = 3,
		rxfifo_component.overflow_checking = "ON",
		rxfifo_component.underflow_checking = "ON",
		rxfifo_component.use_eab = "ON";


endmodule

