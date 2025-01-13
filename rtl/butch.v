module butch(
	input clock,
	input reset_n,
	
	input butch_cs,
	
	input [5:0] cpu_addr,
	input [15:0] cpu_din,
	input cpu_as_n,
	input cpu_rw,
	
	output reg [15:0] butch_dout,

	output reg butch_irq		// TODO!
);


reg [15:0] butch_irq_reg;			// 0x00
reg [15:0] butch_dsa_cont;			// 0x04
reg [15:0] butch_cmd_reg;			// 0x08
reg [15:0] butch_reg_0c;			// 0x0c  ??
reg [15:0] butch_i2s_cont;			// 0x10
reg [15:0] butch_sub_cont;			// 0x14
reg [15:0] butch_sub_rega;			// 0x18
reg [15:0] butch_sub_regb;			// 0x1c
reg [15:0] butch_sub_time;			// 0x20
reg [15:0] butch_i2s_fifo;			// 0x24
reg [15:0] butch_i2s_fifo_old;	// 0x28
reg [15:0] butch_reg_2c;			// 0x2c  Unknown? (used at start-up)

always @(posedge clock or negedge reset_n)
if (!reset_n) begin
	butch_irq_reg			<= 16'h0000;	// 0x00
	butch_dsa_cont			<= 16'h0000;	// 0x04
	butch_cmd_reg			<= 16'h0000;	// 0x08
	butch_reg_0c			<= 16'h0000;	// 0x0c  ??
	butch_i2s_cont			<= 16'h0000;	// 0x10
	butch_sub_cont			<= 16'h0000;	// 0x14
	butch_sub_rega			<= 16'h0000;	// 0x18
	butch_sub_regb			<= 16'h0000;	// 0x1c
	butch_sub_time			<= 16'h0000;	// 0x20
	butch_i2s_fifo			<= 16'h0000;	// 0x24
	butch_i2s_fifo_old	<= 16'h0000;	// 0x28
	butch_reg_2c			<= 16'h0000;	// 0x2c  Unknown? (used at start-up)
end
else begin
	// Handle register WRITES.
	//
	// (not checking fx68k_lds_n nor fx68k_uds_n yet.)
	//
	if (butch_cs && !cpu_as_n && !cpu_rw) begin
		case ( {cpu_addr[5:0],2'b00} )
			6'h00: butch_irq_reg			<= cpu_din;	// 0x00  IRQ reg.
			6'h04: butch_dsa_cont		<= cpu_din;	// 0x04  DSA Control reg.
			6'h08: butch_cmd_reg			<= cpu_din;	// 0x08  DSA TX/RX (Command) reg. (marked as reg 0xA in the MAME comments, but 8,9,A,B is the same reg)
			6'h0c: butch_reg_0c			<= cpu_din;	// 0x0c  ??
			6'h10: butch_i2s_cont		<= cpu_din;	// 0x10  I2S bus control.
			6'h14: butch_sub_cont		<= cpu_din;	// 0x14  CD subcode control.
			6'h18: butch_sub_rega		<= cpu_din;	// 0x18  Subcode data Reg A.
			6'h1c: butch_sub_regb		<= cpu_din;	// 0x1c  Subcode data Reg B.
			6'h20: butch_sub_time		<= cpu_din;	// 0x20  Subcode time and compare enable.
			6'h24: butch_i2s_fifo		<= cpu_din;	// 0x24  I2S FIFO data.
			6'h28: butch_i2s_fifo_old	<= cpu_din;	// 0x28  I2S FIFO data (old)
			6'h2c: butch_reg_2c			<= cpu_din;	// 0x2c  Unknown? (used at start-up)
			default: ;
		endcase
	end
end

always @(*) begin
	// READ mux...
	case ( {cpu_addr[5:0],2'b00} )
		//6'h00: butch_dout = butch_irq_reg;		// 0x00  IRQ reg.
		6'h00: butch_dout = 16'h2000;					// 0x00  IRQ reg. TESTING !!
		
		6'h04: butch_dout = butch_dsa_cont;			// 0x04  DSA Control reg.
		
		6'h08: butch_dout = butch_cmd_reg;			// 0x08  DSA TX/RX (Command) reg.
		//6'h08: butch_dout = 16'h7001;				// 0x0a  DSA TX/RX (Command) reg. TESTING !!
		
		6'h0c: butch_dout = butch_reg_0c;			// 0x0c  ??
		6'h10: butch_dout = butch_i2s_cont;			// 0x10  I2S bus control.
		6'h14: butch_dout = butch_sub_cont;			// 0x14  CD subcode control.
		6'h18: butch_dout = butch_sub_rega;			// 0x18  Subcode data Reg A.
		6'h1c: butch_dout = butch_sub_regb;			// 0x1c  Subcode data Reg B.
		6'h20: butch_dout = butch_sub_time;			// 0x20  Subcode time and compare enable.
		6'h24: butch_dout = butch_i2s_fifo;			// 0x24  I2S FIFO data.
		6'h28: butch_dout = butch_i2s_fifo_old;	// 0x28  I2S FIFO data (old)
		6'h2c: butch_dout = butch_reg_2c;			// 0x2c  Unknown? (used at start-up)
		default: ;
	endcase
end


endmodule

/*
CD-Rom emulation, chip codename Butch (the HW engineer was definitely obsessed with T&J somehow ...)
TODO: this needs to be device-ized, of course ...

[0x00]: irq register
(R)
-x-- ---- ---- ---- CD uncorrectable data error pending
--x- ---- ---- ---- Response from CD drive pending
---x ---- ---- ---- Command to CD drive pending
---- x--- ---- ---- Subcode data pending
---- -x-- ---- ---- Frame pending
---- --x- ---- ---- CD data FIFO half-full flag pending
(W)
---- ---- -x-- ---- CIRC failure irq
---- ---- --x- ---- CD module command RX buffer full irq
---- ---- ---x ---- CD module command TX buffer empty irq
---- ---- ---- x--- Enable pre-set subcode time-match found irq
---- ---- ---- -x-- Enable CD subcode frame-time irq
---- ---- ---- --x- Enable CD data FIFO half full irq
---- ---- ---- ---x set to enable irq
[0x04]: DSA control register
[0x0a]: DSA TX/RX data (sends commands with this)
    0x01 Play Title (?)
    0x02 Stop
    0x03 Read TOC
    0x04 Pause
    0x05 Unpause
    0x09 Get Title Len
    0x0a Open Tray
    0x0b Close Tray
    0x0d Get Comp Time
    0x10 Goto ABS Min
    0x11 Goto ABS Sec
    0x12 Goto ABS Frame
    0x14 Read Long TOC
    0x15 Set Mode
    0x16 Get Error
    0x17 Clear Error
    0x18 Spin Up
    0x20 Play AB Min
    0x21 Play AB Sec
    0x22 Play AB Frame
    0x23 Stop AB Min
    0x24 Stop AB Sec
    0x25 Stop AB Frame
    0x26 AB Release
    0x50 Get Disc Status
    0x51 Set Volume
    0x54 Get Maxsession
    0x70 Set DAC mode (?)
    0xa0-0xaf User Define (???)
    0xf0 Service
    0xf1 Sledge
    0xf2 Focus
    0xf3 Turntable
    0xf4 Radial

[0x10]: I2S bus control register
[0x14]: CD subcode control register
[0x18]: Subcode data register A
[0x1C]: Subcode data register B
[0x20]: Subcode time and compare enable
[0x24]: I2S FIFO data
[0x28]: I2S FIFO data (old)
[0x2c]: ? (used at start-up)

*/
