`default_nettype none

`define PDK_DFF 		0
`define PDK_FPGA 		1
`define PDK_SKY130 		2
`define PDK_GF180 		3

module SRAM_Wrapper_RW #(
		parameter SRAM_PDK = `PDK_DFF,
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
		output wire[WORD_SIZE-1:0] primaryDataRead
	);

	localparam WORD_SIZE = 8 * BYTE_COUNT;

generate

	case (SRAM_PDK)
		`PDK_DFF: begin

			SRAM_Wrapper_DFF_RW #(
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
				.primaryDataRead(primaryDataRead));

		end

		`PDK_FPGA: begin

			SRAM_Wrapper_FPGA_RW #(
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
				.primaryDataRead(primaryDataRead));

		end

		`PDK_SKY130: begin

			SRAM_Wrapper_SKY130_RW #(
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
				.primaryDataRead(primaryDataRead));

		end

		`PDK_GF180: begin

			SRAM_Wrapper_GF180_RW #(
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
				.primaryDataRead(primaryDataRead));

		end

		DEFAULT: begin
`ifdef SIM
			$display("Unknown PDK", `PDK);
`endif
		end
	endcase

endgenerate

endmodule
