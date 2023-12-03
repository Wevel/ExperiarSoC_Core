`default_nettype none

module SRAM_Wrapper_SKY130_RW_R #(
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

	if (BYTE_COUNT == 4) begin
		if (ADDRESS_SIZE == 9) begin

			// Only one SRAM is needed for this configuration
			sky130_sram_2kbyte_1rw1r_32x512_8 sram(
	`ifdef USE_POWER_PINS
				.vccd1(VPWR),	// User area 1 1.8V power
				.vssd1(VGND),	// User area 1 digital ground
	`endif
				.clk0(clk),
				.csb0(~primarySelect),
				.web0(~primaryWriteEnable),
				.wmask0(primaryWriteMask),
				.addr0(primaryAddress),
				.din0(primaryDataWrite),
				.dout0(primaryDataRead),
				.clk1(clk),
				.csb1(~secondarySelect),
				.addr1(secondaryAddress),
				.dout1(secondaryDataRead)
			);

		end else if (ADDRESS_SIZE > 9) begin

			// Recursively instantiate SRAMWrappers to create a memory with the desired address size
			wire[(2*WORD_SIZE)-1:0] primaryDataReadFull;
			wire[(2*WORD_SIZE)-1:0] secondaryDataReadFull;

			SRAM_Wrapper_SKY130_RW_R #(
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

			SRAM_Wrapper_SKY130_RW_R #(
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
	end else begin
`ifdef SIM
		$display("Unsupported BYTE_COUNT", BYTE_COUNT);
`endif
	end

endgenerate

endmodule
