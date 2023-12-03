`default_nettype none

module SRAM_Wrapper_GF180_RW_R #(
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

genvar index;
generate

	if (BYTE_COUNT == 1) begin
		if (ADDRESS_SIZE == 9) begin

			// TODO: RW_R is not supported for GF180
			// Only one SRAM is needed for this configuration
// 			gf180mcu_fd_ip_sram__sram512x8m8wm1 sram (
// 				.CLK(clk),
// 				.CEN(),
// 				.GWEN,
// 				.WEN,
// 				.A,
// 				.D,
// 				.Q,
// `ifdef USE_POWER_PINS
// 				.VDD(VPWR),
// 				.VSS(VGND)
// `endif
// 			);

		end else if (ADDRESS_SIZE > 9) begin

			// Recursively instantiate SRAMWrappers to create a memory with the desired address size
			wire[(2*WORD_SIZE)-1:0] primaryDataReadFull;
			wire[(2*WORD_SIZE)-1:0] secondaryDataReadFull;

			SRAM_Wrapper_GF180_RW_R #(
				.BYTE_COUNT(BYTE_COUNT),
				.ADDRESS_SIZE(ADDRESS_SIZE-1)
			) sramWrapperHigh (
`ifdef USE_POWER_PINS
				.VPWR(VPWR),
				.VGND(VGND),
`endif
				.clk(clk),
				.rst(rst),
				.primarySelect(primarySelect && primaryAddress[ADDRESS_SIZE-1]), // MSB of primary address
				.primaryWriteEnable(primaryWriteEnable),
				.primaryWriteMask(primaryWriteMask),
				.primaryAddress(primaryAddress[ADDRESS_SIZE-2:0]),
				.primaryDataWrite(primaryDataWrite),
				.primaryDataRead(primaryDataReadFull[(2*WORD_SIZE)-1:WORD_SIZE]),
				.secondarySelect(secondarySelect && secondaryAddress[ADDRESS_SIZE-1]), // MSB of secondary address
				.secondaryAddress(secondaryAddress[ADDRESS_SIZE-2:0]),
				.secondaryDataRead(secondaryDataReadFull[(2*WORD_SIZE)-1:WORD_SIZE]));

			SRAM_Wrapper_GF180_RW_R #(
				.BYTE_COUNT(BYTE_COUNT),
				.ADDRESS_SIZE(ADDRESS_SIZE-1)
			) sramWrapperLow (
`ifdef USE_POWER_PINS
				.VPWR(VPWR),
				.VGND(VGND),
`endif
				.clk(clk),
				.rst(rst),
				.primarySelect(primarySelect && !primaryAddress[ADDRESS_SIZE-1]), // MSB of primary address
				.primaryWriteEnable(primaryWriteEnable),
				.primaryWriteMask(primaryWriteMask),
				.primaryAddress(primaryAddress[ADDRESS_SIZE-2:0]),
				.primaryDataWrite(primaryDataWrite),
				.primaryDataRead(primaryDataReadFull[WORD_SIZE-1:0]),
				.secondarySelect(secondarySelect && !secondaryAddress[ADDRESS_SIZE-1]), // MSB of secondary address
				.secondaryAddress(secondaryAddress[ADDRESS_SIZE-2:0]),
				.secondaryDataRead(secondaryDataReadFull[WORD_SIZE-1:0]));

				assign primaryDataRead = primaryAddress[ADDRESS_SIZE-1] ? primaryDataReadFull[(2*WORD_SIZE)-1:WORD_SIZE] : primaryDataReadFull[WORD_SIZE-1:0];
				assign secondaryDataRead = secondaryAddress[ADDRESS_SIZE-1] ? secondaryDataReadFull[(2*WORD_SIZE)-1:WORD_SIZE] : secondaryDataReadFull[WORD_SIZE-1:0];

		end else begin
`ifdef SIM
			$display("Unsupported ADDRESS_SIZE", ADDRESS_SIZE);
`endif
		end

	end if (BYTE_COUNT == 4) begin

		// Break into single byte SRAMs
		for (index = 0; index < BYTE_COUNT; index = index + 1) begin
			SRAM_Wrapper_GF180_RW_R #(
				.BYTE_COUNT(1),
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
				.primaryWriteMask(primaryWriteMask[index]),
				.primaryAddress(primaryAddress),
				.primaryDataWrite(primaryDataWrite[(index*8)+7:(index*8)]),
				.primaryDataRead(primaryDataRead[(index*8)+7:(index*8)]),
				.secondarySelect(secondarySelect),
				.secondaryAddress(secondaryAddress),
				.secondaryDataRead(secondaryDataRead[(index*8)+7:(index*8)]));
		end

	end else begin
`ifdef SIM
		$display("Unsupported BYTE_COUNT", BYTE_COUNT);
`endif
	end

endgenerate

endmodule
