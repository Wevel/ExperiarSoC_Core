`default_nettype none

`define PDK_DFF 		0
`define PDK_FPGA 		1
`define PDK_SKY130 		2
`define PDK_GF180 		3

`ifdef USE_DFF_SRAM
	`define SRAM_PDK `PDK_DFF
	`include "SRAMWrapper_DFF.v"
`elsif USE_FPGA_SRAM
	`define SRAM_PDK `PDK_FPGA
	`include "SRAMWrapper_FPGA.v"
`elsif USE_SKY130_SRAM
	`define SRAM_PDK `PDK_SKY130
	`include "SRAMWrapper_SKY130.v"
`elsif USE_GF180_SRAM
	`define SRAM_PDK `PDK_GF180
	`include "SRAMWrapper_GF180.v"
`else
	`error "Unknown PDK"
`endif


module SRAMWrapper #(
		parameter BYTE_COUNT = 4,
		parameter ADDRESS_SIZE = 9
	)(
`ifdef USE_POWER_PINS
		inout VPWR,
		inout VGND,
`endif

		input wire clk,
		input wire rst,

		// Primary RW port
		input wire primarySelect,
		input wire primaryWriteEnable,
		input wire[BYTE_COUNT-1:0] primaryWriteMask,
		input wire[ADDRESS_SIZE-1:0] primaryAddress,
		input wire[WORD_SIZE-1:0] primaryDataWrite,
		output wire[WORD_SIZE-1:0] primaryDataRead,

		// Secondary R port
		input wire secondarySelect,
		input wire[ADDRESS_SIZE-1:0] secondaryAddress,
		output wire[WORD_SIZE-1:0] secondaryDataRead
	);

	localparam WORD_SIZE = 4 * BYTE_COUNT;

generate

	case (`SRAM_PDK)
		`PDK_DFF: begin
			
			SRAMWrapper_DFF #(
				.BYTE_COUNT(BYTE_COUNT),
				.ADDRESS_SIZE(ADDRESS_SIZE)
			) sramWrapper (
`ifdef USE_POWER_PINS
				.VPWR(VPWR),
				.VGND(VGND),
`endif
				.clk(clk),
				.rst(rst),
				.primarySelect(primarySelect),
				.primaryWriteEnable(primaryWriteEnable),
				.primaryWriteMask(primaryWriteMask),
				.primaryAddress(primaryAddress),
				.primaryDataWrite(primaryDataWrite),
				.primaryDataRead(primaryDataRead),
				.secondarySelect(secondarySelect),
				.secondaryAddress(secondaryAddress),
				.secondaryDataRead(secondaryDataRead));

		end

		`PDK_FPGA: begin
			
			SRAMWrapper_FPGA #(
				.BYTE_COUNT(BYTE_COUNT),
				.ADDRESS_SIZE(ADDRESS_SIZE)
			) sramWrapper (
				.clk(clk),
				.rst(rst),
				.primarySelect(primarySelect),
				.primaryWriteEnable(primaryWriteEnable),
				.primaryWriteMask(primaryWriteMask),
				.primaryAddress(primaryAddress),
				.primaryDataWrite(primaryDataWrite),
				.primaryDataRead(primaryDataRead),
				.secondarySelect(secondarySelect),
				.secondaryAddress(secondaryAddress),
				.secondaryDataRead(secondaryDataRead));

		end

		`PDK_SKY130: begin
					
			SRAMWrapper_SKY130 #(
				.BYTE_COUNT(BYTE_COUNT),
				.ADDRESS_SIZE(ADDRESS_SIZE)
			) sramWrapper (
`ifdef USE_POWER_PINS
				.VPWR(VPWR),
				.VGND(VGND),
`endif
				.clk(clk),
				.rst(rst),
				.primarySelect(primarySelect),
				.primaryWriteEnable(primaryWriteEnable),
				.primaryWriteMask(primaryWriteMask),
				.primaryAddress(primaryAddress),
				.primaryDataWrite(primaryDataWrite),
				.primaryDataRead(primaryDataRead),
				.secondarySelect(secondarySelect),
				.secondaryAddress(secondaryAddress),
				.secondaryDataRead(secondaryDataRead));
				
		end

		`PDK_GF180: begin
						
			SRAMWrapper_GF180 #(
				.BYTE_COUNT(BYTE_COUNT),
				.ADDRESS_SIZE(ADDRESS_SIZE)
			) sramWrapper (
`ifdef USE_POWER_PINS
				.VPWR(VPWR),
				.VGND(VGND),
`endif
				.clk(clk),
				.rst(rst),
				.primarySelect(primarySelect),
				.primaryWriteEnable(primaryWriteEnable),
				.primaryWriteMask(primaryWriteMask),
				.primaryAddress(primaryAddress),
				.primaryDataWrite(primaryDataWrite),
				.primaryDataRead(primaryDataRead),
				.secondarySelect(secondarySelect),
				.secondaryAddress(secondaryAddress),
				.secondaryDataRead(secondaryDataRead));
				
		end

		DEFAULT: begin
			//$display("Unknown PDK", `PDK);
		end
	endcase

endgenerate

endmodule
