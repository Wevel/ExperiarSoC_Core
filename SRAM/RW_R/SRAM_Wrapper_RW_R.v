`default_nettype none

`define PDK_DFF 		0
`define PDK_FPGA 		1
`define PDK_SKY130 		2
`define PDK_GF180 		3

module SRAM_Wrapper_RW_R #(
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
		output wire[WORD_SIZE-1:0] primaryDataRead,

		// Secondary R port
		input wire secondarySelect,
		input wire[ADDRESS_SIZE-1:0] secondaryAddress,
		output wire[WORD_SIZE-1:0] secondaryDataRead
	);

	localparam WORD_SIZE = 8 * BYTE_COUNT;

generate

	case (SRAM_PDK)
		`PDK_DFF: begin

			SRAM_Wrapper_DFF_RW_R  #(
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

			SRAM_Wrapper_FPGA_RW_R  #(
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

			SRAM_Wrapper_SKY130_RW_R  #(
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

			// TODO: RW_R for GF180
// 			SRAM_Wrapper_GF180_RW_R  #(
// 				.BYTE_COUNT(BYTE_COUNT),
// 				.ADDRESS_SIZE(ADDRESS_SIZE)
// 			) sramWrapper (
// `ifdef USE_POWER_PINS
// 				.VPWR(VPWR),
// 				.VGND(VGND),
// `endif
// 				.clk(clk),
// 				.rst(rst),
// 				.primarySelect(primarySelect),
// 				.primaryWriteEnable(primaryWriteEnable),
// 				.primaryWriteMask(primaryWriteMask),
// 				.primaryAddress(primaryAddress),
// 				.primaryDataWrite(primaryDataWrite),
// 				.primaryDataRead(primaryDataRead),
// 				.secondarySelect(secondarySelect),
// 				.secondaryAddress(secondaryAddress),
// 				.secondaryDataRead(secondaryDataRead));

		end

		DEFAULT: begin
`ifdef SIM
			$display("Unknown PDK", `PDK);
`endif
		end
	endcase

endgenerate

endmodule
